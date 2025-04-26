-- Math

--[[
Extensions of Lua `math` library.
These are automatically added to `math` on `.auto()` import.
]]

Math = new_class()



-- ========== Constants ==========

--@section Constants

--@constants
--[[
DEG2RAD     0.01745329251
RAD2DEG     57.2957795131
]]
Math.DEG2RAD = 0.01745329251
Math.RAD2DEG = 57.2957795131



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       number
--@param        a           | number    | The lower bound (inclusive).
--@param        b           | number    | The upper bound (exclusive).
--[[
Returns a random float between `a` (inclusive) and `b` (exclusive).
]]
Math.randomf = function(a, b)
    return a + (math.random() * (b - a))
end


--@static
--@return       number
--@param        n           | number    | The value to get the sign of.
--[[
Returns the sign of the value (either `1`, `-1`, or `0`).
]]
Math.sign = function(n)
    return (n > 0 and 1) or (n < 0 and -1) or 0
end


--@static
--@return       number
--@param        angle       | number    | The angle (in degrees).
--[[
Returns the cosine of the angle (in degrees).
]]
Math.dcos = function(angle)
    return math.cos(angle * Math.DEG2RAD)
end


--@static
--@return       number
--@param        angle       | number    | The angle (in degrees).
--[[
Returns the sine of the angle (in degrees).
]]
Math.dsin = function(angle)
    return math.sin(angle * Math.DEG2RAD)
end


--@static
--@return       number
--@param        n           | number    | The number to clamp.
--@param        min         | number    | The minimum clamp value.
--@param        max         | number    | The maximum clamp value.
--[[
Clamps the given value between two boundaries.
]]
Math.clamp = function(n, _min, _max)
    return math.min(math.max(n, _min), _max)
end