-- Instance

Instance = new_class()



-- ========== Static Methods ==========

Instance.wrap = function(id)
    id = Wrap.unwrap(id)
    if (type(id) ~= "number") or (id < 100000) then log.error("Not a valid instance id", 2) end
    return Proxy.new(id, metatable_instance)
end



-- ========== Instance Methods ==========

methods_instance = {

    exists = function(self)
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
        if k == "type" then return getmetatable(t):sub(14, -1) end

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
    end,


    __eq = function(t, other)
        return t.value == other.value
    end,

    
    __metatable = "RAPI.Wrapper.Instance"
}



_CLASS["Instance"] = Instance