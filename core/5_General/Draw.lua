-- Draw

Draw = new_class()



-- ========== Static Methods ==========

--$static
--$param        x1          | number    | The left coordinate.
--$param        y1          | number    | The top coordinate.
--$param        x2          | number    | The right coordinate.
--$param        y2          | number    | The bottom coordinate.
--$optional     outline     | bool      | If `true`, the shape is drawn as an outline. <br>`false` by default.
--$optional     color       | color     | The color of the shape. <br>Uses the current draw color by default.
--[[
Draws a rectangle.
]]
Draw.rectangle = function(x1, y1, x2, y2, outline, color)
    -- Default color
    if not color then
        local holder = RValue.new_holder(5)
        holder[0] = RValue.new(x1)
        holder[1] = RValue.new(y1)
        holder[2] = RValue.new(x2)
        holder[3] = RValue.new(y2)
        holder[4] = RValue.new(outline or false)
        gmf.draw_rectangle(RValue.new(0), nil, nil, 5, holder)
        return
    end

    -- Specific color
    local holder = RValue.new_holder(9)
    holder[0] = RValue.new(x1)
    holder[1] = RValue.new(y1)
    holder[2] = RValue.new(x2)
    holder[3] = RValue.new(y2)
    holder[4] = RValue.new(color)
    holder[5] = RValue.new(color)
    holder[6] = RValue.new(color)
    holder[7] = RValue.new(color)
    holder[8] = RValue.new(outline or false)
    gmf.draw_rectangle_color(RValue.new(0), nil, nil, 9, holder)
end


--$static
--$param        x           | number    | The x coordinate of the center.
--$param        y           | number    | The y coordinate of the center.
--$param        r           | number    | The radius of the circle.
--$optional     outline     | bool      | If `true`, the shape is drawn as an outline. <br>`false` by default.
--$optional     color       | color     | The color of the shape. <br>Uses the current draw color by default.
--[[
Draws a circle.
]]
Draw.circle = function(x, y, r, outline, color)
    -- Default color
    if not color then
        local holder = RValue.new_holder(4)
        holder[0] = RValue.new(x)
        holder[1] = RValue.new(y)
        holder[2] = RValue.new(r)
        holder[3] = RValue.new(outline or false)
        gmf.draw_circle(RValue.new(0), nil, nil, 4, holder)
        return
    end

    -- Specific color
    local holder = RValue.new_holder(6)
    holder[0] = RValue.new(x)
    holder[1] = RValue.new(y)
    holder[2] = RValue.new(r)
    holder[3] = RValue.new(color)
    holder[4] = RValue.new(color)
    holder[5] = RValue.new(outline or false)
    gmf.draw_circle_color(RValue.new(0), nil, nil, 6, holder)
end


--$static
--$param        x1          | number    | The left coordinate.
--$param        y1          | number    | The top coordinate.
--$param        x2          | number    | The right coordinate.
--$param        y2          | number    | The bottom coordinate.
--$optional     outline     | bool      | If `true`, the shape is drawn as an outline. <br>`false` by default.
--$optional     color       | color     | The color of the shape. <br>Uses the current draw color by default.
--[[
Draws an ellipse.
]]
Draw.ellipse = function(x1, y1, x2, y2, outline, color)
    -- Default color
    if not color then
        local holder = RValue.new_holder(5)
        holder[0] = RValue.new(x1)
        holder[1] = RValue.new(y1)
        holder[2] = RValue.new(x2)
        holder[3] = RValue.new(y2)
        holder[4] = RValue.new(outline or false)
        gmf.draw_ellipse(RValue.new(0), nil, nil, 5, holder)
        return
    end

    -- Specific color
    local holder = RValue.new_holder(7)
    holder[0] = RValue.new(x1)
    holder[1] = RValue.new(y1)
    holder[2] = RValue.new(x2)
    holder[3] = RValue.new(y2)
    holder[4] = RValue.new(color)
    holder[5] = RValue.new(color)
    holder[6] = RValue.new(outline or false)
    gmf.draw_ellipse_color(RValue.new(0), nil, nil, 7, holder)
end


--$static
--$param        x1          | number    | The x coordinate of corner 1.
--$param        y1          | number    | The y coordinate of corner 1.
--$param        x2          | number    | The x coordinate of corner 2.
--$param        y2          | number    | The y coordinate of corner 2.
--$param        x3          | number    | The x coordinate of corner 3.
--$param        y3          | number    | The y coordinate of corner 3.
--$optional     outline     | bool      | If `true`, the shape is drawn as an outline. <br>`false` by default.
--$optional     color       | color     | The color of the shape. <br>Uses the current draw color by default.
--[[
Draws a triangle.
]]
Draw.triangle = function(x1, y1, x2, y2, x3, y3, outline, color)
    -- Default color
    if not color then
        local holder = RValue.new_holder(7)
        holder[0] = RValue.new(x1)
        holder[1] = RValue.new(y1)
        holder[2] = RValue.new(x2)
        holder[3] = RValue.new(y2)
        holder[4] = RValue.new(x3)
        holder[5] = RValue.new(y3)
        holder[6] = RValue.new(outline or false)
        gmf.draw_triangle(RValue.new(0), nil, nil, 7, holder)
        return
    end

    -- Specific color
    local holder = RValue.new_holder(10)
    holder[0] = RValue.new(x1)
    holder[1] = RValue.new(y1)
    holder[2] = RValue.new(x2)
    holder[3] = RValue.new(y2)
    holder[4] = RValue.new(x3)
    holder[5] = RValue.new(y3)
    holder[6] = RValue.new(color)
    holder[7] = RValue.new(color)
    holder[8] = RValue.new(color)
    holder[9] = RValue.new(outline or false)
    gmf.draw_triangle_color(RValue.new(0), nil, nil, 10, holder)
end


--$static
--$param        x1          | number    | The x coordinate of end 1.
--$param        y1          | number    | The y coordinate of end 1.
--$param        x2          | number    | The x coordinate of end 2.
--$param        y2          | number    | The y coordinate of end 2.
--$optional     outline     | bool      | If `true`, the shape is drawn as an outline. <br>`false` by default.
--$optional     color       | color     | The color of the shape. <br>Uses the current draw color by default.
--[[
Draws a line.
]]
Draw.line = function(x1, y1, x2, y2, width, color)
    -- Default color
    if not color then
        local holder = RValue.new_holder(5)
        holder[0] = RValue.new(x1)
        holder[1] = RValue.new(y1)
        holder[2] = RValue.new(x2)
        holder[3] = RValue.new(y2)
        holder[4] = RValue.new(width or 1)
        gmf.draw_line(RValue.new(0), nil, nil, 5, holder)
        return
    end

    -- Specific color
    local holder = RValue.new_holder(7)
    holder[0] = RValue.new(x1)
    holder[1] = RValue.new(y1)
    holder[2] = RValue.new(x2)
    holder[3] = RValue.new(y2)
    holder[4] = RValue.new(color)
    holder[5] = RValue.new(color)
    holder[6] = RValue.new(width or 1)
    gmf.draw_line_color(RValue.new(0), nil, nil, 7, holder)
end


--$static
--$param        x           | number    | The x coordinate.
--$param        y           | number    | The y coordinate.
--$optional     color       | color     | The color of the shape. <br>Uses the current draw color by default.
--[[
Draws a single pixel.
]]
Draw.point = function(x, y, color)
    -- Default color
    if not color then
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(x)
        holder[1] = RValue.new(y)
        gmf.draw_point(RValue.new(0), nil, nil, 2, holder)
        return
    end

    -- Specific color
    local holder = RValue.new_holder(3)
    holder[0] = RValue.new(x)
    holder[1] = RValue.new(y)
    holder[2] = RValue.new(color)
    gmf.draw_point_color(RValue.new(0), nil, nil, 3, holder)
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


--$static
--$return       color or nil
--$optional     color       | color     | The new draw color to set.
--[[
Returns the current draw color, or sets a new one.
]]
Draw.color = function(color)
    -- Get
    if not color then
        local out = RValue.new(0)
        gmf.draw_get_color(out, nil, nil, 0, nil)
        return out.value
    end

    -- Set
    local holder = RValue.new_holder(1)
    holder[0] = RValue.new(color)
    gmf.draw_set_color(RValue.new(0), nil, nil, 1, holder)
end
Draw.colour = function(color) Draw.color(color) end


--$static
--$return       number or nil
--$optional     alpha       | number    | The new draw alpha to set.
--[[
Returns the current draw alpha, or sets a new one.
]]
Draw.alpha = function(alpha)
    -- Get
    if not alpha then
        local out = RValue.new(0)
        gmf.draw_get_alpha(out, nil, nil, 0, nil)
        return out.value
    end

    -- Set
    local holder = RValue.new_holder(1)
    holder[0] = RValue.new(alpha)
    gmf.draw_set_alpha(RValue.new(0), nil, nil, 1, holder)
end



-- Public export
__class.Draw = Draw