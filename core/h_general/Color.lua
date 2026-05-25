-- Color

--[[
The GameMaker engine uses BGR colors.

Alias: `Colour`
]]
---@class Color
Color = new_class()
C.Color = Color
C.Colour = Color

local floor = math.floor
local max   = math.max
local min   = math.min


-- ========== Constants and Enums ==========

-- These are in BGR

Color.AQUA          = 0xffff00
Color.BLACK         = 0x000000
Color.BLUE          = 0xff0000
Color.DKGRAY        = 0x404040
Color.DKGREY        = 0x404040
Color.FUCHSIA       = 0xff00ff
Color.GRAY          = 0x808080
Color.GREEN         = 0x008000
Color.LIME          = 0x00ff00
Color.LTGRAY        = 0xc0c0c0
Color.LTGREY        = 0xc0c0c0
Color.MAROON        = 0x000080
Color.NAVY          = 0x800000
Color.OLIVE         = 0x008080
Color.ORANGE        = 0x40a0ff
Color.PURPLE        = 0x800080
Color.RED           = 0x0000ff
Color.SILVER        = 0xc0c0c0
Color.TEAL          = 0x808000
Color.WHITE         = 0xffffff
Color.YELLOW        = 0x00ffff

Color.WHITE_ALMOST  = 0xfffffe

Color.Item = {
    WHITE  = 0xffffff,
    GREEN  = 0x58b475,
    RED    = 0x3d27c9,
    YELLOW = 0x41cdda,
    ORANGE = 0x3566d9,
    PURPLE = 0xc76aab,
    GRAY   = 0x555555,
    GREY   = 0x555555,
}

Color.Text = {
    YELLOW = 0x7bd2ef,
    BLUE   = 0xd29a31,
    GREEN  = 0x86b67e,
    RED    = 0x6666cf,
    ORANGE = 0x5673f9,
    LTGRAY = 0xc0c0c0,
    LTGREY = 0xc0c0c0,
    DKGRAY = 0x808080,
    DKGREY = 0x808080,
}

Color.Console = {
    WHITE  = 0x9b938c, -- Input
    RED    = 0x3d33cc,
    GREEN  = 0x54ad48,
    BLUE   = 0xcc9b5f, -- Response
    PINK   = 0xb563af,
    PURPLE = 0xb55174,
    BLACK  = 0x564e4b,
}


-- ========== Static Methods ==========

--[[
Returns a BGR value from an RGB value.
Can also be called via `Color(<hex>)`.
]]
---@param hex number The hex value of the color (in RGB).
---@return number
Color.from_hex = function(hex)
    return (hex >> 16) | (hex & 0xff00) | ((hex % 0x100) << 16)
end

--[[
Returns an RGB value from a BGR value.
]]
---@param col number The value of the color (in BGR).
---@return number
Color.to_hex = function(col)
    return Color.from_hex(col)
end

--[[
Returns a BGR value from the specified (R, G, B) components.
]]
---@param r number The red component of the color (0 to 255).
---@param g number The green component of the color (0 to 255).
---@param b number The blue component of the color (0 to 255).
---@return number
Color.from_rgb = function(r, g, b)
    return b*0x10000 + g*0x100 + r
end

--[[
Returns the (R, G, B) components from a BGR value.
]]
---@param col number The value of the color (in BGR).
---@return number, number, number
Color.to_rgb = function(col)
    return col & 0xff, (col & 0xff00) >> 8, col >> 16 --r, g, b
end

--[[
Returns a BGR value from the specified (H, S, V) components.
]]
---@param h number The hue component of the color (0 to 360).
---@param s number The saturation component of the color (0 to 100).
---@param v number The value component of the color (0 to 100).
---@return number
Color.from_hsv = function(h, s, v)
    return Color.from_rgb(Color.hsv_to_rgb(h, s, v))
end

--[[
Returns the (H, S, V) components from a BGR value.
]]
---@param col number The value of the color (in BGR).
---@return number, number, number
Color.to_hsv = function(col)
    return Color.rgb_to_hsv(Color.to_rgb(col))
end

--[[
Returns (R, G, B) components from (H, S, V) components.
]]
---@param h number The hue component of the color (0 to 360).
---@param s number The saturation component of the color (0 to 100).
---@param v number The value component of the color (0 to 100).
---@return number, number, number
Color.hsv_to_rgb = function(h, s, v)
    -- Hue [0-360], Saturation [0-100], Value [0-100] -> r, g, b [0-255]

    if h > 360 or h < 0 or s < 0 or s > 100 or v < 0 or v > 100 then
        throw("Incorrect hsv values")
    end

    h = h / 360
    s = s / 100
    v = v / 100

    if s then
        if h == 1.0 then h = 0.0 end

        local i = floor(h * 6.0)
        local f = h * 6.0 - i

        local w = floor(255 * (v * (1.0 - s)))
        local q = floor(255 * (v * (1.0 - s * f)))
        local t = floor(255 * (v * (1.0 - s * (1.0 - f))))
        v = floor(255 * v)

        if i == 0 then return v, t, w end
        if i == 1 then return q, v, w end
        if i == 2 then return w, v, t end
        if i == 3 then return w, q, v end
        if i == 4 then return t, w, v end
        if i == 5 then return v, w, q end
    else
        v = floor(255 * v)
        return v, v, v
    end
end

--[[
Returns (H, S, V) components from (R, G, B) components.
]]
---@param r number The red component of the color (0 to 255).
---@param g number The green component of the color (0 to 255).
---@param b number The blue component of the color (0 to 255).
---@return number, number, number
Color.rgb_to_hsv = function(r, g, b)
    -- rgb [0-255] -> Hue [0-360], Saturation [0-100], Value [0-100]

    if r < 0 or r > 255 or g < 0 or g > 255 or b < 0 or b > 255 then
        throw("Incorrect rgb values")
    end

    r = r / 255
    g = g / 255
    b = b / 255

    local Cmax = max(r, g, b)
    local Cmin = min(r, g, b)
    local Delta = Cmax - Cmin

    -- Hue calculation
    local h = nil
    if Delta == 0 then
        h = 0
    elseif Cmax == r then
        h = 60 * (((g - b) / Delta) % 6)
    elseif Cmax == g then
        h = 60 * ((b - r) / Delta + 2)
    elseif Cmax == b then
        h = 60 * ((r - g) / Delta + 4)
    end

    -- Saturation calculation
    local s = 0
    if Cmax ~= 0 then
        s = Delta / Cmax
    end

    -- Return h, s, v
    return floor(h), floor(s * 100), floor(Cmax * 100)
end


--[[
---

### Notes from the original author ([@LoveBetween](https://github.com/LoveBetween))

All functions from and to hsv will not be exact because of the way it's calculated. Gamemaker has an implementation of hsv but it uses a `0 to 255` range for the Hue, Saturation, and Value fields which I didn't like.

Gamemaker colors are `24bit unsigned integers` (values from 0 to 16777216) with each portion of 8bits (0 to 255) respectively coding the the Blue, Green and Red components of the color.

All of these functions are defined entirely in lua, with the purpose of reducing the number of gm calls (and also it was fun).
]]


-- ========== Metatables ==========

local mt_name = "Color"

M.Color = {
    __call = function(_, hex)
        return Color.from_hex(hex)
    end,

    __metatable = mt_class_name(mt_name),
}
setmetatable(Color, M.Color)