-- Wrap

---@class Wrap
Wrap = new_class()
C.Wrap = Wrap

local proxy = P.proxy

local type         = type
local getmetatable = debug.getmetatable
local array_wrap    ---@type function
local struct_wrap   ---@type function
local instance_wrap ---@type function
local script_wrap   ---@type function

run_after_core(function()
    array_wrap    = Array.wrap
    struct_wrap   = Struct.wrap
    instance_wrap = Instance.wrap
    script_wrap   = Script.wrap
end)


-- ========== Static Methods ==========

--[[
Returns the unwrapped value of a RAPI wrapper, <br>
or `value` if it is not a wrapper.
]]
---@param value any The value to unwrap (if applicable).
---@return any
Wrap.unwrap = function(value)
    -- TODO For RAPI itself, inline this directly in build script(?)
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
        if     sol == "sol.RefDynamicArrayOfRValueLuaWrapper"
            or sol == "sol.RefDynamicArrayOfRValue*"          then return array_wrap    and array_wrap(value)    or Array.wrap(value)
        elseif sol == "sol.YYObjectBaseLuaWrapper"
            or sol == "sol.YYObjectBase*"                     then return struct_wrap   and struct_wrap(value)   or Struct.wrap(value)
        elseif sol == "sol.CInstance*"                        then return instance_wrap and instance_wrap(value) or Instance.wrap(value)
        elseif sol == "sol.CScriptRef*"                       then return script_wrap   and script_wrap(value)   or Script.wrap(value)
        end
    end
    return value
end