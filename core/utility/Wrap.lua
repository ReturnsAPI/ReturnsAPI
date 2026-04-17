-- Wrap

---@class Wrap
Wrap = {}
C.Wrap = Wrap


-- ========== Static Methods ==========

--[[
Returns the unwrapped value of a RAPI wrapper, <br>
or `value` if it is not a wrapper.
]]
---@param value any The value to unwrap (if applicable).
---@return any
Wrap.unwrap = function(value)
    return Proxy.get(value) or value
end

--[[
Wraps the value with the appropriate RAPI wrapper (if applicable).
]]
---@param value any The value to wrap.
---@return any
Wrap.wrap = function(value)
    if type(value) == "userdata" then
        local sol = getmetatable(value).__name
        if     sol:find("sol.RefDynamicArrayOfRValue")  then return Array.wrap(value)
        elseif sol:find("sol.YYObjectBase")             then return Struct.wrap(value)
        elseif sol == "sol.CInstance*"                  then return Instance.wrap(value)
        elseif sol == "sol.CScriptRef*"                 then return Script.wrap(value)
        end
    end
    return value
end