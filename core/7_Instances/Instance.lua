-- Instance

Instance = new_class()

if not __instance_data then __instance_data = {} end        -- Preserve on hotload
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

--$static
--$return       Instance
--$param        object      | Object    | The object to spawn.
--$param        x           | number    | The x spawn coordinate. <br>`0` by default.
--$param        y           | number    | The y spawn coordinate. <br>`0` by default.
--[[
Creates and returns an instance of the specified object.

Also exists as a $method of Object, Object#create$.
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


--$static
--$aref         exists-static
--$return       bool
--$param        inst        | Instance  | The instance to check.
--[[
Returns `true` if the instance exists, and `false` otherwise.

Also exists as an $instance method, Instance#exists-instance$.
]]
Instance.exists = function(inst)
    local holder = RValue.new_holder(1)
    holder[0] = RValue.new(Wrap.unwrap(inst))
    local out = RValue.new(0)
    gmf.instance_exists(out, nil, nil, 1, holder)
    return out.value == 1
end


--$static
--$return       Instance
--$param        object      | Object    | The object to check.
--[[
Returns the first instance of the specified object,
or an invalid instance (value of `-4`).
]]
Instance.find = function(object)
    local holder = RValue.new_holder(2)
    holder[0] = RValue.new(Wrap.unwrap(object))
    holder[1] = RValue.new(0)
    local out = RValue.new(0)
    gmf.instance_find(out, nil, nil, 2, holder)
    local inst = RValue.to_wrapper(out)

    -- <Insert custom object finding here>

    if inst ~= -4 then return inst end

    -- No instance found
    return __invalid_instance
end


--$static
--$return       table, bool
--$param        object      | Object    | The object to check.
--[[
Returns a table of all instances of the specified object,
and a boolean that is `true` if the table is *not* empty.

**NOTE:** The execution time scales with the number of
instances of the object, and can be *very* expensive at high numbers.
Try not to call this too much.
]]
Instance.find_all = function(object)
    local insts = {}
    local room_size = 200000    -- Should be sufficient

    local object = Wrap.unwrap(object)

    -- Check if object has a sprite (and therefore a collision mask)
    local holder = RValue.new_holder(1)
    holder[0] = RValue.new(object)
    local out = RValue.new(0)
    gmf.object_get_sprite(out, nil, nil, 1, holder)
    local has_sprite = (out.value >= 0)

    -- No collision mask
    if not has_sprite then
        local count = Instance.count(object)
        for n = 0, count - 1 do
            local holder = RValue.new_holder(2)
            holder[0] = RValue.new(object)
            holder[1] = RValue.new(n)
            local out = RValue.new(0)
            gmf.instance_find(out, nil, nil, 2, holder)
            local inst = RValue.to_wrapper(out)

            -- <Insert custom object finding here>
            
            if inst ~= -4 then table.insert(insts, inst) end
        end

    -- Collision mask; faster to use collision_rectangle_list
    else
        local list = List.new()

        local holder = RValue.new_holder(9)
        holder[0] = RValue.new(-room_size)
        holder[1] = RValue.new(-room_size)
        holder[2] = RValue.new(room_size)
        holder[3] = RValue.new(room_size)
        holder[4] = RValue.new(object)
        holder[5] = RValue.new(false)
        holder[6] = RValue.new(false)
        holder[7] = RValue.new(list.value)
        holder[8] = RValue.new(false)
        local out = RValue.new(0)
        gmf.collision_rectangle_list(out, nil, nil, 9, holder)

        for _, v in ipairs(list) do
            table.insert(insts, Instance.wrap(v))
        end

        list:destroy()

    end

    return insts, #insts > 0
end


--$static
--$return       number
--$param        object      | Object    | The object to check.
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


--$static
--$return       table
--$param        instance    | Instance  | The instance to get the table from.
--$optional     subtable    | string    | If specified, returns a different table under the ID `subtable`. <br>Useful for organization and preventing variable name conflicts within a mod itself. <br>This string can be whatever you want.
--$optional     namespace   | string    | If specified, returns another mod's table for the instance.
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


--$static
--$return       Instance
--$param        id          | number    | The instance ID to wrap.
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


--$static
--$return       bool
--$param        value       | RValue or Instance wrapper    | The value to check.
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

methods_instance = {

    --$instance
    --$aref         exists-instance
    --$return       bool
    --[[
    Returns `true` if the instance exists, and `false` otherwise.

    Also exists as a $static method, Instance#exists-static$.
    ]]
    exists = function(self)
        -- Return `false` if wrapper is invalid
        if self.value == -4 then return false end

        local holder = RValue.new_holder(1)
        holder[0] = RValue.new(self.value, RValue.Type.REF)
        local out = RValue.new(0)
        gmf.instance_exists(out, nil, nil, 1, holder)
        local ret = (RValue.to_wrapper(out) == 1)

        -- Make this wrapper invalid if the instance actually existn't
        if not ret then Proxy.set(self, -4) end

        return ret
    end,


    --$instance
    --[[
    Destroys the instance.
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


    --$instance
    --$return       bool
    --$param        object      | Object    | The object to check.
    --$optional     x           | number    | The x position to check at. <br>Uses this instance's current position by default.
    --$optional     y           | number    | The y position to check at. <br>Uses this instance's current position by default.
    --[[
    Returns `true` if this instance is colliding with *any* instance of the specified object.
    ]]
    is_colliding = function(self, object, x, y)
        -- Return `false` if wrapper is invalid
        if self.value == -4 then return false end

        local holder = RValue.new_holder_scr(3)
        holder[0] = RValue.new(x or self.x)
        holder[1] = RValue.new(y or self.y)
        holder[2] = RValue.from_wrapper(object)
        local out = RValue.new(0)
        gmf.place_meeting(self.CInstance, self.CInstance, out, 3, holder)
        return (out.value == 1)
    end

}

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



-- ========== Metatables ==========

metatable_instance = {
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
        return RValue.to_wrapper(out)
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
}



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
__invalid_instance = Proxy.new(-4, metatable_instance)

__class.Instance = Instance