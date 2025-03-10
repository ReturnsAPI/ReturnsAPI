-- HitInfo

HitInfo = new_class()



-- ========== Static Methods ==========

HitInfo.wrap = function(hitinfo)
    return Proxy.new(hitinfo, metatable_hitinfo)
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
        return metatable_struct_getset.__index(t, k)
    end,


    __newindex = function(t, k, v)
        -- Setter
        return metatable_struct_getset.__newindex(t, k, v)
    end,

    
    __metatable = "RAPI.Wrapper.HitInfo"
}



_CLASS["HitInfo"] = HitInfo