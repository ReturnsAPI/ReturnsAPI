-- Draw

Draw = new_class()



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@param        x1          | number    | The left coordinate.
--@param        y1          | number    | The top coordinate.
--@param        x2          | number    | The right coordinate.
--@param        y2          | number    | The bottom coordinate.
--@optional     outline     | bool      | If `true`, the shape is drawn as an outline. <br>`false` by default.
--@optional     color       | color     | The color of the shape. <br>Uses the current draw color by default.
--[[
Draws a rectangle.
]]
Draw.rectangle = function(x1, y1, x2, y2, outline, color)
    -- Default color
    if not color then
        gm.draw_rectangle(x1, y1, x2, y2, outline or false)
        return
    end

    -- Specific color
    gm.draw_rectangle_color(x1, y1, x2, y2, color, color, color, color, outline or false)
end


--@static
--@param        x           | number    | The x coordinate of the center.
--@param        y           | number    | The y coordinate of the center.
--@param        r           | number    | The radius of the circle.
--@optional     outline     | bool      | If `true`, the shape is drawn as an outline. <br>`false` by default.
--@optional     color       | color     | The color of the shape. <br>Uses the current draw color by default.
--[[
Draws a circle.
]]
Draw.circle = function(x, y, r, outline, color)
    -- Default color
    if not color then
        gm.draw_circle(x, y, r, outline or false)
        return
    end

    -- Specific color
    gm.draw_circle_color(x, y, r, color, color, outline or false)
end


--@static
--@param        x1          | number    | The left coordinate.
--@param        y1          | number    | The top coordinate.
--@param        x2          | number    | The right coordinate.
--@param        y2          | number    | The bottom coordinate.
--@optional     outline     | bool      | If `true`, the shape is drawn as an outline. <br>`false` by default.
--@optional     color       | color     | The color of the shape. <br>Uses the current draw color by default.
--[[
Draws an ellipse.
]]
Draw.ellipse = function(x1, y1, x2, y2, outline, color)
    -- Default color
    if not color then
        gm.draw_ellipse(x1, y1, x2, y2, outline or false)
        return
    end

    -- Specific color
    gm.draw_ellipse_color(x1, y1, x2, y2, color, color, outline or false)
end


--@static
--@param        x1          | number    | The x coordinate of corner 1.
--@param        y1          | number    | The y coordinate of corner 1.
--@param        x2          | number    | The x coordinate of corner 2.
--@param        y2          | number    | The y coordinate of corner 2.
--@param        x3          | number    | The x coordinate of corner 3.
--@param        y3          | number    | The y coordinate of corner 3.
--@optional     outline     | bool      | If `true`, the shape is drawn as an outline. <br>`false` by default.
--@optional     color       | color     | The color of the shape. <br>Uses the current draw color by default.
--[[
Draws a triangle.
]]
Draw.triangle = function(x1, y1, x2, y2, x3, y3, outline, color)
    -- Default color
    if not color then
        gm.draw_triangle(x1, y1, x2, y2, x3, y3, outline or false)
        return
    end

    -- Specific color
    gm.draw_triangle_color(x1, y1, x2, y2, x3, y3, color, color, color, outline or false)
end


--@static
--@param        x1          | number    | The x coordinate of end 1.
--@param        y1          | number    | The y coordinate of end 1.
--@param        x2          | number    | The x coordinate of end 2.
--@param        y2          | number    | The y coordinate of end 2.
--@optional     width       | number    | The width of the line. <br>`1` by default.
--@optional     color       | color     | The color of the shape. <br>Uses the current draw color by default.
--[[
Draws a line.
]]
Draw.line = function(x1, y1, x2, y2, width, color)
    -- Default color
    if not color then
        gm.draw_line_width(x1, y1, x2, y2, width or 1)
        return
    end

    -- Specific color
    gm.draw_line_width_color(x1, y1, x2, y2, width or 1, color, color)
end


--@static
--@param        x           | number    | The x coordinate.
--@param        y           | number    | The y coordinate.
--@optional     color       | color     | The color of the shape. <br>Uses the current draw color by default.
--[[
Draws a single pixel.
]]
Draw.point = function(x, y, color)
    -- Default color
    if not color then
        gm.draw_point(x, y)
        return
    end

    -- Specific color
    gm.draw_point_color(x, y, color)
end


Draw.sprite = function()
    -- TODO
end


Draw.surface = function()
    -- TODO
end


Draw.text = function()
    -- TODO
    -- Also describe Scribble text formatting in description
end


--@static
--@return       color or nil
--@optional     color       | color     | The new draw color to set.
--[[
Returns the current draw color, or sets a new one.
]]
Draw.color = function(color)
    -- Get
    if not color then
        return gm.draw_get_color()
    end

    -- Set
    gm.draw_set_color(color)
end
Draw.colour = function(color) Draw.color(color) end


--@static
--@return       number or nil
--@optional     alpha       | number    | The new draw alpha to set.
--[[
Returns the current draw alpha, or sets a new one.
]]
Draw.alpha = function(alpha)
    -- Get
    if not alpha then
        return gm.draw_get_alpha()
    end

    -- Set
    gm.draw_set_alpha(alpha)
end


--@static
--@optional     prec        | number    | The new precision. <br>Must be *divisible by 4*, between `4` and `64`. <br>`24` by default.
--[[
Sets the circle precision (number of sides) for subsequently drawn circles.
]]
Draw.circle_precision = function(prec)
    gm.draw_set_circle_precision(prec or 24)
end



-- Public export
__class.Draw = Draw