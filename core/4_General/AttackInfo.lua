-- AttackInfo

AttackInfo = new_class()



-- ========== Static Methods ==========

AttackInfo.wrap = function(attack_info)
    return Proxy.new(Wrap.unwrap(attack_info), metatable_attackinfo)
end



-- ========== Instance Methods ==========

methods_attackinfo = {

    abc = function(self)
        
    end

}



-- ========== Metatables ==========

metatable_attackinfo = {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(proxy) end
        if k == "RAPI" then return getmetatable(proxy):sub(14, -1) end

        -- Methods
        if methods_attackinfo[k] then
            return methods_attackinfo[k]
        end

        -- Getter
        return metatable_struct.__index(proxy, k)
    end,


    __newindex = function(proxy, k, v)
        -- Setter
        return metatable_struct.__newindex(proxy, k, v)
    end,


    __len = function(proxy)
        return metatable_struct.__len(proxy)
    end,


    __pairs = function(proxy)
        return metatable_struct.__pairs(proxy)
    end,

    
    __metatable = "RAPI.Wrapper.AttackInfo"
}



__class.AttackInfo = AttackInfo