-- AttackFlag

AttackFlag = new_class()

run_once(function()
    __attack_flag_find_table = {}
    __attack_flag_current_id = 30
    __attack_flag_funcs = {}
end)



-- ========== Constants ==========

--@section Constants

--[[
The actual values used in-game are $2^n$ (i.e., bitwise).
]]

--@constants
--[[
CD_RESET_ON_KILL            0
INFLICT_POISON_DOT          1
CHEF_IGNITE                 2
STUN_PROC_EF                3
KNOCKBACK_PROC_EF           4 
SPAWN_LIGHTNING             5
SNIPER_BONUS_60             6
SNIPER_BONUS_30             7
HAND_STEAM_1                8
HAND_STEAM_5                9
DRIFTER_SCRAP_BIT1          10
DRIFTER_SCRAP_BIT2          11
DRIFTER_EXECUTE             12
MINER_HEAT                  13
COMMANDO_WOUND              14
COMMANDO_WOUND_DAMAGE       15
GAIN_SKULL_ON_KILL          16
GAIN_SKULL_BOOSTED          17
CHEF_FREEZE                 18
CHEF_BIGFREEZE              19
CHEF_FOOD                   20
INFLICT_ARMOR_STRIP         21
INFLICT_FLAME_DOT           22
MERC_AFTERIMAGE_NODAMAGE    23
PILOT_RAID                  24
PILOT_RAID_BOOSTED          25
PILOT_MINE                  26
INFLICT_ARTI_FLAME_DOT      27
SAWMERANG                   28
FORCE_PROC                  29
]]

local flag_constants = {
    CD_RESET_ON_KILL            = 0,
    INFLICT_POISON_DOT          = 1,
    CHEF_IGNITE                 = 2,
    STUN_PROC_EF                = 3,
    KNOCKBACK_PROC_EF           = 4, 
    SPAWN_LIGHTNING             = 5,
    SNIPER_BONUS_60             = 6,
    SNIPER_BONUS_30             = 7,
    HAND_STEAM_1                = 8,
    HAND_STEAM_5                = 9,
    DRIFTER_SCRAP_BIT1          = 10,
    DRIFTER_SCRAP_BIT2          = 11,
    DRIFTER_EXECUTE             = 12,
    MINER_HEAT                  = 13,
    COMMANDO_WOUND              = 14,
    COMMANDO_WOUND_DAMAGE       = 15,
    GAIN_SKULL_ON_KILL          = 16,
    GAIN_SKULL_BOOSTED          = 17,
    CHEF_FREEZE                 = 18,
    CHEF_BIGFREEZE              = 19,
    CHEF_FOOD                   = 20,
    INFLICT_ARMOR_STRIP         = 21,
    INFLICT_FLAME_DOT           = 22,
    MERC_AFTERIMAGE_NODAMAGE    = 23,
    PILOT_RAID                  = 24,
    PILOT_RAID_BOOSTED          = 25,
    PILOT_MINE                  = 26,
    INFLICT_ARTI_FLAME_DOT      = 27,
    SAWMERANG                   = 28,
    FORCE_PROC                  = 29,
}

-- Add to AttackFlag directly (e.g., AttackFlag.MINER_HEAT)
for k, v in pairs(flag_constants) do
    AttackFlag[k] = v
end



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return   AttackFlag
--@param    identifier      | string    | The identifier for the attack flag.
--[[
Creates a new attack flag with the given identifier if it does not already exist,
or returns the existing one if it does.
]]
AttackFlag.new = function(namespace, identifier)
    local flag = AttackFlag.find(identifier, namespace)
    if flag then return flag end

    local proxy = AttackFlag.wrap(__attack_flag_current_id, metatable_attack_flag)

    -- Add to find table
    __attack_flag_find_table[namespace] = __attack_flag_find_table[namespace] or {}
    __attack_flag_find_table[namespace][identifier] = proxy

    __attack_flag_current_id = __attack_flag_current_id + 1

    return proxy
end


--@static
--@return       AttackFlag or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified attack flag and returns it.
If no namespace is provided, searches in your mod's namespace.
]]
AttackFlag.find = function(identifier, namespace, default_namespace)
    local namespace, is_specified = parse_optional_namespace(namespace, default_namespace)

    -- Search in namespace
    local namespace_table = __attack_flag_find_table[namespace]
    if namespace_table then return namespace_table[identifier] end

    return nil
end


--@static
--@return       AttackFlag
--@param        flag        | number    | The attack flag to wrap.
--[[
Returns an AttackFlag wrapper containing the provided attack flag.
]]
AttackFlag.wrap = function(flag)
    -- Input:   number or AttackFlag wrapper
    -- Wraps:   number
    return make_proxy(Wrap.unwrap(flag), metatable_attack_flag)
end



-- ========== Instance Methods ==========

--@section Instance Methods

methods_attack_flag = {

    --@instance
    --@param        func        | function  | The function to set. <br>The parameters for it are `hit_info`.
    --[[
    Sets the function that gets called whenever the attack flag is used.
    
    The function is only called for the host.
    ]]
    set_func = function(self, func)
        __attack_flag_funcs[self.value] = func
    end

}



-- ========== Metatables ==========

local wrapper_name = "AttackFlag"

make_table_once("metatable_attack_flag", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return __proxy[proxy] end
        if k == "RAPI" then return wrapper_name end

        -- Methods
        if methods_attack_flag[k] then
            return methods_attack_flag[k]
        end

        log.error("AttackFlag has no properties to get", 2)
    end,


    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        log.error("AttackFlag has no properties to set", 2)
    end,

    __metatable = "RAPI.Wrapper."..wrapper_name
})



-- ========== Hooks ==========

Callback.add(_ENV["!guid"], Callback.ON_ATTACK_HIT, function(hit_info)
    if not hit_info then return end
    local attack_info = hit_info.attack_info

    -- Call custom attack flag functions
    local keys = attack_info:get_keys()
    for _, k in ipairs(keys) do
        if k:match("RAPI_attack_flag_") then
            __attack_flag_funcs[tonumber(k:sub(18, -1))](hit_info)
        end
    end
end)



-- Public export
__class.AttackFlag = AttackFlag