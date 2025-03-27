-- RValue

RValue = new_class()

if not __holder_struct then     -- Preserve on hotload
    __holder_struct = {}
    for i = 0, 16 do __holder_struct[i] = ffi.typeof("struct RValue["..i.."]") end
end

if not __holder_struct_scr then
    __holder_struct_scr = {}
    for i = 0, 16 do __holder_struct_scr[i] = ffi.typeof("struct RValue*["..i.."]") end
end

if not __rvalue_struct      then __rvalue_struct = ffi.typeof("struct RValue") end
if not __rvalue_struct_str  then __rvalue_struct_str = ffi.typeof("struct RValue[1]") end



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
        elseif  yyobjectbase.type == 3  then
            -- return rvalue.cscriptref

            -- return function(self, other, ...)
            --     return methods_GM.callso(ffi.string(rvalue.cscriptref.m_call_script.m_script_name):sub(12, -1))(self, other, ...)
            -- end

            local script_name = ffi.string(rvalue.cscriptref.m_call_script.m_script_name):sub(12, -1)

            return function(self, other, ...)
                local args = table.pack(...)
                local holder = RValue.new_holder_scr(args.n)

                -- Populate holder
                for i = 1, args.n do
                    holder[i - 1] = RValue.from_wrapper(args[i])
                end

                local out = RValue.new(0)
                gmf[script_name](ffi.cast("struct CInstance*", self), ffi.cast("struct CInstance*", other), out, args.n, holder)
                return RValue.to_wrapper(out)
            end
        end
        return Struct.wrap(rvalue)
    elseif  rvalue_type == RValue.Type.INT32        then return tonumber(rvalue.i32)  -- Don't see any immediate consequences of doing this
    elseif  rvalue_type == RValue.Type.INT64        then return tonumber(rvalue.i64)
    elseif  rvalue_type == RValue.Type.BOOL         then return (rvalue.value ~= nil and rvalue.value ~= 0)
    elseif  rvalue_type == RValue.Type.REF          then return Instance.wrap(rvalue.i32)
    end

    return nil  -- Unset
end


RValue.sol_to_wrapper = function(value)
    if type(value) == "userdata" then
        local rvalue
        local _type = getmetatable(value).__name
        if      _type == "sol.RefDynamicArrayOfRValue*" then rvalue = RValue.new(memory.get_usertype_pointer(value), RValue.Type.ARRAY)
        elseif  _type == "sol.YYObjectBase*"            then rvalue = RValue.new(ffi.cast("struct YYObjectBase*", memory.get_usertype_pointer(value)), RValue.Type.OBJECT)
        elseif  _type == "sol.CInstance*"               then rvalue = RValue.new(value.id, RValue.Type.REF)
        end
        return RValue.to_wrapper(rvalue)
    end
    return value
end


-- Variant of Wrap.unwrap that places it into and returns an RValue
RValue.from_wrapper = function(value)
    -- Get correct RValue.Type
    local _type, is_RAPI = Util.type(value, true)
    local _type_rvalue = rvalue_type_lookup[_type]
    if is_RAPI then value = Proxy.get(value) end

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
        local rvalue = ffi.new(__rvalue_struct)
        rvalue.type = RValue.Type.UNDEFINED
        rvalue.i64 = 0
        return rvalue
    end

    -- No RValue.Type specified; lua primitives
    if not rvalue_type then
        local type_val = type(val)
        if type_val == "number" then
            local rvalue = ffi.new(__rvalue_struct)
            rvalue.type = RValue.Type.REAL
            rvalue.value = val
            return rvalue
        elseif type_val == "string" then
            local rvalue = ffi.new(__rvalue_struct_str)
            gmf.yysetstring(rvalue, val)
            return rvalue[0]
        elseif type_val == "boolean" then
            local rvalue = ffi.new(__rvalue_struct)
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
        local rvalue = ffi.new(__rvalue_struct)
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
    -- return ffi.new("struct RValue["..size.."]")
    return ffi.new(__holder_struct[size])
end


RValue.new_holder_scr = function(size)
    -- return ffi.new("struct RValue*["..size.."]")
    return ffi.new(__holder_struct_scr[size])
end



__class.RValue = RValue