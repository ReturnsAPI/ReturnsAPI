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
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(t) end
        if k == "RAPI" then return getmetatable(t):sub(14, -1) end

        -- Methods
        if methods_hitinfo[k] then
            return methods_hitinfo[k]
        end

        -- Getter
        local ret = metatable_struct.__index(t, k)
        if k == "attack_info" then ret = AttackInfo.wrap(ret) end
        return ret
    end,


    __newindex = function(t, k, v)
        -- Setter
        return metatable_struct.__newindex(t, k, v)
    end,

    
    __metatable = "RAPI.Wrapper.HitInfo"
}



__class.HitInfo = HitInfo