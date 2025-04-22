-- Color

Color = new_class()



-- ========== Constants and Enums ==========

-- These are in BGR
--$constants
--[[
AQUA            0xffff00
BLACK           0x000000
BLUE            0xff0000
DKGRAY          0x404040
DKGREY          0x404040
FUCHSIA         0xff00ff
GRAY            0x808080
GREEN           0x008000
LIME            0x00ff00
LTGRAY          0xc0c0c0
LTGREY          0xc0c0c0
MAROON          0x000080
NAVY            0x800000
OLIVE           0x008080
ORANGE          0x40a0ff
PURPLE          0x800080
RED             0x0000ff
SILVER          0xc0c0c0
TEAL            0x808000
WHITE           0xffffff
YELLOW          0x00ffff
WHITE_ALMOST    0xfffffe
]]

local color_constants = {
    -- GameMaker in-built colors (in BGR)
    AQUA            = 0xffff00,
    BLACK           = 0x000000,
    BLUE            = 0xff0000,
    DKGRAY          = 0x404040,
    DKGREY          = 0x404040,
    FUCHSIA         = 0xff00ff,
    GRAY            = 0x808080,
    GREEN           = 0x008000,
    LIME            = 0x00ff00,
    LTGRAY          = 0xc0c0c0,
    LTGREY          = 0xc0c0c0,
    MAROON          = 0x000080,
    NAVY            = 0x800000,
    OLIVE           = 0x008080,
    ORANGE          = 0x40a0ff,
    PURPLE          = 0x800080,
    RED             = 0x0000ff,
    SILVER          = 0xc0c0c0,
    TEAL            = 0x808000,
    WHITE           = 0xffffff,
    YELLOW          = 0x00ffff,

    WHITE_ALMOST    = 0xfffffe
}

-- Add to Color directly (allowing for Color.WHITE, etc.)
for k, v in pairs(color_constants) do
    Color[k] = v
end


--$enum
Color.Item = ReadOnly.new({
    WHITE   = 0xffffff,
    GREEN   = 0x58b475,
    RED     = 0x3d27c9,
    YELLOW  = 0x41cdda,
    ORANGE  = 0x3566d9,
    PURPLE  = 0xc76aab,
    GRAY    = 0x555555,
    GREY    = 0x555555
})


--$enum
Color.Text = ReadOnly.new({
    YELLOW  = 0x7bd2ef,
    BLUE    = 0xd29a31,
    GREEN   = 0x86b67e,
    RED     = 0x6666cf,
    ORANGE  = 0x5673f9,
    LTGRAY  = 0xc0c0c0,
    LTGREY  = 0xc0c0c0,
    DKGRAY  = 0x808080,
    DKGREY  = 0x808080
})



-- ========== Internal ==========

local hex_symbols_l = "0123456789abcdef"
local hex_symbols_u = "0123456789ABCDEF"

-- `hex` is a string
Color.internal.hex2dec = function(hex)
    if type(hex) ~= "string" then log.error("hex2dec: hex must be a string", 2) end
    local sum = 0
    local place = 0
    for i = #hex, 1, -1 do
        local symbol = hex:sub(i, i)
        local value = hex_symbols_l:find(symbol) or hex_symbols_u:find(symbol)
        if not value then log.error("hex2dec: hex is invalid", 2) end
        value = (value - 1) * math.pow(16, place)
        sum = sum + value
        place = place + 1
    end
    return sum
end



-- ========== Static Methods ==========

--$static
--$return       number
--$param        hex         | string    | The hex string of the color (in RGB).
--[[
Returns a decimal color value from a hex string.
Can also be called via `Color(<hex>)`.
]]
Color.from_hex = function(hex)
    if (type(hex) ~= "string") or (#hex ~= 6) then log.error("Color.from_hex: hex must be a string of length 6", 2) end
    hex = hex:sub(5, 6)..hex:sub(3, 4)..hex:sub(1, 2)
    return Color.internal.hex2dec(hex)
end


-- Bitwise doesn't seem to exist here
-- so these will have to be rewritten


-- from rgb [0-255] to gamemaker
-- Color.from_rgb = function(r,g,b)
--     return b*0x10000+g*0x100+r
-- end


-- -- from lua hex to gamemaker (switch most significant bit)c
-- Color.from_hex = function(hex)
--     return (hex >> 16) | (hex & 0xff00) | ((hex % 0x100) << 16)
-- end


-- -- from gamemaker to rgb
-- Color.to_rgb = function(col)
--     return col & 0xff, (col & 0xff00) >> 8, col >> 16 --r, g, b
-- end


-- -- switch back MSB (same operation)
-- Color.to_hex = function(col)
--     return Color.from_hex(col)
-- end


-- -- Hue [0-360], Saturation [0-100], Value [0-100] -> r, g, b [0-255]
-- Color.hsv_to_rgb = function(h, s, v)
--     if h > 360 or h<0 or s<0 or s > 100 or v < 0 or v > 100 then 
--         log.error("Incorrect hsv values", 2)
--         return nil
--     end
--     local h = h/360
--     local s = s/100
--     local v = v/100
  
--     if s then
--         if h == 1.0 then h = 0.0 end
--         local i = math.floor(h*6.0)
--         local f = h*6.0 - i
        
--         local w = math.floor(255*(v * (1.0 - s)))
--         local q = math.floor(255*(v * (1.0 - s * f)))
--         local t = math.floor(255*(v * (1.0 - s * (1.0 - f))))
--         v = math.floor(255*v)
        
--         if i==0 then return v, t, w end
--         if i==1 then return q, v, w end
--         if i==2 then return w, v, t end
--         if i==3 then return w, q, v end
--         if i==4 then return t, w, v end
--         if i==5 then return v, w, q end
--     else 
--         v = math.floor(255*v)
--         return v, v, v
--     end
-- end


-- -- rgb [0-255] -> Hue [0-360], Saturation [0-100], Value [0-100]
-- Color.rgb_to_hsv = function(r, g, b)
--     if r < 0 or r > 255 or g < 0 or g > 255 or b < 0 or b > 255 then
--         log.error("Incorrect rgb values")
--         return nil
--     end
--     r = r/255
--     g = g/255
--     b = b/255
--     local Cmax = math.max(r,g,b)
--     local Cmin = math.min(r,g,b)
--     local Delta = Cmax-Cmin
    
--     -- Hue calculation
--     local h = nil
--     if Delta == 0 then h = 0 
--     elseif Cmax == r then h = 60*(((g-b)/Delta)%6) 
--     elseif Cmax == g then h = 60*((b-r)/Delta+2)
--     elseif Cmax == b then h = 60*((r-g)/Delta+4) 
--     end
--     -- Saturation calculation
--     local s = 0
--     if Cmax ~= 0 then
--         s = Delta/Cmax
--     end
--     -- Return h, s, v
--     return math.floor(h), math.floor(s*100), math.floor(Cmax*100)
-- end


-- Color.from_hsv = function(h, s, v)
--     return Color.from_rgb(Color.hsv_to_rgb(h,s,v))
-- end


-- Color.to_hsv = function(col)
--     return Color.rgb_to_hsv(Color.to_rgb(col))
-- end



-- ========== Metatables ==========

make_table_once("metatable_color", {
    __call = function(t, hex)
        return Color.from_hex(hex)
    end,


    __metatable = "RAPI.Class.Color"
})
setmetatable(Color, metatable_color)



-- Public export
__class.Color = Color
__class_mt.Color = metatable_color

__class.Colour = Color
__class_mt.Colour = metatable_color