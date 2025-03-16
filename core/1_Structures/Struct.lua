-- Struct

Struct = new_class()



-- ========== Static Methods ==========

Struct.new = function()
    local rvalue_struct = RValue.new(ffi.cast("struct YYObjectBase*", gm.gmf_struct_create()), RValue.Type.OBJECT)
    return Struct.wrap(rvalue_struct)
end


Struct.wrap = function(struct)  -- Stores 'object RValue.yy_object_base (type 0)'
    -- `struct` is either an `object RValue` or a Struct wrapper
    if not Struct.is(struct) then log.error("Value is not a struct", 2) end
    local proxy = Proxy.new_gc(struct.yy_object_base, metatable_struct)
    __ref_list:add(proxy)
    return proxy
end


Struct.is = function(value)
    -- `value` is either an `object RValue` or a Struct wrapper
    local _type = type(value)
    if (_type == "cdata" and value.type == RValue.Type.OBJECT)
    or (_type == "table" and value.RAPI and value.RAPI == "Struct") then return true end
    return false
end



-- ========== Instance Methods ==========

methods_struct = {

    get_keys = function(self)
        local holder = RValue.new_holder(1)
        holder[0] = RValue.new(self.value, RValue.Type.OBJECT)
        local out = RValue.new(0)
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
        if k == "value" or k == "yy_object_base" then return Proxy.get(t) end
        if k == "RAPI" then return getmetatable(t):sub(14, -1) end

        -- Methods
        if methods_struct[k] then
            return methods_struct[k]
        end
        
        -- Getter
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(Proxy.get(t), RValue.Type.OBJECT)
        holder[1] = RValue.new(k)
        local out = RValue.new(0)
        gmf.variable_struct_get(out, nil, nil, 2, holder)
        return RValue.to_wrapper(out)
    end,


    __newindex = function(t, k, v)
        -- Setter
        local holder = RValue.new_holder(3)
        holder[0] = RValue.new(Proxy.get(t), RValue.Type.OBJECT)
        holder[1] = RValue.new(k)
        holder[2] = RValue.from_wrapper(v)
        gmf.variable_struct_set(RValue.new(0), nil, nil, 3, holder)
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


    __gc = function(t)
        -- print("Struct __gc: ", t.value)
        if not t.value then return end
        __ref_list:delete_value(t)
    end,


    __metatable = "RAPI.Wrapper.Struct"
}



_CLASS["Struct"] = Struct