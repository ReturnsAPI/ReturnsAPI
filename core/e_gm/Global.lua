-- Global

--[[
Allows for accessing global variables via `Global.<variable>`. <br>
Automatically wraps/unwraps on access.
]]
---@class Global
Global = new_class()
C.Global = Global

run_on_initial_load(function()
    ---@type number
    P.current_frame = gm.variable_global_get("_current_frame")
end)

local g_get  = gm.variable_global_get   ---@type function
local g_set  = gm.variable_global_set   ---@type function
local wrap   = Wrap.wrap
local unwrap = Wrap.unwrap


-- ========== Metatables ==========

---@class Global
---@field [string] any

M.Global = {
    __index = function(t, k)
        if k == "_current_frame" then return P.current_frame
        return g_get(k)
    end,

    __newindex = function(t, k, v)
        g_set(k, unwrap(v))
    end,

    __metatable = mt_class_name("Global"),
}
setmetatable(Global, M.Global)


-- ========== Hooks ==========

gm.post_code_execute("gml_Object_oInit_Step_1", function(self, other)
    -- `_current_frame` is updated in this event
    P.current_frame = g_get("_current_frame")
end)