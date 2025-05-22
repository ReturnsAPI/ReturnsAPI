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
    return Proxy.get(value) or value
end


--@static
--@return       any (`sol` value)
--@param        value       |           | The value to convert.
--[[
Returns a `sol` value from the given RAPI wrapper or Lua primitive.
]]
Wrap.unwrap_to_sol = function(value)
    -- Get RAPI type
    local _type = Util.type(value)
    local raw = Proxy.get(value) or value

    -- Return sol value
    if      _type == "Array"    then return memory.resolve_pointer_to_type(tonumber(raw), "RefDynamicArrayOfRValue*")
    elseif  _type == "Struct"   then return memory.resolve_pointer_to_type(raw, "YYObjectBase*")
    -- elseif  instance_wrappers[_type]    then return value.CInstance      -- Not needed since passing by ID works fine for gm functions
    end

    return raw
end



-- Public export
__class.Wrap = Wrap