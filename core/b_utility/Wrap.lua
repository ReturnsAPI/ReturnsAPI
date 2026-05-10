-- Wrap

---@class Wrap
Wrap = new_class()
C.Wrap = Wrap

local proxy = P.proxy

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
**[!] DEPRECATED**

Wraps the value with the appropriate RAPI wrapper (if applicable).
]]
---@deprecated
---@param value any The value to wrap.
---@return any
Wrap.wrap = function(value)
    return value
end