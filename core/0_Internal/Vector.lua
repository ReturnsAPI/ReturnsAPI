-- Vector

--[[
This is a simple implementation for 2D vectors.

```lua
-- Some operations may not be exact due to floating-point errors.

-- New
local v1 = Vector()         -- <0, 0>
local v2 = Vector(1, 1)     -- <1, 1>

-- Clone
local v3 = Vector(v2)       -- <1, 1>

-- Length and direction
print(v3.length)            -- 1
print(v3.direction)         -- -45
v3.length = 1               -- <0.70710678118655, 0.70710678118655>
v3.direction = 180          -- <-1, 0>

-- Operations
local v4 = Vector(1, 2)
local v5 = Vector(3, 4)
print(v4 == v5)             -- false
print(v4 + v5)              -- <4, 6>
print(v4 - v5)              -- <-2, -2>
print(v4 * v5)              -- 11  (dot product)

-- Scalar operations
print(v4 * 2)               -- <2, 4>
print(v4 / 2)               -- <0.5, 1>

-- Negation
print(-v4)                  -- <-1, -2>
```
]]

Vector = new_class()



-- ========== Metatables ==========

local wrapper_name = "Vector"

make_table_once("metatable_vector_class", {
    __call = function(t, x, y)
        -- Clone
        if type(x) == "table" then
            return setmetatable({
                x = x.x,
                y = x.y,
            }, metatable_vector)
        end

        -- New
        return setmetatable({
            x = x or 0,
            y = y or 0
        }, metatable_vector)
    end,


    __metatable = "RAPI.Class."..wrapper_name
})
setmetatable(Vector, metatable_vector_class)


make_table_once("metatable_vector", {
    __index = function(vec, k)
        -- Get length/direction
        if k == "length"    then return  math.sqrt(vec.x^2, vec.y^2)                end
        if k == "direction" then return -math.atan2(vec.y, vec.x) * Math.RAD2DEG    end
        if k == "RAPI"      then return wrapper_name end
    end,


    __newindex = function(vec, k, v)
        -- Set length
        if k == "length" then
            local length = math.sqrt(vec.x^2 + vec.y^2)
            if length == 0 then return end
            local scale = v / length
            vec.x = vec.x * scale
            vec.y = vec.y * scale
            return
        end

        -- Set direction
        if k == "direction" then
            local length = math.sqrt(vec.x^2 + vec.y^2)
            vec.x =  math.cos(v * Math.DEG2RAD) * length
            vec.y = -math.sin(v * Math.DEG2RAD) * length
            return
        end
    end,
    
    
    __len = function(vec)
        -- Get length
        return math.sqrt(vec.x^2, vec.y^2)
    end,


    __eq = function(v1, v2)
        -- Check equivalence
        return (v1.x == v2.x) and (v1.y == v2.y)
    end,


    __add = function(v1, v2)
        -- Add
        return Vector(v1.x + v2.x, v1.y + v2.y)
    end,


    __sub = function(v1, v2)
        -- Subtract
        return Vector(v1.x - v2.x, v1.y - v2.y)
    end,


    __mul = function(vec, value)
        -- Dot product
        if type(value) == "table" then return (vec.x * value.x) + (vec.y * value.y) end

        -- Scalar multiply
        return Vector(vec.x * value, vec.y * value)
    end,


    __div = function(vec, value)
        -- Scalar divide
        return Vector(vec.x / value, vec.y / value)
    end,


    __unm = function(vec)
        -- Negate
        return Vector(-vec.x, -vec.y)
    end,


    __tostring = function(vec)
        return "<"..vec.x..", "..vec.y..">"
    end,


    __metatable = "RAPI.Wrapper."..wrapper_name
})



-- Public export
__class.Vector = Vector
__class_mt.Vector = metatable_vector_class