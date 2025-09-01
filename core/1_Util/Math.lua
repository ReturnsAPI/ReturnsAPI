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
DEG2RAD     math.pi / 180 (approx. 0.01745329251)
RAD2DEG     180 / math.pi (approx. 57.2957795131)
]]
Math.DEG2RAD = math.pi / 180
Math.RAD2DEG = 180 / math.pi



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
--@param        x1          | number    | The x coordinate of point 1.
--@param        y1          | number    | The y coordinate of point 1.
--@param        x2          | number    | The x coordinate of point 2.
--@param        y2          | number    | The y coordinate of point 2.
--[[
Returns the distance between two points.
]]
Math.distance = function(x1, y1, x2, y2)
    return math.sqrt( (x2 - x1)^2 + (y2 - y1)^2 )
end


--@static
--@return       number
--@param        x1          | number    | The x coordinate of point 1.
--@param        y1          | number    | The y coordinate of point 1.
--@param        x2          | number    | The x coordinate of point 2.
--@param        y2          | number    | The y coordinate of point 2.
--[[
Returns the angle (in degrees) to face point 2 from point 1.
]]
Math.direction = function(x1, y1, x2, y2)
    return (-math.atan2(y2 - y1, x2 - x1) * Math.RAD2DEG) % 360
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


--@static
--@return       number
--@param        x           | number    | The value to ease, between `0` and `1`.
--@optional     n           | number    | The easing power. <br>`2` (quadratic) by default.
--[[
Returns an ease-in value for a given value `x` between `0` and `1`.
]]
Math.easein = function(x, n)
    return x^(n or 2)
end


--@static
--@return       number
--@param        x           | number    | The value to ease, between `0` and `1`.
--@optional     n           | number    | The easing power. <br>`2` (quadratic) by default.
--[[
Returns an ease-out value for a given value `x` between `0` and `1`.
]]
Math.easeout = function(x, n)
    return 1 - (1 - x)^(n or 2)
end



-- Public export
__class.Math = Math