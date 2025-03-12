-- Instance

Instance = new_class()



-- ========== Static Methods ==========

Instance.wrap = function(id)
    id = Wrap.unwrap(id)
    if (type(id) ~= "number") or (id < 100000) then
        Proxy.new(-4, metatable_instance)   -- Wrap as invalid instance
    end
    return Proxy.new(id, metatable_instance)
end


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



-- ========== Instance Methods ==========

methods_instance = {

    exists = function(self)
        if self.value == -4 then return false end
        local holder = ffi.new("struct RValue[1]")
        holder[0] = RValue.new(self.value, RValue.Type.REF)
        local out = RValue.new(0)
        gmf.instance_exists(out, nil, nil, 1, holder)
        return RValue.to_wrapper(out) == 1
    end,


    destroy = function(self)
        local holder = ffi.new("struct RValue[1]")
        holder[0] = RValue.new(self.value, RValue.Type.REF)
        gmf.instance_destroy(nil, nil, nil, 1, holder)
    end

}



-- ========== Metatables ==========

metatable_instance = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(t) end
        if k == "RAPI" then return getmetatable(t):sub(14, -1) end

        -- Methods
        if methods_instance[k] then
            return methods_instance[k]
        end

        -- Getter
        local holder = ffi.new("struct RValue[2]")
        holder[0] = RValue.new(Proxy.get(t), RValue.Type.REF)
        holder[1] = RValue.new(k)
        local out = RValue.new(0)
        gmf.variable_instance_get(out, nil, nil, 2, holder)
        return RValue.to_wrapper(out)
    end,


    __newindex = function(t, k, v)
        -- Setter
        local holder = ffi.new("struct RValue[3]")
        holder[0] = RValue.new(Proxy.get(t), RValue.Type.REF)
        holder[1] = RValue.new(k)
        holder[2] = RValue.new(Wrap.unwrap(v))
        gmf.variable_instance_set(nil, nil, nil, 3, holder)
    end,


    __eq = function(t, other)
        return t.value == other.value
    end,

    
    __metatable = "RAPI.Wrapper.Instance"
}



_CLASS["Instance"] = Instance