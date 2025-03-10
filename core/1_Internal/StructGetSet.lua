-- Struct

local out = gmf.rvalue_new(0)

metatable_struct_getset = {
    __index = function(t, k)
        local holder = ffi.new("struct RValue[2]")  -- args holder

        -- hitinfo
        holder[0] = ffi.new("struct RValue")
        holder[0].type = 6
        holder[0].yy_object_base = Proxy.get(t)

        -- key
        holder[1] = gmf.rvalue_new_string(k)

        gmf.variable_struct_get(out, nil, nil, 2, holder)
        local ret_val, is_instance_id = rvalue_to_lua(out)
        if is_instance_id then ret_val = gm.CInstance.instance_id_to_CInstance[ret_val] end
        return Wrap.wrap(ret_val)
    end,


    __newindex = function(t, k, v)
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

        gmf.variable_struct_set(out, nil, nil, 3, holder)
    end
}