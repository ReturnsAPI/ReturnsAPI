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
        holder[0] = gmf.rvalue_new(object)
        holder[1] = gmf.rvalue_new(0)
        local out = gmf.rvalue_new(0)
        gmf.instance_find(out, nil, nil, 2, holder)
        local inst = Wrap.wrap(out)

        -- <Insert custom object finding here>

        if inst:exists() then return inst end
    end

    -- No instance found
    return Instance.wrap(-4)
end



-- ========== Instance Methods ==========

methods_instance = {

    exists = function(self)
        if self.value == -4 then return false end
        local holder = ffi.new("struct RValue[1]")
        holder[0] = gmf.rvalue_new(self.value)
        local out = gmf.rvalue_new(0)
        gmf.instance_exists(out, nil, nil, 1, holder)
        return Wrap.wrap(out) == 1
    end,


    destroy = function(self)
        local holder = ffi.new("struct RValue[1]")
        holder[0] = gmf.rvalue_new(self.value)
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
        holder[0] = gmf.rvalue_new(Proxy.get(t))
        holder[1] = gmf.rvalue_new_string(k)
        local out = gmf.rvalue_new(0)
        gmf.variable_instance_get(out, nil, nil, 2, holder)
        return Wrap.wrap(out)
    end,


    __newindex = function(t, k, v)
        -- Setter
        local holder = ffi.new("struct RValue[3]")
        holder[0] = gmf.rvalue_new(Proxy.get(t))
        holder[1] = gmf.rvalue_new_string(k)
        holder[2] = gmf.rvalue_new_auto(Wrap.unwrap(v))
        gmf.variable_instance_set(nil, nil, nil, 3, holder)

        -- TODO: When setting an Instance back into an instance variable,
        -- make sure it's marked as a REF value and not a normal number
        -- Can do this by passing a second return value with Wrap.unwrap saying that it is a Wrap.Type.REF (possibly)
        -- This also goes for data structures, globals, etc.
    end,


    __eq = function(t, other)
        return t.value == other.value
    end,

    
    __metatable = "RAPI.Wrapper.Instance"
}



_CLASS["Instance"] = Instance