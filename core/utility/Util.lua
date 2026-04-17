-- Util

---@class Util
Util = {}


-- ========== Static Methods ==========

--[[
Converts a numerical value into a bool,
returning `true` if > 0.5, and `false` otherwise.

Other cases:
Non-numerical, non-bool values will return `true`.
`nil` will return `false`.

Works just like [`GM.bool`](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Variable_Functions/bool.htm).
]]
---@param value any The value to convert.
---@return bool
Util.bool = function(value)
    if type(value) == "number" then return value > 0.5 end
    return (value and true) or false
end