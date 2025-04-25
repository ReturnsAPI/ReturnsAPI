-- HitInfo

-- "Child" class of AttackInfo

HitInfo = new_class()

-- Cache for hitinfo.attack_info
local attackinfo_cache = setmetatable({}, {__mode = "k"})



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       HitInfo
--@param        hit_info    | Struct    | The `hit_info` struct to wrap.
--[[
Returns a HitInfo wrapper containing the provided `hit_info` struct.
]]
HitInfo.wrap = function(hit_info)
    return Proxy.new(Wrap.unwrap(hit_info), metatable_hitinfo)
end



-- ========== Instance Methods ==========

methods_hitinfo = {

    -- Will contain all of AttackInfo's methods but with
    -- the necessary modifications to HitInfo struct as well

    abc = function(self)
        
    end

}



-- ========== Metatables ==========

make_table_once("metatable_hitinfo", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" or k == "yy_object_base" then return Proxy.get(proxy) end
        if k == "RAPI" then return getmetatable(proxy):sub(14, -1) end
        if k == "attack_info" then
            -- Check cache
            local attackinfo = attackinfo_cache[proxy]
            if not attackinfo then
                attackinfo = AttackInfo.wrap(metatable_struct.__index(proxy, k))
                attackinfo_cache[proxy] = attackinfo
            end

            return attackinfo
        end

        -- Methods
        if methods_hitinfo[k] then
            return methods_hitinfo[k]
        end

        -- Pass to metatable_struct
        return metatable_struct.__index(proxy, k)
    end,


    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "yy_object_base"
        or k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Pass to metatable_struct
        return metatable_struct.__newindex(proxy, k, v)
    end,


    __len = function(proxy)
        return metatable_struct.__len(proxy)
    end,


    __pairs = function(proxy)
        return metatable_struct.__pairs(proxy)
    end,

    
    __metatable = "RAPI.Wrapper.HitInfo"
})



-- Public export
__class.HitInfo = HitInfo