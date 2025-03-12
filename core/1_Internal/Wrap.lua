-- Wrap

Wrap = new_class()



-- ========== Static Methods ==========

local rvalue_type_lookup = {
    Array       = RValue.Type.ARRAY,
    Struct      = RValue.Type.OBJECT,

    Instance    = RValue.Type.REF,
}

-- May return an RValue.Type as a second value
-- Make sure this gets passed into RValue.new if using that; having them be on the same line works
Wrap.unwrap = function(value)
    local rvalue_type = nil
    if type(value) == "table" and value.RAPI then
        rvalue_type = rvalue_type_lookup[value.RAPI]
    end
    return Proxy.get(value) or value, rvalue_type
end



_CLASS["Wrap"] = Wrap