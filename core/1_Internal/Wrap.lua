-- Wrap

Wrap = new_class()



-- ========== Static Methods ==========

local lua_type_lookup = {
    number      = RValue.Type.REAL,
    string      = RValue.Type.STRING,
    boolean     = RValue.Type.BOOL
}

local rvalue_type_lookup = {
    Array       = RValue.Type.ARRAY,
    Struct      = RValue.Type.OBJECT,

    Instance    = RValue.Type.REF,
    Actor       = RValue.Type.REF,
    Player      = RValue.Type.REF,
}

-- May return an RValue.Type as a second value
-- Make sure this gets passed into RValue.new if using that
-- Having them be on the same line works ( e.g., RValue.new(Wrap.unwrap(value)) )
Wrap.unwrap = function(value)
    local type_value = type(value)
    local rvalue_type = nil --lua_type_lookup[type_value]
    if type_value == "table" and value.RAPI then
        rvalue_type = rvalue_type_lookup[value.RAPI]
    end
    return Proxy.get(value) or value, rvalue_type
end



_CLASS["Wrap"] = Wrap