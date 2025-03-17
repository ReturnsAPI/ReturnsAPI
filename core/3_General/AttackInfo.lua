-- AttackInfo

AttackInfo = new_class()



-- ========== Static Methods ==========

AttackInfo.wrap = function(attack_info)
    return Proxy.new(attack_info, metatable_attackinfo)
end



-- ========== Instance Methods ==========

methods_attackinfo = {

    abc = function(self)
        
    end

}



-- ========== Metatables ==========

metatable_attackinfo = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(t) end
        if k == "RAPI" then return getmetatable(t):sub(14, -1) end

        -- Methods
        if methods_attackinfo[k] then
            return methods_attackinfo[k]
        end

        -- Getter
        return metatable_struct.__index(t, k)
    end,


    __newindex = function(t, k, v)
        -- Setter
        return metatable_struct.__newindex(t, k, v)
    end,

    
    __metatable = "RAPI.Wrapper.AttackInfo"
}



_CLASS["AttackInfo"] = AttackInfo