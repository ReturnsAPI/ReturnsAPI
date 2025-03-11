-- Struct

Struct = new_class()



-- ========== Static Methods ==========

Struct.wrap = function(struct)
    return Proxy.new(struct, metatable_struct)
end



-- ========== Metatables ==========

-- local get_keys = function(t, k)
--     local holder = ffi.new("struct RValue[1]")  -- args holder

--     -- hitinfo
--     holder[0] = ffi.new("struct RValue")
--     holder[0].type = 6
--     holder[0].yy_object_base = Proxy.get(t)

--     gmf.variable_struct_get_names(out, nil, nil, 1, holder)
--     -- local array = rvalue_to_lua(out)
--     -- return Array.wrap(array)
--     -- return array
--     return out
-- end

metatable_struct = {
    __index = function(t, k)
        -- if k == "keys" then return get_keys(t, k) end

        -- Get wrapped value
        if k == "value" then return Proxy.get(t) end
        if k == "type" then return getmetatable(t):sub(14, -1) end
        
        --- Getter
        local holder = ffi.new("struct RValue[2]")  -- args holder

        -- hitinfo
        holder[0] = ffi.new("struct RValue")
        holder[0].type = 6
        holder[0].yy_object_base = Proxy.get(t)

        -- key
        holder[1] = gmf.rvalue_new_string(k)

        local out = gmf.rvalue_new(0)
        gmf.variable_struct_get(out, nil, nil, 2, holder)
        return Wrap.wrap(out)
    end,


    __newindex = function(t, k, v)
        --- Setter
        local holder = ffi.new("struct RValue[3]")  -- args holder

        -- hitinfo
        holder[0] = ffi.new("struct RValue")
        holder[0].type = 6
        holder[0].yy_object_base = Proxy.get(t)

        -- key
        holder[1] = gmf.rvalue_new_string(k)

        -- value
        v = Wrap.unwrap(v)
        if type(v) == "string" then holder[2] = gmf.rvalue_new_string(v)
        else holder[2] = gmf.rvalue_new(v) end

        gmf.variable_struct_set(nil, nil, nil, 3, holder)
    end,


    __metatable = "RAPI.Wrapper.Struct"
}



_CLASS["Struct"] = Struct