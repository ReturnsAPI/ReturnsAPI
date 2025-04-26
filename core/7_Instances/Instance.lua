-- Instance

--[[
This class provides get/set functionality for GameMaker instances,
as well as allowing GM function calls with the
instance passed in as `self`/`other` using `:` syntax.
]]

Instance = new_class()

run_once(function()
    __instance_data = {}
    __object_index_cache = {}   -- Cache for inst:get_object_index; indexed by ID
end)

local wrapper_cache = setmetatable({}, {__mode = "v"})      -- Cache for Instance.wrap
local cinstance_cache = setmetatable({}, {__mode = "k"})    -- Cache for inst.CInstance

-- `__invalid_instance` created at the bottom


-- Internal lookup table for Instance.is
instance_wrappers = {
    Instance    = true,
    Actor       = true,
    Player      = true
}



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       Instance
--@param        object      | Object    | The object to spawn.
--@param        x           | number    | The x spawn coordinate. <br>`0` by default.
--@param        y           | number    | The y spawn coordinate. <br>`0` by default.
--[[
Creates and returns an instance of the specified object.

Also exists as a @link {method of Object | Object#create}.
]]
Instance.create = function(x, y, object)
    local holder = RValue.new_holder_scr(3)
    holder[0] = RValue.new(x or 0)
    holder[1] = RValue.new(y or 0)
    holder[2] = RValue.from_wrapper(object)
    local out = RValue.new(0)
    gmf.instance_create(nil, nil, out, 3, holder)
    return RValue.to_wrapper(out)
end


--@static
--@return       bool
--@param        inst        | Instance  | The instance to check.
--[[
Returns `true` if the instance exists, and `false` otherwise.
]]
Instance.exists = function(inst)
    local holder = RValue.new_holder(1)
    holder[0] = RValue.new(Wrap.unwrap(inst), RValue.Type.REF)
    local out = RValue.new(0)
    gmf.instance_exists(out, nil, nil, 1, holder)
    return out.value == 1
end


--@static
--@href         destroy-static
--@param        inst        | Instance  | The instance to destroy.
--[[
Destroys the instance.

Also exists as an @link {instance method | Instance#destroy-instance}.
]]
Instance.destroy = function(inst)
    inst = Wrap.unwrap(inst)

    local holder = RValue.new_holder(1)
    holder[0] = RValue.new(inst, RValue.Type.REF)
    gmf.instance_destroy(RValue.new(0), nil, nil, 1, holder)

    -- Clear instance data
    __instance_data[inst] = nil
end


--@static
--@return       Instance
--@param        object      | Object    | The object to check.
--@param        n           | number    | The *n*-th instance, indexed from 1. <br>`1` by default.
--[[
Returns the first (or *n*-th) instance of the specified object,
or an invalid instance (value of `-4`).
]]
Instance.find = function(object, n)
    local object = Wrap.unwrap(object)
    local n = n or 1

    -- GML `instance_find` is faster than `_mod_instance_find`,
    -- so use that for vanilla objects

    -- Vanilla object
    if object < Object.CUSTOM_START then
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(object)
        holder[1] = RValue.new(n - 1)
        local out = RValue.new(0)
        gmf.instance_find(out, nil, nil, 2, holder)
        local inst = RValue.to_wrapper(out)
        if inst ~= -4 then return inst end
    
    -- Custom object
    else
        local holder = RValue.new_holder_scr(2)
        holder[0] = RValue.new(object)
        holder[1] = RValue.new(n)   -- _mod_instance_find is indexed from 1
        local out = RValue.new(0)
        gmf._mod_instance_find(nil, nil, out, 2, holder)
        local inst = RValue.to_wrapper(out)
        if inst ~= -4 then return inst end

    end

    -- No instance found
    return __invalid_instance
end


--@static
--@return       table
--@param        object      | Object    | The object to check.
--[[
Returns a table of all instances of the specified object.

**NOTE:** The execution time scales with the number of
instances of the object, and can be *very* expensive at high numbers.
Try not to call this too much.
]]
Instance.find_all = function(object)
    local object = Wrap.unwrap(object)
    local insts = {}

    local count = Instance.count(object)
    for n = 1, count do
        table.insert(insts, Instance.find(object, n))
    end

    return insts
end


--@static
--@return       number
--@param        object      | Object    | The object to check.
--[[
Returns the instance count of the specified object.
]]
Instance.count = function(object)
    local holder = RValue.new_holder_scr(1)
    holder[0] = RValue.new(Wrap.unwrap(object))
    local out = RValue.new(0)
    gmf._mod_instance_number(nil, nil, out, 1, holder)
    return out.value
end


--@static
--@return       table
--@param        instance    | Instance  | The instance to get the table from.
--@optional     subtable    | string    | If specified, returns a different table under the ID `subtable`. <br>Useful for organization and preventing variable name conflicts within a mod itself. <br>This string can be whatever you want.
--@optional     namespace   | string    | If specified, returns another mod's table for the instance.
--[[
Returns a table unique to each instance (will be initially empty) and unique to each mod calling this.
(e.g., Given the same instance and two mods A and B, A calling `get_data` will return a different table to B calling `get_data`).

This table is useful for storing Lua data (such as tables) in instances, which cannot be done with normal instance variables.
It is automatically deleted upon the instance's destruction.
]]
Instance.get_data = function(instance, subtable, namespace, default_namespace)
    local id = Wrap.unwrap(instance)
    if (type(id) ~= "number") or (id < 100000) then log.error("Instance does not exist", 2) end
    local namespace, is_specified = parse_optional_namespace(namespace, default_namespace)
    subtable = subtable or "__main"
    namespace = namespace or _ENV["!guid"]  -- Internal RAPI calling of this is not namespace-bound
    if not __instance_data[id] then __instance_data[id] = {} end
    if not __instance_data[id][namespace] then __instance_data[id][namespace] = {} end
    if not __instance_data[id][namespace][subtable] then __instance_data[id][namespace][subtable] = {} end
    return __instance_data[id][namespace][subtable]
end


--@static
--@return       Instance
--@param        id          | number    | The instance ID to wrap.
--[[
Returns an Instance wrapper containing the provided instance.
]]
Instance.wrap = function(id)
    id = Wrap.unwrap(id)
    if (type(id) ~= "number") or (id < 100000) then
        return __invalid_instance
    end

    -- Check cache
    if wrapper_cache[id] then return wrapper_cache[id] end

    -- Wrap as Instance
    -- and get object_index
    local inst = Proxy.new(id, metatable_instance)
    local obj_index = inst.object_index

    -- Check object_index to determine if
    -- "child" metatables should be used instead
    if obj_index then
        
        -- Player
        if obj_index == gm.constants.oP then
            inst = Proxy.new(id, metatable_player)
            wrapper_cache[id] = inst
            return inst
        end

        -- Actor
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(obj_index)
        holder[1] = RValue.new(gm.constants.pActor)
        local out = RValue.new(0)
        gmf.object_is_ancestor(out, nil, nil, 2, holder)
        if out.value == 1 then
            inst = Proxy.new(id, metatable_actor)
            wrapper_cache[id] = inst
            return inst
        end

        -- Instance
        wrapper_cache[id] = inst
        return inst

    -- Debug
    -- Just leave this here; it should never run
    else
        print("Instance.wrap error:", inst, inst.value, inst.RAPI)

        local holder = RValue.new_holder(1)
        holder[0] = RValue.from_wrapper(inst)
        local out = RValue.new(0)
        gmf.instance_exists(out, nil, nil, 1, holder)
        RValue.peek(out)

        local holder = RValue.new_holder(2)
        holder[0] = RValue.from_wrapper(inst)
        holder[1] = RValue.new("object_index")
        local out = RValue.new(0)
        gmf.variable_instance_get(out, nil, nil, 2, holder)
        RValue.peek(out)

    end
end


--@static
--@return       bool
--@param        value       | RValue or Instance wrapper    | The value to check.
--[[
Returns `true` if `value` is an instance, and `false` otherwise.
]]
Instance.is = function(value)
    -- `value` is either a `ref RValue` or an Instance wrapper
    local _type = Util.type(value)
    if (_type == "cdata" and value.type == RValue.Type.REF)
    or inst_wrappers[_type] then return true end
    return false
end



-- ========== Instance Methods ==========

--@section Instance Methods

methods_instance = {}

-- Add GM scripts
for scr, _ in pairs(GM.internal.builtin) do
    methods_instance[scr] = function(self, ...)
        if self.value == -4 then log.error("Instance does not exist", 2) end
        return GM.SO[scr](self, self, ...)
    end
end
for scr, _ in pairs(GM.internal.script) do
    methods_instance[scr] = function(self, ...)
        if self.value == -4 then log.error("Instance does not exist", 2) end
        return GM.SO[scr](self, self, ...)
    end
end

Util.table_append(methods_instance, {

    -- exists = function(self)
    --     -- Return `false` if wrapper is invalid
    --     if self.value == -4 then return false end

    --     local holder = RValue.new_holder(1)
    --     holder[0] = RValue.new(self.value, RValue.Type.REF)
    --     local out = RValue.new(0)
    --     gmf.instance_exists(out, nil, nil, 1, holder)
    --     local ret = (RValue.to_wrapper(out) == 1)

    --     -- Make this wrapper invalid if the instance actually existn't
    --     if not ret then Proxy.set(self, -4) end

    --     return ret
    -- end,


    --@instance
    --@href         destroy-instance
    --[[
    Destroys the instance.

    Also exists as a @link {static method | Instance#destroy-static}.
    ]]
    destroy = function(self)
        -- Return if wrapper is invalid
        if self.value == -4 then return end

        local holder = RValue.new_holder(1)
        holder[0] = RValue.new(self.value, RValue.Type.REF)
        gmf.instance_destroy(RValue.new(0), nil, nil, 1, holder)

        -- Clear instance data and
        -- make this wrapper invalid
        __instance_data[self.value] = nil
        Proxy.set(self, -4)
    end,


    --@instance
    --@return       Object
    --[[
    Returns the object that the instance is a type of.
    ]]
    get_object = function(self)
        return Object.wrap(self:get_object_index())
    end,


    --@instance
    --@return       number
    --[[
    Returns the instance's correct object index, accounting for custom objects.
    ]]
    get_object_index = function(self)
        -- Check cache
        local object_index = __object_index_cache[self.value]
        if not object_index then
            object_index = self:get_object_index_self()
            __object_index_cache[self.value] = object_index
        end
        
        return object_index
    end,


    --@instance
    --@return       bool
    --@param        object      | Object    | The object to check.
    --@optional     x           | number    | The x position to check at. <br>Uses this instance's current position by default.
    --@optional     y           | number    | The y position to check at. <br>Uses this instance's current position by default.
    --[[
    Returns `true` if this instance is colliding with *any* instance of the specified object.

    **NOTE:** Checking for custom object collision
    is *much* slower than a vanilla object.
    Be mindful of this.
    ]]
    is_colliding = function(self, object, x, y)
        -- Return `false` if wrapper is invalid
        if self.value == -4 then return false end

        local object = Wrap.unwrap(object)

        -- Vanilla object
        if object < Object.CUSTOM_START then
            local holder = RValue.new_holder(3)
            holder[0] = RValue.new(x or self.x)
            holder[1] = RValue.new(y or self.y)
            holder[2] = RValue.new(object)
            local out = RValue.new(0)
            gmf.place_meeting(out, self.CInstance, self.CInstance, 3, holder)
            return (out.value == 1)

        -- Custom object
        else
            -- Figure out correct object to check
            local obj_array = Object.wrap(object).array
            local object_to_check = obj_array:get(Object.Property.BASE)
            
            local list = List.new()

            local holder = RValue.new_holder(5)
            holder[0] = RValue.new(x or self.x)
            holder[1] = RValue.new(y or self.y)
            holder[2] = RValue.new(object_to_check)
            holder[3] = RValue.new(list.value)
            holder[4] = RValue.new(false)
            local out = RValue.new(0)
            gmf.instance_place_list(out, self.CInstance, self.CInstance, 5, holder)
            local count = out.value

            if count > 0 then
                for _, inst in ipairs(list) do
                    -- Check if `__object_index` matches
                    if inst:get_object_index() == object then
                        list:destroy()
                        return true
                    end
                end
            end
            
            list:destroy()
            return false
        end
    end,


    --@instance
    --@return       table
    --@param        object      | Object    | The object to check.
    --@optional     x           | number    | The x position to check at. <br>Uses this instance's current position by default.
    --@optional     y           | number    | The y position to check at. <br>Uses this instance's current position by default.
    --[[
    Returns a table of all instances of the specified object that this instance is colliding with.

    **NOTE:** The execution time scales with the number of
    instances found, and can be somewhat expensive at high numbers.
    Be mindful of this.
    ]]
    get_collisions = function(self, object, x, y)
        -- Return `{}, 0` if wrapper is invalid
        if self.value == -4 then return {}, 0 end
        
        local object = Wrap.unwrap(object)

        -- Figure out correct object to check
        local object_to_check = object
        if object >= Object.CUSTOM_START then
            local obj_array = Object.wrap(object).array
            object_to_check = obj_array:get(Object.Property.BASE)
        end

        local insts = {}
        local list = List.new()

        local holder = RValue.new_holder(5)
        holder[0] = RValue.new(x or self.x)
        holder[1] = RValue.new(y or self.y)
        holder[2] = RValue.new(object_to_check)
        holder[3] = RValue.new(list.value)
        holder[4] = RValue.new(false)
        local out = RValue.new(0)
        gmf.instance_place_list(out, self.CInstance, self.CInstance, 5, holder)
        local count = out.value

        -- Convert output list to table
        if count > 0 then

            -- Vanilla object
            if object < Object.CUSTOM_START then
                for _, inst in ipairs(list) do
                    table.insert(insts, inst)
                end

            -- Custom object
            else
                for _, inst in ipairs(list) do
                    -- Check if `__object_index` matches
                    if inst:get_object_index() == object then
                        table.insert(insts, inst)
                    end
                end

            end
        end
        
        list:destroy()

        return insts
    end,


    --@instance
    --@return       number or nil
    --@param        x           | number    | The target x position.
    --@param        y           | number    | The target y position.
    --[[
    Returns the distance between this instance's position and a point.
    Returns `nil` if this instance does not exist.
    ]]
    distance_to = function(self, x, y)
        -- Return `nil` if wrapper is invalid
        if self.value == -4 then return nil end

        local holder = RValue.new_holder(4)
        holder[0] = RValue.new(self.x)
        holder[1] = RValue.new(self.y)
        holder[2] = RValue.new(x)
        holder[3] = RValue.new(y)
        local out = RValue.new(0)
        gmf.point_distance(out, nil, nil, 4, holder)
        return out.value
    end,


    --@instance
    --@return       number or nil
    --@param        x           | number    | The target x position.
    --@param        y           | number    | The target y position.
    --[[
    Returns the angle to face a point from this instance's position.
    Returns `nil` if this instance does not exist.
    ]]
    direction_to = function(self, x, y)
        -- Return `nil` if wrapper is invalid
        if self.value == -4 then return nil end

        local holder = RValue.new_holder(4)
        holder[0] = RValue.new(self.x)
        holder[1] = RValue.new(self.y)
        holder[2] = RValue.new(x)
        holder[3] = RValue.new(y)
        local out = RValue.new(0)
        gmf.point_direction(out, nil, nil, 4, holder)
        return out.value
    end,


    --@instance
    --@return       bool
    --@param        tag         | string    | The tag to check.
    --[[
    Returns `true` if this instance is of an object with the specified tag.
    ]]
    has_tag = function(self, tag)
        if type(tag) ~= "string" then log.error("has_tag: tag must be a string", 2) end

        if not __object_tags[tag] then return false end
        if __object_tags[tag][self:get_object_index()] then return true end
        return false
    end,


    --@instance
    --[[
    Prints the instances's variables.
    ]]
    print_variables = function(self)
        local holder = RValue.new_holder(1)
        holder[0] = RValue.new(self.value, RValue.Type.REF)
        local out = RValue.new(0)
        gmf.variable_instance_get_names(out, nil, nil, 1, holder)
        local names = RValue.to_wrapper(out)

        local str = ""
        for _, name in ipairs(names) do
            str = str.."\n"..Util.pad_string_right(name, 32).." = "..Util.tostring(self[name])
        end
        print(str)
    end

})



-- ========== Metatables ==========

make_table_once("metatable_instance", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" or k == "id" then return Proxy.get(proxy) end
        if k == "RAPI" then return getmetatable(proxy):sub(14, -1) end
        if k == "CInstance" then
            -- Check cache
            local cinstance = cinstance_cache[proxy]
            if not cinstance then
                cinstance = ffi.cast("struct CInstance*", gm.CInstance.instance_id_to_CInstance_ffi[Proxy.get(proxy)])
                cinstance_cache[proxy] = cinstance
            end
            
            return cinstance
        end

        -- Methods
        if methods_instance[k] then
            return methods_instance[k]
        end

        -- Getter
        local id = Proxy.get(proxy)
        if id == -4 then log.error("Instance does not exist", 2) end
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(id, RValue.Type.REF)
        holder[1] = RValue.new(k)
        local out = RValue.new(0)
        gmf.variable_instance_get(out, nil, nil, 2, holder)
        local ret = RValue.to_wrapper(out)

        -- For attack instances from `actor:fire_` methods, wrap `attack_info`
        if k == "attack_info" then return AttackInfo.wrap(ret) end

        -- If Script, automatically "bind"
        -- script as self/other
        if type(ret) == "table"
        and ret.RAPI == "Script" then
            local cinst = self.CInstance
            ret.self = cinst
            ret.other = cinst
        end

        -- Standard return
        return ret
    end,


    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "id"
        or k == "RAPI"
        or k == "CInstance" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        local id = Proxy.get(proxy)
        if id == -4 then log.error("Instance does not exist", 2) end
        local holder = RValue.new_holder(3)
        holder[0] = RValue.new(id, RValue.Type.REF)
        holder[1] = RValue.new(k)
        holder[2] = RValue.from_wrapper(v)
        gmf.variable_instance_set(RValue.new(0), nil, nil, 3, holder)
    end,


    __eq = function(proxy, other)
        return proxy.value == other.value
    end,

    
    __metatable = "RAPI.Wrapper.Instance"
})



-- ========== __instance_data GC ==========

-- On room change, remove non-existent instances from `__instance_data`

memory.dynamic_hook("RAPI.Instance.room_goto", "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.room_goto),
    -- Pre-hook
    {nil,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
        for id, _ in pairs(__instance_data) do
            if not Instance.exists(id) then
                __instance_data[id] = nil
            end
        end
    end}
)


-- Remove `__instance_data` on non-player kill

memory.dynamic_hook("RAPI.Instance.actor_set_dead", "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.actor_set_dead),
    -- Pre-hook
    {nil,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
        local args_typed = ffi.cast("struct RValue**", args:get_address())
    
        local actor_id = args_typed[0].i32
    
        -- Get object_index
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(actor_id, RValue.Type.REF)
        holder[1] = RValue.new("object_index")
        local out = RValue.new(0)
        gmf.variable_instance_get(out, nil, nil, 2, holder)
    
        -- Do not clear for player deaths
        if out.value ~= gm.constants.oP then
            __instance_data[actor_id] = nil
        end
    end}
)


-- Move `__instance_data` to new instance

memory.dynamic_hook("RAPI.Instance.actor_transform", "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.actor_transform),
    -- Pre-hook
    {nil,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
        local args_typed = ffi.cast("struct RValue**", args:get_address())
    
        local actor_id = args_typed[0].i32
        local new_id = args_typed[1].i32
    
        -- Move data
        if __instance_data[actor_id] then
            __instance_data[new_id] = __instance_data[actor_id]
            __instance_data[actor_id] = nil
        end
    end}
)



-- Create invalid_instance
run_once(function() __invalid_instance = Proxy.new(-4, metatable_instance) end)

-- Public export
__class.Instance = Instance