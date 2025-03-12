-- Instance

Instance = new_class()

local instance_data = {}



-- ========== Static Methods ==========

Instance.find = function(...)
    local t = {...}     -- Variable number of object_indexes

    -- If argument is a non-wrapper table, use it as the loop table
    if type(t[1]) == "table" and (not t[1].RAPI) then t = t[1] end

    -- Loop through object_indexes
    for _, object in ipairs(t) do
        object = Wrap.unwrap(object)

        local holder = ffi.new("struct RValue[2]")
        holder[0] = RValue.new(object)
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


Instance.wrap = function(id)
    id = Wrap.unwrap(id)
    if (type(id) ~= "number") or (id < 100000) then
        Proxy.new(-4, metatable_instance)   -- Wrap as invalid instance
    end
    return Proxy.new(id, metatable_instance)
end


-- ========== Instance Methods ==========

methods_instance = {

    exists = function(self)
        if self.value == -4 then return false end
        local holder = ffi.new("struct RValue[1]")
        holder[0] = RValue.new(self.value, RValue.Type.REF)
        local out = RValue.new(0)
        gmf.instance_exists(out, nil, nil, 1, holder)
        local ret = (RValue.to_wrapper(out) == 1)
        if not ret then Proxy.get(self) = -4 end
        return ret
    end,


    destroy = function(self)
        local holder = ffi.new("struct RValue[1]")
        holder[0] = RValue.new(self.value, RValue.Type.REF)
        gmf.instance_destroy(nil, nil, nil, 1, holder)
        instance_data[self.value] = nil
        Proxy.get(self) = -4
    end

}



-- ========== Metatables ==========

metatable_instance = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" or k == "id" then return Proxy.get(t) end
        if k == "RAPI" then return getmetatable(t):sub(14, -1) end

        -- Methods
        if methods_instance[k] then
            return methods_instance[k]
        end

        -- Getter
        local id = Proxy.get(t)
        if id == -4 then log.error("Cannot get from non-existent instance", 2) end
        local holder = ffi.new("struct RValue[2]")
        holder[0] = RValue.new(id, RValue.Type.REF)
        holder[1] = RValue.new(k)
        local out = RValue.new(0)
        gmf.variable_instance_get(out, nil, nil, 2, holder)
        return RValue.to_wrapper(out)
    end,


    __newindex = function(t, k, v)
        -- Setter
        local id = Proxy.get(t)
        if id == -4 then log.error("Cannot set to non-existent instance", 2) end
        local holder = ffi.new("struct RValue[3]")
        holder[0] = RValue.new(id, RValue.Type.REF)
        holder[1] = RValue.new(k)
        holder[2] = RValue.new(Wrap.unwrap(v))
        gmf.variable_instance_set(nil, nil, nil, 3, holder)
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