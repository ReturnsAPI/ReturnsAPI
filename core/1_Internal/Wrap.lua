-- Wrap

Wrap = new_class()



-- ========== Static Methods ==========

Wrap.unwrap = function(value)
    return Proxy.get(value) or value
end



__class.Wrap = Wrap