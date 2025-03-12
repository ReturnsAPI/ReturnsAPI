-- Wrap

Wrap = new_class()



-- ========== Static Methods ==========

-- May return an RValue.Type as a second value
-- Make sure this gets passed into RValue.new if using that; having them be on the same line works
Wrap.unwrap = function(value)
    local rvalue_type = nil
    if type(value) == "table" then
        if      value.RAPI == "Instance"    then rvalue_type = RValue.Type.REF
        end
    end
    return Proxy.get(value) or value, rvalue_type
end



_CLASS["Wrap"] = Wrap