-- HitInfo

--[[
HitInfo wrappers are "children" of @link {`Struct` | Struct}, and can use its properties and wrapper methods. <br>
They also contain an @link {`AttackInfo` | AttackInfo}.
]]
---@class HitInfoClass
HitInfo = new_class()
C.HitInfo = HitInfo

local proxy = P.proxy
local metatable
local metatable_struct = W.Struct

local attackinfo_cache = setmetatable({}, {__mode = "k"})  ---@type table <HitInfo, AttackInfo> Cache for `.attack_info`

local new_proxy = new_proxy
local unwrap    = Wrap.unwrap


-- ========== Static Methods ==========

--[[
Returns a HitInfo wrapper containing the provided `hit_info` struct.
]]
---@param hit_info Struct The `hit_info` struct to wrap.
---@return HitInfo
HitInfo.wrap = function(hit_info)
    return new_proxy(unwrap(hit_info), metatable)
end


-- ========== Metatables ==========

---@class HitInfo
---@field value Struct The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field attack_info AttackInfo The `attack_info` struct of the HitInfo.

local mt_name = "HitInfo"

W.HitInfo = {
    ---@param t HitInfo
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return proxy[t] end
        if k == "RAPI" then return mt_name end
        if k == "attack_info" then
            local attackinfo = attackinfo_cache[t]
            if not attackinfo then
                attackinfo = AttackInfo.wrap(proxy[t][k])
                attackinfo_cache[t] = attackinfo
            end
            return attackinfo
        end

        -- Getter
        return proxy[t][k]
    end,

    __newindex = function(t, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI"
        or k == "attack_info" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        proxy[t][k] = v
    end,

    __len = function(t)
        return #proxy[t]
    end,

    __pairs = function(t)
        return metatable_struct.__pairs(t)
    end,

    __metatable = mt_wrapper_name(mt_name),
}
metatable = W.HitInfo