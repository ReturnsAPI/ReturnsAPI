-- HitInfo

--[[
HitInfo wrappers are "children" of @link {`Struct` | Struct} and @link {`AttackInfo` | AttackInfo}, and can use their properties and instance methods.
]]

HitInfo = new_class()

-- Cache for hit_info.attack_info
local attackinfo_cache = setmetatable({}, {__mode = "k"})



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         |           | The `sol.YYObjectBase*` being wrapped.
`RAPI`          | string    | The wrapper name.
`attack_info`   | AttackInfo | The attack_info struct of the HitInfo. <br>Comes automatically wrapped.
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       HitInfo
--@param        hit_info    | Struct    | The `hit_info` struct to wrap.
--[[
Returns a HitInfo wrapper containing the provided `hit_info` struct.
]]
HitInfo.wrap = function(hit_info)
    return make_proxy(Wrap.unwrap(hit_info), metatable_hitinfo)
end



-- ========== Instance Methods ==========

methods_hitinfo = {

    -- Will contain all of AttackInfo's methods but with
    -- the necessary modifications to HitInfo struct as well

    abc = function(self)
        
    end

}



-- ========== Metatables ==========

local wrapper_name = "HitInfo"

make_table_once("metatable_hitinfo", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return __proxy[proxy] end
        if k == "RAPI" then return wrapper_name end
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
        or k == "RAPI"
        or k == "attack_info" then
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

    
    __metatable = "RAPI.Wrapper."..wrapper_name
})



-- Public export
__class.HitInfo = HitInfo