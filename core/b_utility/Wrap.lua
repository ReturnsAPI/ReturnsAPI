-- Wrap

---@class Wrap
Wrap = new_class()
C.Wrap = Wrap

local type = type
local getmetatable = getmetatable

local proxy = P.proxy
local array_wrap
local struct_wrap
local instance_wrap
local script_wrap

run_after_core(function()
    array_wrap    = Array.wrap
    struct_wrap   = Struct.wrap
    -- instance_wrap = Instance.wrap    -- TODO
    -- script_wrap   = Script.wrap
end)


-- ========== Static Methods ==========

--[[
Returns the unwrapped value of a RAPI wrapper, <br>
or `value` if it is not a wrapper.
]]
---@param value any The value to unwrap (if applicable).
---@return any
Wrap.unwrap = function(value)
    -- TODO For RAPI itself, inline this directly in build script
    return proxy[value] or value
end

--[[
Wraps the value with the appropriate RAPI wrapper (if applicable).
]]
---@param value any The value to wrap.
---@return any
Wrap.wrap = function(value)
    if type(value) == "userdata" then
        local sol = getmetatable(value).__name
        if     sol == "sol.RefDynamicArrayOfRValueLuaWrapper" then return array_wrap(value)
        elseif sol == "sol.YYObjectBaseLuaWrapper"            then return struct_wrap(value)
        -- elseif sol == "sol.CInstance*"                        then return instance_wrap(value)
        -- elseif sol == "sol.CScriptRef*"                       then return script_wrap(value)
        end
    end
    return value
end