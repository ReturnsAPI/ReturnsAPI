-- Wrap

Wrap = {}



-- ========== Static Methods ==========

Wrap.wrap = function(value)
    value = Wrap.unwrap(value)

    -- Array
    if userdata_type(value) == "sol.RefDynamicArrayOfRValue*" then
        return Proxy.new(value, metatable_array)
    end

    -- Instance
    if userdata_type(value) == "sol.CInstance*" then
        return Instance_wrap_internal(value)
    end

    return value
end


Wrap.unwrap = function(value)
    return Proxy.get(value) or value
end



_CLASS["Wrap"] = Wrap