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


local rvalue_type_lookup = {
    number      = RValue.Type.REAL,
    string      = RValue.Type.STRING,
    boolean     = RValue.Type.BOOL,

    Array       = RValue.Type.ARRAY,
    Struct      = RValue.Type.OBJECT,

    Instance    = RValue.Type.REF,
    Actor       = RValue.Type.REF,
    Player      = RValue.Type.REF,
}



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
        -- return Struct.wrap(rvalue)
        return yyobjectbase
    elseif  rvalue_type == RValue.Type.INT32        then return tonumber(rvalue.i32)  -- Don't see any immediate consequences of doing this
    elseif  rvalue_type == RValue.Type.INT64        then return tonumber(rvalue.i64)
    elseif  rvalue_type == RValue.Type.BOOL         then return (rvalue.value ~= nil and rvalue.value ~= 0)
    -- elseif  rvalue_type == RValue.Type.REF          then return Instance.wrap(rvalue.i32)
    elseif  rvalue_type == RValue.Type.REF          then return tonumber(rvalue.i32)
    end

    return nil  -- Unset
end


-- Variant of Wrap.unwrap that places it into and returns an RValue
RValue.from_wrapper = function(value)
    -- Get correct RValue.Type
    local _type = Util.type(value)
    local _type_rvalue = rvalue_type_lookup[_type]
    if _type == "table" and value.RAPI then
        value = Proxy.get(value)
    end

    -- Make an RValue
    return RValue.new(value, _type_rvalue)
end


RValue.peek = function(rvalue)
    if type(rvalue) ~= "cdata" then return end

    local rvalue_type = rvalue.type
    local str = ""

    if      rvalue_type == RValue.Type.REAL         then str = "value: "..tostring(rvalue.value)
    elseif  rvalue_type == RValue.Type.STRING       then str = "m_str: "..tostring(rvalue.ref_string.m_str)
    elseif  rvalue_type == RValue.Type.ARRAY        then str = "i64: "..tostring(rvalue.i64)
    elseif  rvalue_type == RValue.Type.PTR          then str = "i64: "..tostring(rvalue.i64)
    elseif  rvalue_type == RValue.Type.UNDEFINED    then str = "i64: "..tostring(rvalue.i64)
    elseif  rvalue_type == RValue.Type.OBJECT then
        local yyob = rvalue.yy_object_base
        str = "yy_object_base: "..tostring(yyob)..", ".."yyob.type: "..tostring(yyob.type)
    elseif  rvalue_type == RValue.Type.INT32        then str = "i32: "..tostring(rvalue.i32)
    elseif  rvalue_type == RValue.Type.INT64        then str = "i64: "..tostring(rvalue.i64)
    elseif  rvalue_type == RValue.Type.BOOL         then str = "bool: "..tostring(rvalue.value ~= nil and rvalue.value ~= 0)
    elseif  rvalue_type == RValue.Type.REF          then str = "i32: "..tostring(rvalue.i32)
    end

    print("type: "..RValue.Type[rvalue_type], str, "__flags: "..tostring(rvalue.__flags))
end


RValue.new = function(val, rvalue_type)
    -- Return RValue.Type.UNDEFINED if `val` is nil
    if val == nil then
        local rvalue = ffi.new("struct RValue")
        rvalue.type = RValue.Type.UNDEFINED
        rvalue.i64 = 0
        return rvalue
    end

    -- No RValue.Type specified; lua primitives
    if not rvalue_type then
        local type_val = type(val)
        if type_val == "number" then
            local rvalue = ffi.new("struct RValue")
            rvalue.type = RValue.Type.REAL
            rvalue.value = val
            return rvalue
        elseif type_val == "string" then
            local rvalue = ffi.new("struct RValue[1]")
            gmf.yysetstring(rvalue, val)
            return rvalue[0]
        elseif type_val == "boolean" then
            local rvalue = ffi.new("struct RValue")
            rvalue.type = RValue.Type.BOOL
            rvalue.value = val
            return rvalue
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
    if type(val) ~= "table" then
        local rvalue = ffi.new("struct RValue")
        rvalue.type = rvalue_type
        if      rvalue_type == RValue.Type.REAL         then rvalue.value = val
        elseif  rvalue_type == RValue.Type.ARRAY        then rvalue.i64 = val
        elseif  rvalue_type == RValue.Type.PTR          then rvalue.i64 = val
        elseif  rvalue_type == RValue.Type.UNDEFINED    then rvalue.i64 = 0
        elseif  rvalue_type == RValue.Type.OBJECT       then rvalue.yy_object_base = val
        elseif  rvalue_type == RValue.Type.INT32        then rvalue.i32 = val
        elseif  rvalue_type == RValue.Type.INT64        then rvalue.i64 = val
        elseif  rvalue_type == RValue.Type.BOOL         then rvalue.value = val
        elseif  rvalue_type == RValue.Type.REF          then rvalue.i32 = val
        else    return nil
        end
        return rvalue
    end

    -- Should not happen, so log it
    log.error("RValue.new: Table passed in, val = "..tostring(val)..", rvalue_type = "..tostring(rvalue_type), 2)
end


RValue.new_holder = function(size)
    return ffi.new("struct RValue["..size.."]")
end


RValue.new_holder_scr = function(size)
    return ffi.new("struct RValue*["..size.."]")
end



__class.RValue = RValue