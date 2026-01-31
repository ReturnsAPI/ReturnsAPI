-- AttackFlag

AttackFlag = new_class()

AttackFlag.CUSTOM_START = 32

run_once(function()
    __attack_flag_cache = FindCache.new()
    __attack_flag_counter = AttackFlag.CUSTOM_START - 1
end)



-- ========== Constants ==========

--@section Constants

--[[
The actual values used by the game are $2^n$ (i.e., bitwise).
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


--@constants
--[[
CUSTOM_START    32
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       number
--@param        identifier      | string    | The identifier for the attack flag.
--[[
Allocates a new attack flag value for the given identifier if it does not already exist,
or returns the existing one if it does.
]]
AttackFlag.new = function(NAMESPACE, identifier)
    -- Return existing flag if found
    local flag = AttackFlag.find(identifier, NAMESPACE, true)
    if flag then return flag end

    __attack_flag_counter = __attack_flag_counter + 1

    -- Add to cache
    __attack_flag_cache:set(
        __attack_flag_counter,
        identifier,
        NAMESPACE
    )

    return __attack_flag_counter
end


--@static
--@return       number
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified attack flag value and returns it.
If no namespace is provided, searches in your mod's namespace.
]]
AttackFlag.find = function(identifier, namespace, namespace_is_specified)
    -- Check in find table
    local cached = __attack_flag_cache:get(identifier, namespace, true)
    return cached
end



-- Public export
__class.AttackFlag = AttackFlag