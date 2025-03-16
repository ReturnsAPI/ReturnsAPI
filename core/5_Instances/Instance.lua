-- Instance

Instance = new_class()

local instance_data = {}
local wrapper_cache = setmetatable({}, {__mode = "v"})



-- ========== Static Methods ==========

--$static
--$return       Instance
--$param        object  | Object    | The object to spawn.
--$param        x       | number    | The x spawn coordinate.
--$param        y       | number    | The y spawn coordinate.
--[[
Creates and returns an instance of the specified object.

Also exists as a $method of Object, Object#create$.
]]
Instance.create = function(x, y, object)
    local holder = RValue.new_holder_scr(3)
    holder[0] = RValue.new(x)
    holder[1] = RValue.new(y)
    holder[2] = RValue.from_wrapper(object)
    local out = RValue.new(0)
    gmf.instance_create(nil, nil, out, 3, holder)
    return RValue.to_wrapper(out)
end


--$static
--$return       Instance
--$param        object  | Object or table   | The object to check. <br>Alternatively, a single table containing multiple can be provided.
--[[
Returns the first instance of the specified object(s),
or an invalid instance (value of `-4`).
]]
Instance.find = function(object)
    -- Single find
    if type(object) ~= "table" or object.RAPI then
        local holder = RValue.new_holder(2)
        holder[0] = RValue.from_wrapper(object)
        holder[1] = RValue.new(0)
        local out = RValue.new(0)
        gmf.instance_find(out, nil, nil, 2, holder)
        local inst = RValue.to_wrapper(out)
        if inst ~= -4 then return inst end
        return Instance.wrap(-4)

    -- Table
    else
        for _, obj in ipairs(object) do
            local holder = RValue.new_holder(2)
            holder[0] = RValue.from_wrapper(obj)
            holder[1] = RValue.new(0)
            local out = RValue.new(0)
            gmf.instance_find(out, nil, nil, 2, holder)
            local inst = RValue.to_wrapper(out)
    
            -- <Insert custom object finding here>
    
            if inst ~= -4 then return inst end
        end

        -- No instance found
        return Instance.wrap(-4)

    end
end


--$static
--$return       table, bool
--$param        object  | Object or table   | The object to check. <br>Alternatively, a single table containing multiple can be provided.
--[[
Returns a table of all instances of the specified object(s),
and a boolean that is `true` if the table is *not* empty.

**NOTE:** The execution time scales with the number of
instances of the object, and can be very expensive at high numbers.
Try not to call this too much.
]]
Instance.find_all = function(object)
    local insts = {}
    local room_size = 200000

    -- Single find
    if type(object) ~= "table" or object.RAPI then
        object = Wrap.unwrap(object)

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

            for i, v in ipairs(list) do
                table.insert(insts, v)
            end

            list:destroy()
        
        end

    -- Table
    else
        for _, obj in ipairs(object) do
            obj = Wrap.unwrap(obj)

            -- Check if object has a sprite (and therefore a collision mask)
            local holder = RValue.new_holder(1)
            holder[0] = RValue.new(obj)
            local out = RValue.new(0)
            gmf.object_get_sprite(out, nil, nil, 1, holder)
            local has_sprite = (out.value >= 0)

            -- No collision mask
            if not has_sprite then
                local count = Instance.count(obj)
                for n = 0, count - 1 do
                    local holder = RValue.new_holder(2)
                    holder[0] = RValue.new(obj)
                    holder[1] = RValue.new(n)
                    local out = RValue.new(0)
                    gmf.instance_find(out, nil, nil, 2, holder)
                    local inst = RValue.to_wrapper(out)
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
                holder[4] = RValue.new(obj)
                holder[5] = RValue.new(false)
                holder[6] = RValue.new(false)
                holder[7] = RValue.new(list.value)
                holder[8] = RValue.new(false)
                local out = RValue.new(0)
                gmf.collision_rectangle_list(out, nil, nil, 9, holder)

                for i, v in ipairs(list) do
                    table.insert(insts, v)
                end

                list:destroy()

            end
        end
    end

    return insts, #insts > 0
end


--$static
--$return       number
--$param        object  | Object    | The object to check.
--[[
Returns the instance count of the specified object.
]]
Instance.count = function(object)
    local holder = RValue.new_holder_scr(1)
    holder[0] = RValue.from_wrapper(object)
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

This table is useful for storing lua data (such as tables) in instances, which cannot be done with normal instance variables.
It is automatically deleted upon the instance's destruction.
]]
Instance.get_data = function(instance, subtable, namespace, default_namespace)
    id = Wrap.unwrap(instance)
    if (type(id) ~= "number") or (id < 100000) then log.error("Instance does not exist", 2) end
    subtable = subtable or "__main"
    namespace = namespace or "RAPI" -- Internal RAPI calling of this is not namespace-bound
    if not instance_data[id] then instance_data[id] = {} end
    if not instance_data[id][namespace] then instance_data[id][namespace] = {} end
    if not instance_data[id][namespace][subtable] then instance_data[id][namespace][subtable] = {} end
    return instance_data[id][namespace][subtable]
end


--$static
--$return       Instance
--$param        id      | number    | The instance ID to wrap.
--[[
Returns an Instance wrapper containing the provided instance.
]]
Instance.wrap = function(id)
    id = Wrap.unwrap(id)
    if (type(id) ~= "number") or (id < 100000) then
        Proxy.new(-4, metatable_instance)   -- Wrap as invalid instance
    end

    -- Check cache
    if wrapper_cache[id] then return wrapper_cache[id] end

    -- Instance
    local inst = Proxy.new(id, metatable_instance)
    if inst.value == -4 then
        wrapper_cache[id] = inst
        return inst
    end

    local obj_index = inst.object_index

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
    if RValue.to_wrapper(out) == 1 then
        inst = Proxy.new(id, metatable_actor)
        wrapper_cache[id] = inst
        return inst
    end

    return inst
end


local inst_wrappers = {
    "Instance",
    "Actor",
    "Player"
}

Instance.is = function(value)
    -- `value` is either a `ref RValue` or an Instance wrapper
    local _type = type(value)
    if (_type == "cdata" and value.type == RValue.Type.REF)
    or (_type == "table" and inst_wrappers[value.RAPI]) then return true end
    return false
end



-- ========== Instance Methods ==========

methods_instance = {

    --$instance
    --$return       bool
    --[[
    Returns `true` if the instance exists, and `false` otherwise.
    ]]
    exists = function(self)
        if self.value == -4 then return false end
        local holder = RValue.new_holder(1)
        holder[0] = RValue.new(self.value, RValue.Type.REF)
        local out = RValue.new(0)
        gmf.instance_exists(out, nil, nil, 1, holder)
        local ret = (RValue.to_wrapper(out) == 1)
        if not ret then Proxy.set(self, -4) end
        return ret
    end,


    --$instance
    --[[
    Destroys the instance.
    ]]
    destroy = function(self)
        local holder = RValue.new_holder(1)
        holder[0] = RValue.new(self.value, RValue.Type.REF)
        gmf.instance_destroy(RValue.new(0), nil, nil, 1, holder)
        instance_data[self.value] = nil
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
        if self.value == -4 then return false end
        object = Wrap.unwrap(object)
        return self:place_meeting(x or self.x, y or self.y, object) == 1
    end

}

-- Add GM scripts
for scr, _ in pairs(GM.internal.builtin) do
    methods_instance[scr] = function(self, ...)
        methods_GM.callso(scr)(self, self, ...)
    end
end
for scr, _ in pairs(GM.internal.script) do
    methods_instance[scr] = function(self, ...)
        methods_GM.callso(scr)(self, self, ...)
    end
end



-- ========== Metatables ==========

metatable_instance = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" or k == "id" then return Proxy.get(t) end
        if k == "RAPI" then return getmetatable(t):sub(14, -1) end
        if k == "CInstance" then return ffi.cast("struct CInstance*", gm.CInstance.instance_id_to_CInstance_ffi[Proxy.get(t)]) end

        -- Methods
        if methods_instance[k] then
            return methods_instance[k]
        end

        -- Getter
        local id = Proxy.get(t)
        if id == -4 then log.error("Instance does not exist", 2) end
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(id, RValue.Type.REF)
        holder[1] = RValue.new(k)
        local out = RValue.new(0)
        gmf.variable_instance_get(out, nil, nil, 2, holder)
        return RValue.to_wrapper(out)
    end,


    __newindex = function(t, k, v)
        -- Setter
        local id = Proxy.get(t)
        if id == -4 then log.error("Instance does not exist", 2) end
        local holder = RValue.new_holder(3)
        holder[0] = RValue.new(id, RValue.Type.REF)
        holder[1] = RValue.new(k)
        holder[2] = RValue.from_wrapper(v)
        gmf.variable_instance_set(RValue.new(0), nil, nil, 3, holder)
    end,


    __eq = function(t, other)
        return t.value == other.value
    end,

    
    __metatable = "RAPI.Wrapper.Instance"
}



-- ========== instance_data GC ==========

-- TODO replace with memory.dynamic_hook

gm.post_script_hook(gm.constants.room_goto, function(self, other, result, args)
    -- On room change, remove non-existent instances from `instance_data`
    for k, v in pairs(instance_data) do
        if gm.instance_exists(k) == 0 then
            instance_data[k] = nil
        end
    end
end)


gm.post_script_hook(gm.constants.actor_set_dead, function(self, other, result, args)
    -- Remove `instance_data` on non-player kill
    local actor = args[1].value
    if actor.object_index ~= gm.constants.oP then
        instance_data[actor.id] = nil
    end
end)


gm.post_script_hook(gm.constants.actor_transform, function(self, other, result, args)
    -- Move `instance_data` to new instance
    local id = args[1].value.id
    if instance_data[id] then
        instance_data[args[2].value.id] = instance_data[id]
        instance_data[id] = nil
    end
end)



_CLASS["Instance"] = Instance