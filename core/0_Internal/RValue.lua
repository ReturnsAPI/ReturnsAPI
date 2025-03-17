-- RValue

RValue = new_class()

local holder = ffi.new("struct RValue[0]")
local holder_scr = ffi.new("struct RValue*[0]")
local holder_size = 0
local holder_size_scr = 0
local rvalue_cache = {}
for i = 1, 100000 do rvalue_cache[i] = ffi.new("struct RValue") end
local rvalue_current = 0



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
    elseif  rvalue_type == RValue.Type.INT32        then return tonumber(rvalue.i32)  -- Don't see any immediate consequences of doing this
    elseif  rvalue_type == RValue.Type.INT64        then return tonumber(rvalue.i64)
    elseif  rvalue_type == RValue.Type.BOOL         then return (rvalue.value ~= nil and rvalue.value ~= 0)
    elseif  rvalue_type == RValue.Type.REF          then return Instance.wrap(rvalue.i32)
    end

    return nil  -- Unset
end


-- Variant of Wrap.unwrap that places it into and returns an RValue
RValue.from_wrapper = function(value)
    -- Get correct RValue.Type
    local type_value = type(value)
    local rvalue_type = lua_type_lookup[type_value]
    if type_value == "table" and value.RAPI then
        rvalue_type = rvalue_type_lookup[value.RAPI]
        value = Proxy.get(value) or value.value
    end

    -- Get raw value and make an RValue from it
    return RValue.new(value, rvalue_type)
end


RValue.peek = function(rvalue)
    if type(rvalue) ~= "cdata" then return end

    local rvalue_type = rvalue.type
    local str = ""

    if      rvalue_type == RValue.Type.REAL         then str = "Value: "..tostring(rvalue.value)
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

    print("Type: "..RValue.Type[rvalue_type], str)
end


RValue.new = function(val, rvalue_type)
    rvalue_current = rvalue_current + 1
    if rvalue_current > #rvalue_cache then rvalue_current = 1 end

    local rvalue = rvalue_cache[rvalue_current]
    rvalue.type = 0
    rvalue.value = 0
    -- rvalue.__flags = 0

    -- Return RValue.Type.UNDEFINED if `val` is nil
    if val == nil then
        rvalue.type = RValue.Type.UNDEFINED
        rvalue.i64 = 0
        return rvalue
    end

    -- No RValue.Type specified; lua primitives
    if not rvalue_type then
        local type_val = type(val)
        if type_val == "number" then
            rvalue.value = val
            return rvalue
        elseif type_val == "string" then
            local rvalue = ffi.new("struct RValue[1]")
            gmf.yysetstring(rvalue, val)
            return rvalue[0]
        elseif type_val == "boolean" then
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
    end

	return rvalue
end


RValue.new_holder = function(new_size)
    if holder_size ~= new_size then
        holder_size = new_size
        holder = ffi.new("struct RValue["..new_size.."]")
    end
    return holder
end


RValue.new_holder_scr = function(new_size)
    if holder_size_scr ~= new_size then
        holder_size_scr = new_size
        holder_scr = ffi.new("struct RValue*["..new_size.."]")
    end
    return holder_scr
end


RValue.debug_get_current = function()
    return rvalue_current
end



_CLASS["RValue"] = RValue