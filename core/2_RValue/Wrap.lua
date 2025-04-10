-- Wrap

Wrap = new_class()



-- ========== Static Methods ==========

--$static
--$return       any
--$param        value       |           | The value to unwrap (if applicable).
--[[
Returns the unwrapped value of a RAPI wrapper,
or `value` if it is not a wrapper.
]]
Wrap.unwrap = function(value)
    return Proxy.get(value) or value
end



__class.Wrap = Wrap