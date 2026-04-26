-- Global

--[[
Allows for accessing global variables via `Global.<variable>`. <br>
Automatically wraps/unwraps on access.
]]
---@class Global
Global = new_class()
C.Global = Global

local g_get  = gm.variable_global_get   ---@type function
local g_set  = gm.variable_global_set   ---@type function
local wrap   = Wrap.wrap
local unwrap = Wrap.unwrap


-- ========== Metatables ==========

M.Global = {
    __index = function(t, k)
        return wrap(g_get(k))
    end,

    __newindex = function(t, k, v)
        g_set(k, unwrap(v))
    end,

    __metatable = mt_class_name("Global"),
}
setmetatable(Global, M.Global)