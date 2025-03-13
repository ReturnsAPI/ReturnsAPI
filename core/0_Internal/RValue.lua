-- RValue

RValue = new_class()



-- ========== Enums ==========

RValue.Type = {
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

for k, v in pairs(RValue.Type) do
    RValue.Type[v] = k
end

RValue.Type = ReadOnly.new(RValue.Type)



-- ========== Static Methods ==========

RValue.to_wrapper = function(rvalue)
    if type(rvalue) ~= "cdata" then return rvalue end

    local rvalue_type = rvalue.type

    if      rvalue_type == RValue.Type.REAL         then return rvalue.value
    elseif  rvalue_type == RValue.Type.STRING       then return ffi.string(rvalue.ref_string.m_str)
    elseif  rvalue_type == RValue.Type.ARRAY        then return Array.wrap(rvalue)
    elseif  rvalue_type == RValue.Type.PTR          then return rvalue.i64
    elseif  rvalue_type == RValue.Type.UNDEFINED    then return nil
    elseif  rvalue_type == RValue.Type.OBJECT then
        local yyobjectbase = rvalue.yy_object_base
        if      yyobjectbase.type == 1  then return rvalue.cinstance
        elseif  yyobjectbase.type == 3  then return rvalue.cscriptref
        end
        return Struct.wrap(rvalue)
    elseif  rvalue_type == RValue.Type.INT32        then return rvalue.i32
    elseif  rvalue_type == RValue.Type.INT64        then return rvalue.i64
    elseif  rvalue_type == RValue.Type.BOOL         then return (rvalue.value ~= nil and rvalue.value ~= 0)
    elseif  rvalue_type == RValue.Type.REF          then return Instance.wrap(rvalue.i32)
    end

    return nil  -- Unset
end


-- If passing in an output from Wrap.unwrap,
-- make sure *both* return values are passed in
-- Having them be on the same line works ( e.g., RValue.new(Wrap.unwrap(value)) )
RValue.new = function(val, rvalue_type)
    -- No RValue.Type specified; lua primitives
    if not rvalue_type then
        local type_val = type(val)
        if type_val == "number" then
            local rvalue = ffi.new("struct RValue")
            rvalue.value = val
            return rvalue
        elseif type_val == "string" then
            local rvalue = ffi.new("struct RValue[1]")
            gmf.yysetstring(rvalue, val)
            return rvalue[0]
        else
            return val
        end
    end

    -- RValue.Type.STRING
    if rvalue_type == RValue.Type.STRING then
        local rvalue = ffi.new("struct RValue[1]")
        gmf.yysetstring(rvalue, val)
        return rvalue[0]
    end
    
    -- Other RValue.Type
    local rvalue = ffi.new("struct RValue")
	rvalue.type = rvalue_type
    if      rvalue_type == RValue.Type.REAL         then rvalue.value = val
    elseif  rvalue_type == RValue.Type.ARRAY        then rvalue.i64 = val
    elseif  rvalue_type == RValue.Type.PTR          then rvalue.i64 = val
    elseif  rvalue_type == RValue.Type.UNDEFINED    then -- Nothing
    elseif  rvalue_type == RValue.Type.OBJECT       then rvalue.yy_object_base = val
    elseif  rvalue_type == RValue.Type.INT32        then rvalue.i32 = val
    elseif  rvalue_type == RValue.Type.INT64        then rvalue.i64 = val
    elseif  rvalue_type == RValue.Type.BOOL         then rvalue.value = val
    elseif  rvalue_type == RValue.Type.REF          then rvalue.i32 = val
    else    return nil
    end
	return rvalue
end



_CLASS["RValue"] = RValue