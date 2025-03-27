-- Graphics

Graphics = new_class()



-- ========== Static Methods ==========

Graphics.circle = function(x, y, r, outline)
    local holder = RValue.new_holder(4)
    holder[0] = RValue.new(x)
    holder[1] = RValue.new(y)
    holder[2] = RValue.new(r)
    holder[3] = RValue.new(outline or false)
    gmf.draw_circle(RValue.new(0), nil, nil, 4, holder)
end



__class.Graphics = Graphics