-- Wrap

Wrap = {}



-- ========== Static Methods ==========

Wrap.wrap = function(value)
    -- TODO
end


Wrap.unwrap = function(value)
    return Proxy.get(value) or value
end



return Wrap