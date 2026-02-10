-- Vector

-- This is a simple implementation for 2D vectors.
-- See usage here:  https://github.com/ReturnsAPI/ReturnsAPI/wiki/Vector

Vector = new_class()



-- ========== Instance Methods ==========

methods_vector = {

    normalize = function(self)
        local v = Vector(self)
        v.length = 1
        return v
    end,


    rotate = function(self, angle)
        local v = Vector(self)
        v.direction = v.direction + angle
        return v
    end

}



-- ========== Metatables ==========

local wrapper_name = "Vector"

make_table_once("metatable_vector_class", {
    __call = function(t, x, y)
        -- Clone
        if type(x) == "table" then
            return setmetatable({
                x = x.x,
                y = x.y
            }, metatable_vector)
        end

        if not (x and y) then log.error("Vector: Missing arguments", 2) end

        -- New
        return setmetatable({
            x = x,
            y = y
        }, metatable_vector)
    end,


    __index = function(t, k)
        -- Constants
        if k == "ZERO"  then return Vector( 0,  0)  end
        if k == "ONE"   then return Vector( 1,  1)  end
        if k == "LEFT"  then return Vector(-1,  0)  end
        if k == "RIGHT" then return Vector( 1,  0)  end
        if k == "UP"    then return Vector( 0, -1)  end
        if k == "DOWN"  then return Vector( 0,  1)  end
        if k == "HUGE"  then return Vector(math.huge, math.huge) end
    end,


    __metatable = "RAPI.Class."..wrapper_name
})
setmetatable(Vector, metatable_vector_class)


make_table_once("metatable_vector", {
    __index = function(vec, k)
        -- Get length/direction
        if k == "length"    then return math.sqrt(vec.x^2 + vec.y^2) end
        if k == "direction" then return (-math.atan(vec.y, vec.x) * Math.RAD2DEG) % 360 end
        if k == "RAPI"      then return wrapper_name end

        -- Methods
        return methods_vector[k]
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


    __mul = function(v1, v2)
        -- Scalar multiply
        if type(v1) == "number" then return Vector(v2.x * v1, v2.y * v1) end
        if type(v2) == "number" then return Vector(v1.x * v2, v1.y * v2) end

        -- Dot product
        return (v1.x * v2.x) + (v1.y * v2.y)
    end,


    __div = function(vec, value)
        -- Scalar divide
        if value == 0 then log.error("Vector division by 0", 2) end
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