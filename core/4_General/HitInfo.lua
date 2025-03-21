-- HitInfo

HitInfo = new_class()



-- ========== Static Methods ==========

HitInfo.wrap = function(hit_info)
    return Proxy.new(Wrap.unwrap(hit_info), metatable_hitinfo)
end



-- ========== Instance Methods ==========

methods_hitinfo = {

    abc = function(self)
        
    end

}



-- ========== Metatables ==========

metatable_hitinfo = {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(proxy) end
        if k == "RAPI" then return getmetatable(proxy):sub(14, -1) end

        -- Methods
        if methods_hitinfo[k] then
            return methods_hitinfo[k]
        end

        -- Getter
        local ret = metatable_struct.__index(proxy, k)
        if k == "attack_info" then ret = AttackInfo.wrap(ret) end
        return ret
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

    
    __metatable = "RAPI.Wrapper.HitInfo"
}



__class.HitInfo = HitInfo