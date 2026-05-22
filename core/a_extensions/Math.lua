-- Math

--[[
Extensions to Lua's `math`.
]]
---@class Math
Math = {}
C.Math = Math


-- ========== Constants ==========

Math.DEG2RAD = math.pi / 180    -- `math.pi` / `180` (approx. `0.01745329251`)
Math.RAD2DEG = 180 / math.pi    -- `180` / `math.pi` (approx. `57.2957795131`)


-- ========== Static Methods ==========

--[[
Returns a random float between `a` (inclusive) and `b` (exclusive).
]]
---@param a number The lower bound (inclusive).
---@param b number The upper bound (exclusive).
---@return number
Math.randomf = function(a, b)
    return a + ((b - a) * math.random())
end

--[[
Returns `n` rounded to the nearest integer.
]]
---@param n number The value to round.
---@return number
Math.round = function(n)
    return math.floor(n + 0.5)
end

---@alias sign -1 | 0 | 1
--[[
Returns the sign of the value.
]]
---@param n number The value to get the sign of.
---@return sign sign
Math.sign = function(n)
    return (n > 0 and 1) or (n < 0 and -1) or 0
end

--[[
Returns the cosine of the angle (in degrees).
]]
---@param angle number The angle (in degrees).
---@return number cosine
Math.dcos = function(angle)
    return math.cos(angle * Math.DEG2RAD)
end

--[[
Returns the sine of the angle (in degrees).
]]
---@param angle number The angle (in degrees).
---@return number sine
Math.dsin = function(angle)
    return math.sin(angle * Math.DEG2RAD)
end

--[[
Returns the distance between two points.
]]
---@param x1 number The x coordinate of point 1.
---@param y1 number The y coordinate of point 1.
---@param x2 number The x coordinate of point 2.
---@param y2 number The y coordinate of point 2.
---@return number distance
Math.distance = function(x1, y1, x2, y2)
    return math.sqrt( (x2 - x1)^2 + (y2 - y1)^2 )
end

--[[
Returns the angle (in degrees) to face point 2 from point 1.
]]
---@param x1 number The x coordinate of point 1.
---@param y1 number The y coordinate of point 1.
---@param x2 number The x coordinate of point 2.
---@param y2 number The y coordinate of point 2.
---@return number degrees
Math.direction = function(x1, y1, x2, y2)
    return (-math.atan(y2 - y1, x2 - x1) * Math.RAD2DEG) % 360
end

--[[
Clamps the given value between two boundaries.
]]
---@param n number The number to clamp.
---@param min number The minimum clamp value.
---@param max number The maximum clamp value.
---@return number
Math.clamp = function(n, _min, _max)
    return math.min(math.max(n, _min), _max)
end

--[[
Returns an ease-in value for a given value `x` between `0` and `1`.
]]
---@param x number The value to ease, between `0` and `1`.
---@param n? number The easing power. <br>`2` (quadratic) by default.
---@return number
Math.easein = function(x, n)
    return x^(n or 2)
end

--[[
Returns an ease-out value for a given value `x` between `0` and `1`.
]]
---@param x number The value to ease, between `0` and `1`.
---@param n? number The easing power. <br>`2` (quadratic) by default.
---@return number
Math.easeout = function(x, n)
    return 1 - (1 - x)^(n or 2)
end

--[[
Returns the value between `a` and `b` at percentage `x`.
]]
---@param a number The first value.
---@param b number The second value.
---@param x number The amount to interpolate, between `0` and `1`. <br>Values outside this range will extrapolate.
---@return number
Math.lerp = function(a, b, x)
    return a + ((b - a) * x)
end


-- Insert into ReturnAPI's `math`

math.DEG2RAD    = Math.DEG2RAD
math.RAD2DEG    = Math.RAD2DEG
math.randomf    = Math.randomf
math.round      = Math.round
math.sign       = Math.sign
math.dcos       = Math.dcos
math.dsin       = Math.dsin
math.distance   = Math.distance
math.direction  = Math.direction
math.clamp      = Math.clamp
math.easein     = Math.easein
math.easeout    = Math.easeout
math.lerp       = Math.lerp