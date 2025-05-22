-- Wrap

Wrap = new_class()



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       any
--@param        value       |           | The value to unwrap (if applicable).
--[[
Returns the unwrapped value of a RAPI wrapper,
or `value` if it is not a wrapper.
]]
Wrap.unwrap = function(value)
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

        -- Script
            
        end
    end

    return value
end



-- Public export
__class.Wrap = Wrap