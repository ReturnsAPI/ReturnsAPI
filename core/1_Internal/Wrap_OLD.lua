-- Wrap

return

Wrap = new_class()



-- ========== Enums ==========

Wrap.Type = {
    REAL        = 0,
    STRING      = 1,
    ARRAY       = 2,
    PTR         = 3,
    UNDEFINED   = 5,
    OBJECT      = 6,
    INT32       = 7,
    INT64       = 10,
    BOOL        = 13,
    REF         = 15
}

for k, v in pairs(Wrap.Type) do
    Wrap.Type[v] = k
end



-- ========== Static Methods ==========

Wrap.wrap = function(rvalue)
    if type(rvalue) ~= "cdata" then return rvalue end
    local rvalue_type = rvalue.type
    if      rvalue_type == 0 then   -- real
        return rvalue.value, 0
    elseif  rvalue_type == 1 then   -- string
        return ffi.string(rvalue.ref_string.m_str), 1
    elseif  rvalue_type == 2 then   -- array
        return Array.wrap(rvalue), 2
    elseif  rvalue_type == 3 then   -- ptr
        return rvalue.i64, 3
    elseif  rvalue_type == 5 then   -- undefined
        return nil, 5
    elseif  rvalue_type == 6 then   -- object
        local yyobjectbase = rvalue.yy_object_base
        if yyobjectbase.type == 1 then
            return rvalue.cinstance, 6.1
            -- return Instance.wrap(rvalue.cinstance), 6
        elseif yyobjectbase.type == 3 then
            return rvalue.cscriptref, 6.2
        end
        -- struct(?)
        return Struct.wrap(rvalue), 6.3
    elseif  rvalue_type == 7 then   -- int32
        return rvalue.i32, 7
    elseif  rvalue_type == 10 then  -- int64
        return rvalue.i64, 10
    elseif  rvalue_type == 13 then  -- bool
        local rvalue_value = rvalue.value
        return (rvalue_value ~= nil and rvalue_value ~= 0), 13
    elseif  rvalue_type == 15 then  -- ref (cinstance id)
        -- return rvalue.i32, 15
        return Instance.wrap(rvalue.i32), 15
    end
    return nil                      -- unset
end


Wrap.unwrap = function(value)
    local RAPI = nil
    if type(value) == "table" then RAPI = value.RAPI end
    return Proxy.get(value) or value, RAPI
end



_CLASS["Wrap"] = Wrap