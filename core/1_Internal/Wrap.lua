-- Wrap

Wrap = new_class()



-- ========== Static Methods ==========

Wrap.unwrap = function(value)
    local rvalue_type = nil
    if type(value) == "table" then
        if      value.RAPI == "Instance"    then rvalue_type = RValue.Type.REF
        end
    end
    return Proxy.get(value) or value, rvalue_type
end



_CLASS["Wrap"] = Wrap