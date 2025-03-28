-- Draw

Draw = new_class()



-- ========== Static Methods ==========

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



__class.Draw = Draw