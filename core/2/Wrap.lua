-- Wrap

Wrap = {}



-- ========== Static Methods ==========

Wrap.wrap = function(value)
    -- TODO
end


Wrap.unwrap = function(value)
    if type(value) == "table" then return value.value end
    return value
end



return Wrap