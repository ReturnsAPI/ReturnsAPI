-- Internal

-- Utility functions for RAPI

function userdata_type(userdata)
    if type(userdata) ~= "userdata" then return end
    return getmetatable(userdata).__name
end


function new_class()
    return {
        internal = {}
    }
end


-- Taken from ReturnOfModding-DebugToolkit
-- Returns `true` as a second return value if the RValue is an Instance ID
function rvalue_to_lua(rvalue)
    local rvalue_type = rvalue.type
    if      rvalue_type == 0 then -- real
        return rvalue.value
    elseif  rvalue_type == 1 then -- string
        return rvalue.ref_string.m_str
    elseif  rvalue_type == 2 then -- array
        return rvalue.i64
    elseif  rvalue_type == 3 then -- ptr
        return rvalue.i64 
    elseif  rvalue_type == 5 then -- undefined
        return nil
    elseif  rvalue_type == 6 then -- object
        local yyobjectbase = rvalue.yy_object_base
        if yyobjectbase.type == 1 then
            return rvalue.cinstance 
        elseif yyobjectbase.type == 3 then
            return rvalue.cscriptref
        end
        return yyobjectbase
    elseif  rvalue_type == 7 then -- int32
        return rvalue.i32
    elseif  rvalue_type == 10 then -- int64
        return rvalue.i64
    elseif  rvalue_type == 13 then -- bool
        local rvalue_value = rvalue.value
        return rvalue_value ~= nil and rvalue_value ~= 0
    elseif  rvalue_type == 15 then -- ref (cinstance id)
        return rvalue.i32, true
    else                       -- unset
        return nil
    end
end