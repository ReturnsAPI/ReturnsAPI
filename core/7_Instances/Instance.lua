-- Instance

--[[
This class provides get/set functionality for GameMaker instances,
as well as allowing GM function calls with the
instance passed in as `self`/`other` using `:` syntax.
]]

Instance = new_class()

run_once(function()
    __instance_data = {}
end)

local wrapper_cache = setmetatable({}, {__mode = "v"})      -- Cache for Instance.wrap
local cinstance_cache = setmetatable({}, {__mode = "k"})    -- Cache for inst.CInstance
local object_index_cache = {}                               -- Cache for inst:get_object_index; indexed by ID

-- `__invalid_instance` created at the bottom


-- Wrapper types that are Instances
instance_wrappers = {
    Instance    = true,
    Actor       = true,
    Player      = true
}



-- ========== Properties ==========

--@section Properties

--[[
Instances possess all the builtin [GameMaker instance variables](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Asset_Management/Instances/Instance_Variables/Instance_Variables.htm).
]]



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
    return Instance.wrap(gm.instance_create(
        Wrap.unwrap(x) or 0, 
        Wrap.unwrap(y) or 0, 
        Wrap.unwrap(object)
    ))
end


--@static
--@return       bool
--@param        inst        | Instance  | The instance to check.
--[[
Returns `true` if the instance exists, and `false` otherwise.
]]
Instance.exists = function(inst)
    return (gm.instance_exists(Wrap.unwrap(inst)) == 1)
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
    gm.instance_destroy(inst)

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
        local inst = gm.instance_find(object, n - 1)
        if inst ~= -4 then return Instance.wrap(inst.id) end
    
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
    local ns = __instance_data[id][namespace]
    if not ns[subtable] then ns[subtable] = {} end
    return ns[subtable]
end


--@static
--@return       Instance
--@param        id          | number    | The instance ID to wrap.
--[[
Returns an Instance wrapper containing the provided instance.
]]
Instance.wrap = function(id)
    local _type = type(id)
    if _type == "table" then return id end
    if (_type ~= "number") or (id < 100000) then
        return __invalid_instance
    end

    -- Check cache
    if wrapper_cache[id] then return wrapper_cache[id] end

    -- Wrap as Instance
    -- and get object_index
    local inst = make_proxy(id, metatable_instance)
    local obj_index = inst.object_index

    -- Check object_index to determine if
    -- "child" metatables should be used instead
    if obj_index then
        
        -- Player
        -- if obj_index == gm.constants.oP then
        --     inst = make_proxy(id, metatable_player)
        --     wrapper_cache[id] = inst
        --     return inst
        -- end

        -- Actor
        if gm.object_is_ancestor(obj_index, gm.constants.pActor) == 1 then
            inst = make_proxy(id, metatable_actor)
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

    --@instance
    --@href         destroy-instance
    --[[
    Destroys the instance.

    Also exists as a @link {static method | Instance#destroy-static}.
    ]]
    destroy = function(self)
        gm.instance_destroy(id)

        -- Clear instance data and
        -- make this wrapper invalid
        __instance_data[id] = nil
        __proxy[self] = -4
    end,


    --@instance
    --@return       Object
    --[[
    Returns the object that the instance is a type of, accounting for custom objects.
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
        local value = self.value
        local object_index = __object_index_cache[value]
        if not object_index then
            object_index = self:get_object_index_self()
            __object_index_cache[value] = object_index
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
        local object = Wrap.unwrap(object)

        -- Vanilla object
        if object < Object.CUSTOM_START then
            return (gm.call(
                "place_meeting",
                self.CInstance,
                self.CInstance,
                x or self.x,
                y or self.y,
                object
            ) == 1)

        -- Custom object
        else
            -- Figure out correct object to check
            local obj_array = Object.wrap(object).array
            local object_to_check = obj_array:get(Object.Property.BASE)
            
            local list = List.new()

            local count = gm.call(
                "instance_place_list",
                self.CInstance,
                self.CInstance,
                x or self.x,
                y or self.y,
                object_to_check,
                list.value,
                false
            )

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
        local object = Wrap.unwrap(object)

        -- Figure out correct object to check
        local object_to_check = object
        if object >= Object.CUSTOM_START then
            local obj_array = Object.wrap(object).array
            object_to_check = obj_array:get(Object.Property.BASE)
        end

        local insts = {}
        local list = List.new()

        local count = gm.call(
            "instance_place_list",
            self.CInstance,
            self.CInstance,
            x or self.x,
            y or self.y,
            object_to_check,
            list.value,
            false
        )

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
        local names = Array.wrap(gm.variable_instance_get_names(self.value))

        local str = ""
        for _, name in ipairs(names) do
            str = str.."\n"..Util.pad_string_right(name, 32).." = "..Util.tostring(self[name])
        end
        print(str)
    end

})



-- ========== Metatables ==========

local wrapper_name = "Instance"

make_table_once("metatable_instance", {
    __index = function(proxy, k, id)
        -- Get wrapped value
        if k == "value" or k == "id" then return __proxy[proxy] end
        if k == "RAPI" then return wrapper_name end
        if k == "CInstance" then
            -- Check cache
            local cinstance = cinstance_cache[proxy]
            if not cinstance then
                cinstance = gm.CInstance.instance_id_to_CInstance[__proxy[proxy]] 
                cinstance_cache[proxy] = cinstance
            end
            
            return cinstance
        end

        -- Check if this instance is valid
        if not id then
            id = __proxy[proxy]
            if id == -4 then log.error("Instance does not exist", 2) end
        end

        -- Methods
        if methods_instance[k] then
            return methods_instance[k]
        end

        -- Getter
        local ret = gm.variable_instance_get(id, k)

        -- For attack instances from `actor:fire_` methods, wrap `attack_info`
        if k == "attack_info" then return AttackInfo.wrap(ret) end

        ret = Wrap.wrap(ret)

        -- If Script, automatically "bind"
        -- script as self/other
        if type(ret) == "table"
        and ret.RAPI == "Script" then
            ret.self = proxy
            ret.other = proxy
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
        local id = __proxy[proxy]
        if id == -4 then log.error("Instance does not exist", 2) end
        gm.variable_instance_set(id, k, Wrap.unwrap(v, true))
    end,


    __eq = function(proxy, other)
        return proxy.value == other.value
    end,

    
    __metatable = "RAPI.Wrapper."..wrapper_name
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
    
        -- Do not clear for player deaths
        local obj_ind = gm.variable_instance_get(actor_id, "object_index")
        if obj_ind ~= gm.constants.oP then
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
run_once(function() __invalid_instance = make_proxy(-4, metatable_instance) end)

-- Public export
__class.Instance = Instance