-- Wrap

Wrap = new_class()



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       any
--@param        value           |       | The value to unwrap (if applicable).
--@optional     use_CInstance   | bool  | If `true`, Instance wrappers will return their `sol.CInstance*`. <br>`false` by default.
--[[
Returns the unwrapped value of a RAPI wrapper,
or `value` if it is not a wrapper.
]]
Wrap.unwrap = function(value, use_CInstance)
    if use_CInstance
    and type(value) == "table"
    and instance_wrappers[value.RAPI] then
        return value.CInstance
    end
    return __proxy[value] or value
end


--@static
--@return       any
--@param        value       |           | The value to wrap.
--[[
Wraps the value with the appropriate RAPI wrapper (if applicable).
]]
Wrap.wrap = function(value)
    if type(value) == "userdata" then
        local sol = getmetatable(value).__name

        -- Array
        if sol == "sol.RefDynamicArrayOfRValue*" then
            return Array.wrap(value)

        -- Instance
        elseif sol == "sol.CInstance*" then
            return Instance.wrap(value.id)

        -- Struct
        elseif sol == "sol.YYObjectBase*" then
            return Struct.wrap(value)

        -- Script
        elseif sol == "sol.CScriptRef*" then
            return Script.wrap(value)
            
        end
    end

    return value
end



-- Public export
__class.Wrap = Wrap