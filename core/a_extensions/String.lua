-- String

--[[
Extensions to Lua's `string`.
]]
---@class String
String = {}
C.String = String

local tostring   = tostring
local string_rep = string.rep
local math_floor = math.floor


-- ========== Static Methods ==========

--[[
Returns a string with character padding on the <br>
*left* side to match the desired string length.
]]
---@param s string The string to pad.
---@param length integer The desired string length.
---@param char string The character to use. <br>`" "` (space) by default.
---@return string
String.pad_left = function(s, length, char)
    s = tostring(s)
    local n = length - #s
    if n <= 0 then return s end
    return string_rep(char or " ", n)..s
end

--[[
Returns a string with character padding on the <br>
*right* side to match the desired string length.
]]
---@param s string The string to pad.
---@param length integer The desired string length.
---@param char string The character to use. <br>`" "` (space) by default.
---@return string
String.pad_right = function(s, length, char)
    s = tostring(s)
    local n = length - #s
    if n <= 0 then return s end
    return s..string_rep(char or " ", length - #s)
end

--[[
Returns a string with character padding on the <br>
*left* side to match the desired *pixel width*. <br>
Width information is based on the current font.
]]
---@param s string The string to pad.
---@param width float The desired pixel width.
---@param char string The character to use. <br>`" "` (space) by default.
---@return string
String.pad_left_to_width = function(s, width, char)
    s = tostring(s)
    local str_w = gm.scribble_get_width(s)
    local diff  = width - str_w
    if diff <= 0 then return s end

    char = char or " "
    local char_w = gm.scribble_get_width(char)
    if char_w <= 0 then return s end

    local n = math_floor(diff / char_w)
    if n <= 0 then return s end
    return string_rep(char, n)..s
end

--[[
Returns a string with character padding on the <br>
*right* side to match the desired *pixel width*. <br>
Width information is based on the current font.
]]
---@param s string The string to pad.
---@param width float The desired pixel width.
---@param char string The character to use. <br>`" "` (space) by default.
---@return string
String.pad_right_to_width = function(s, width, char)
    s = tostring(s)
    local str_w = gm.scribble_get_width(s)
    local diff  = width - str_w
    if diff <= 0 then return s end

    char = char or " "
    local char_w = gm.scribble_get_width(char)
    if char_w <= 0 then return s end

    local n = math_floor(diff / char_w)
    if n <= 0 then return s end
    return s..string_rep(char, n)
end


-- Insert into ReturnAPI's `string`

string.pad_left             = String.pad_left
string.pad_right            = String.pad_right
string.pad_left_to_width    = String.pad_left_to_width
string.pad_right_to_width   = String.pad_right_to_width