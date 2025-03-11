-- Struct

Struct = new_class()



-- ========== Static Methods ==========

Struct.new = function()
    local out = gmf.rvalue_new(0)
    gmf.struct_create(out, nil, nil, 0, nil)
    return Struct.wrap(out)
end


Struct.wrap = function(struct)
    if not Struct.is(struct) then log.error("Value is not a struct", 2) end
    return Proxy.new(struct, metatable_struct)
end


Struct.is = function(value)
    value = Wrap.unwrap(value)
    if type(value) == "cdata"
    and value.type == Wrap.Type.OBJECT
    and value.yy_object_base.type == 0 then return true end
    return false
end



-- ========== Instance Methods ==========

methods_struct = {

    get_keys = function(self)
        print("get_keys")
        local holder = ffi.new("struct RValue[1]")
        holder[0] = gmf.rvalue_new_object(self.value.yy_object_base)
        local out = gmf.rvalue_new(0)
        gmf.variable_struct_get_names(out, nil, nil, 1, holder)
        local arr = Array.wrap(out)
        local keys = {}
        for i, v in ipairs(arr) do keys[i] = v end
        return keys
    end

}



-- ========== Metatables ==========

metatable_struct = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(t) end
        if k == "type" then return getmetatable(t):sub(14, -1) end

        -- Methods
        if methods_struct[k] then
            return methods_struct[k]
        end
        
        -- Getter
        local holder = ffi.new("struct RValue[2]")
        holder[0] = gmf.rvalue_new_object(Proxy.get(t).yy_object_base)
        holder[1] = gmf.rvalue_new_string(k)
        local out = gmf.rvalue_new(0)
        gmf.variable_struct_get(out, nil, nil, 2, holder)
        return Wrap.wrap(out)
    end,


    __newindex = function(t, k, v)
        -- Setter
        local holder = ffi.new("struct RValue[3]")
        holder[0] = gmf.rvalue_new_object(Proxy.get(t).yy_object_base)
        holder[1] = gmf.rvalue_new_string(k)
        holder[2] = gmf.rvalue_new_auto(Wrap.unwrap(v))
        gmf.variable_struct_set(nil, nil, nil, 3, holder)
    end,


    __pairs = function(t)
        local keys = t:get_keys()
        local i = 0
        return function(t)
            i = i + 1
            if i <= #keys then
                local k = keys[i]
                return k, t[k]
            end
        end, t, nil
    end,


    __metatable = "RAPI.Wrapper.Struct"
}



_CLASS["Struct"] = Struct