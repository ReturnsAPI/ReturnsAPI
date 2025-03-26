-- Wrap

Wrap = new_class()



-- ========== Static Methods ==========

Wrap.unwrap = function(value)
    return Proxy.get(value) or value
end


Wrap.unwrap_to_sol = function(value)
    local _type = Util.type(value)
    value = Proxy.get(value) or value

    if      _type == "Array"    then return memory.resolve_pointer_to_type(value, "RefDynamicArrayOfRValue*")
    elseif  _type == "Struct"   then return memory.resolve_pointer_to_type(value, "YYObjectBase*")
    elseif  _type == "Instance"
         or _type == "Actor"
         or _type == "Player"   then return memory.resolve_pointer_to_type(value, "CInstance*")
    end

    return value
end



__class.Wrap = Wrap