-- RValue

RValue = new_class()


-- Typeof:
-- Seems to be faster to run ffi.new with predefined types
-- instead of passing "struct RValue", etc.
local holder_size_count = 12

if not __holder_struct then     -- Preserve on hotload
    __holder_struct = {}
    for i = 1, holder_size_count do __holder_struct[i] = ffi.typeof("struct RValue["..i.."]") end
end

if not __holder_struct_scr then
    __holder_struct_scr = {}
    for i = 1, holder_size_count do __holder_struct_scr[i] = ffi.typeof("struct RValue*["..i.."]") end
end

if not __rvalue_struct      then __rvalue_struct = ffi.typeof("struct RValue") end
if not __rvalue_struct_str  then __rvalue_struct_str = ffi.typeof("struct RValue[1]") end


-- Cache:
-- Fresh RValues and holders are created in bulk after
-- they run out, which allows for faster general use
local bulk_size = 100000

if not __holder_cache then
    __holder_cache = {}
    __holder_current = {}
    for size = 1, holder_size_count do
        __holder_cache[size] = {}
        __holder_current[size] = 0
        for i = 1, bulk_size do __holder_cache[size][i] = ffi.new(__holder_struct[size]) end
    end
end

if not __holder_cache_scr then
    __holder_cache_scr = {}
    __holder_current_scr = {}
    for size = 1, holder_size_count do
        __holder_cache_scr[size] = {}
        __holder_current_scr[size] = 0
        for i = 1, bulk_size do __holder_cache_scr[size][i] = ffi.new(__holder_struct_scr[size]) end
    end
end

if not __rvalue_cache then __rvalue_cache = {} end
for i = 1, bulk_size do __rvalue_cache[i] = ffi.new(__rvalue_struct) end
if not __rvalue_current then __rvalue_current = 0 end



-- ========== Enums ==========

--$enum
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


-- Internal lookup table for RValue.from_wrapper
local rvalue_type_lookup = {
    -- Lua primitives
    number      = RValue.Type.REAL,
    string      = RValue.Type.STRING,
    boolean     = RValue.Type.BOOL,

    -- Data Structures
    Array       = RValue.Type.ARRAY,
    Struct      = RValue.Type.OBJECT,
    
    -- GM
    Script      = RValue.Type.OBJECT,

    -- Instances
    Instance    = RValue.Type.REF,
    Actor       = RValue.Type.REF,
    Player      = RValue.Type.REF,
}



-- ========== Static Methods (Creation) ==========

--$static
--$return       RValue
--$param        value       |           | The value to wrap.
--$optional     rvalue_type | number    | The $`RValue.Type`, RValue#Type$ to wrap as. <br>Not required for Lua primitives.
--[[
Wraps a value as an RValue and returns it.
]]
RValue.new = function(val, rvalue_type)
    -- Retrieve fresh RValue from cache
    __rvalue_current = __rvalue_current + 1
    if __rvalue_current > #__rvalue_cache then
        __rvalue_current = 1

        -- Rebuild cache
        for i = 1, bulk_size do __rvalue_cache[i] = ffi.new(__rvalue_struct) end
    end
    local rvalue = __rvalue_cache[__rvalue_current]

    -- Return RValue.Type.UNDEFINED if `val` is nil
    if val == nil then
        rvalue.type = RValue.Type.UNDEFINED
        rvalue.i64 = 0
        return rvalue
    end

    -- No RValue.Type specified; Lua primitives
    if not rvalue_type then
        local type_val = type(val)
        if type_val == "number" then
            rvalue.type = RValue.Type.REAL
            rvalue.value = val
            return rvalue
        elseif type_val == "string" then
            local rvalue = ffi.new(__rvalue_struct_str)
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
        local rvalue = ffi.new(__rvalue_struct_str)
        gmf.yysetstring(rvalue, val)
        return rvalue[0]
    end
    
    -- Other RValue.Type
    if type(val) ~= "table" then
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
    log.error("RValue.new: table passed in, val = "..tostring(val)..", rvalue_type = "..tostring(rvalue_type), 2)
end


--$static
--$return       RValue[]
--$param        size        | number    | The size of the holder.
--[[
Returns a new RValue holder of the specified size (for builtin functions).
]]
RValue.new_holder = function(size)
    -- Retrieve fresh holder from cache
    __holder_current[size] = __holder_current[size] + 1
    if __holder_current[size] > #__holder_cache[size] then
        __holder_current[size] = 1

        -- Rebuild cache
        for i = 1, bulk_size do __holder_cache[size][i] = ffi.new(__holder_struct[size]) end
    end

    return __holder_cache[size][__holder_current[size]]
end


--$static
--$return       RValue*[]
--$param        size        | number    | The size of the holder.
--[[
Returns a new RValue* holder of the specified size (for script functions).
]]
RValue.new_holder_scr = function(size)
    -- Retrieve fresh holder from cache
    __holder_current_scr[size] = __holder_current_scr[size] + 1
    if __holder_current_scr[size] > #__holder_cache_scr[size] then
        __holder_current_scr[size] = 1

        -- Rebuild cache
        for i = 1, bulk_size do __holder_cache_scr[size][i] = ffi.new(__holder_struct_scr[size]) end
    end

    return __holder_cache_scr[size][__holder_current_scr[size]]
end


--$static
--$param        rvalue      | RValue    | The RValue to peek at.
--$optional     label       | string    | Prepend text to the print.
--[[
Prints the contents of an RValue.
]]
RValue.peek = function(rvalue, label)
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

    if label then
        print(label, "type: "..RValue.Type[rvalue_type], str, "__flags: "..tostring(rvalue.__flags))
        return
    end
    print("type: "..RValue.Type[rvalue_type], str, "__flags: "..tostring(rvalue.__flags))
end



-- ========== Static Methods (Conversions) ==========

--$static
--$return       RAPI wrapper or Lua primitive
--$param        rvalue      | RValue    | The RValue to convert.
--[[
Converts an RValue into the appropriate RAPI wrapper or Lua primitive.
]]
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
        if      yyobjectbase.type == 1  then return Instance.wrap(rvalue.cinstance.id)
        elseif  yyobjectbase.type == 3  then return Script.wrap(rvalue)
        end
        return Struct.wrap(rvalue)
    elseif  rvalue_type == RValue.Type.INT32        then return tonumber(rvalue.i32)  -- Don't see any immediate consequences of doing this
    elseif  rvalue_type == RValue.Type.INT64        then return tonumber(rvalue.i64)
    elseif  rvalue_type == RValue.Type.BOOL         then return (rvalue.value ~= nil and rvalue.value ~= 0)
    elseif  rvalue_type == RValue.Type.REF          then return Instance.wrap(rvalue.i32)
    end

    return nil  -- Unset
end


--$static
--$return       RValue
--$param        value       |           | The value to convert.
--[[
Converts a RAPI wrapper or Lua primitive into the appropriate RValue.
]]
RValue.from_wrapper = function(value)
    -- Get correct RValue.Type
    local _type, is_RAPI = Util.type(value, true)
    local _type_rvalue = rvalue_type_lookup[_type]
    if is_RAPI then value = Proxy.get(value) end

    -- Make an RValue
    return RValue.new(value, _type_rvalue)
end



__class.RValue = RValue