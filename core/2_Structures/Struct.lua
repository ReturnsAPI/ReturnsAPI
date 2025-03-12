-- Struct

Struct = new_class()



-- ========== Static Methods ==========

Struct.new = function()
    local out = RValue.new(0)
    gmf.struct_create(out, nil, nil, 0, nil)
    return Struct.wrap(out)
end


Struct.wrap = function(struct)
    struct = Wrap.unwrap(struct)
    if not Struct.is(struct) then log.error("Value is not a struct", 2) end
    __ref_list:add(struct)
    return Proxy.new_gc(struct, metatable_struct)
end


Struct.is = function(value)
    value = Wrap.unwrap(value)
    if type(value) == "cdata"
    and value.type == RValue.Type.OBJECT
    and value.yy_object_base.type == 0 then return true end
    return false
end



-- ========== Instance Methods ==========

methods_struct = {

    get_keys = function(self)
        local holder = ffi.new("struct RValue[1]")
        holder[0] = RValue.new(self.value.yy_object_base, RValue.Type.OBJECT)
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
        if k == "value" then return Proxy.get(t) end
        if k == "RAPI" then return getmetatable(t):sub(14, -1) end

        -- Methods
        if methods_struct[k] then
            return methods_struct[k]
        end
        
        -- Getter
        local holder = ffi.new("struct RValue[2]")
        holder[0] = RValue.new(Proxy.get(t).yy_object_base, RValue.Type.OBJECT)
        holder[1] = RValue.new(k)
        local out = RValue.new(0)
        gmf.variable_struct_get(out, nil, nil, 2, holder)
        return RValue.to_wrapper(out)
    end,


    __newindex = function(t, k, v)
        -- Setter
        local holder = ffi.new("struct RValue[3]")
        holder[0] = RValue.new(Proxy.get(t).yy_object_base, RValue.Type.OBJECT)
        holder[1] = RValue.new(k)
        holder[2] = RValue.new(Wrap.unwrap(v))
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


    __gc = function(t)
        __ref_list:remove(t.value)
    end,


    __metatable = "RAPI.Wrapper.Struct"
}



_CLASS["Struct"] = Struct