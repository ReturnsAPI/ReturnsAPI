-- Wrap

Wrap = {}



-- ========== Static Methods ==========

Wrap.wrap = function(value)
    value = Wrap.unwrap(value)

    -- Array
    if select(2, type(value)) == "sol.RefDynamicArrayOfRValue*" then
        return Proxy.new(value, metatable_array)
    end

    -- Instance
    -- TODO
    -- if Instance.is(value) then
    --     return Instance.wrap(value)
    -- end

    return value
end


Wrap.unwrap = function(value)
    return Proxy.get(value) or value
end



return Wrap