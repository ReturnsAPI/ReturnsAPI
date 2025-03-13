-- Wrap

Wrap = new_class()



-- ========== Static Methods ==========

Wrap.unwrap = function(value)
    return Proxy.get(value) or value
end



_CLASS["Wrap"] = Wrap