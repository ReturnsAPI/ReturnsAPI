-- AttackFlag

---@class AttackFlagClass
AttackFlag = new_class()
C.AttackFlag = AttackFlag

run_on_initial_load(function()
    P.attack_flag_table = FindTable.new()
end)

local flag_table = P.attack_flag_table

local proxy = P.proxy
local metatable

local flag_constants = {}   ---@type table<number, string> Array table of vanilla flags (indexed from `1`).

local new_proxy = new_proxy
local unwrap    = Wrap.unwrap


-- ========== Constants ==========

-- The actual values used by the game are $2^n$ (i.e., bitwise).

AttackFlag.CD_RESET_ON_KILL         = 0
AttackFlag.INFLICT_POISON_DOT       = 1
AttackFlag.CHEF_IGNITE              = 2
AttackFlag.STUN_PROC_EF             = 3
AttackFlag.KNOCKBACK_PROC_EF        = 4 
AttackFlag.SPAWN_LIGHTNING          = 5
AttackFlag.SNIPER_BONUS_60          = 6
AttackFlag.SNIPER_BONUS_30          = 7
AttackFlag.HAND_STEAM_1             = 8
AttackFlag.HAND_STEAM_5             = 9
AttackFlag.DRIFTER_SCRAP_BIT1       = 10
AttackFlag.DRIFTER_SCRAP_BIT2       = 11
AttackFlag.DRIFTER_EXECUTE          = 12
AttackFlag.MINER_HEAT               = 13
AttackFlag.COMMANDO_WOUND           = 14
AttackFlag.COMMANDO_WOUND_DAMAGE    = 15
AttackFlag.GAIN_SKULL_ON_KILL       = 16
AttackFlag.GAIN_SKULL_BOOSTED       = 17
AttackFlag.CHEF_FREEZE              = 18
AttackFlag.CHEF_BIGFREEZE           = 19
AttackFlag.CHEF_FOOD                = 20
AttackFlag.INFLICT_ARMOR_STRIP      = 21
AttackFlag.INFLICT_FLAME_DOT        = 22
AttackFlag.MERC_AFTERIMAGE_NODAMAGE = 23
AttackFlag.PILOT_RAID               = 24
AttackFlag.PILOT_RAID_BOOSTED       = 25
AttackFlag.PILOT_MINE               = 26
AttackFlag.INFLICT_ARTI_FLAME_DOT   = 27
AttackFlag.SAWMERANG                = 28
AttackFlag.FORCE_PROC               = 29

-- Populate `flag_constants`
for name, flag in pairs(AttackFlag) do
    if type(flag) == "number" then
        flag_constants[flag + 1] = name
    end
end

AttackFlag.CUSTOM_START = 32

run_on_initial_load(function()
    P.attack_flag_counter = AttackFlag.CUSTOM_START - 1  -- Highest attack flag value *currently in use*; increment before taking.
end)


-- ========== Internal ==========

-- Called at the bottom of this file since it does wrapping
local function populate_find_table()
    -- Populate find table with vanilla attack flags
    for flag, name in ipairs(flag_constants) do
        local identifier = name:lower()

        -- Convert snake_case to camelCase
        while true do
            local pos = identifier:find("_")
            if not pos then break end
            identifier = identifier:sub(1, pos - 1)..identifier:sub(pos + 1, pos + 1):upper()..identifier:sub(pos + 2, -1)
        end

        flag_table:set(AttackFlag.wrap(flag), identifier, "ror", flag)
    end
end


-- ========== Static Methods ==========

--[[
Allocates a new attack flag value for the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the attack flag.
---@return AttackFlag
AttackFlag.new = function(NAMESPACE, identifier)
    -- Return existing flag if found
    local flag = AttackFlag.find(identifier, NAMESPACE, true)
    if flag then return flag end

    -- Get next usable ID
    P.attack_flag_counter = P.attack_flag_counter + 1

    local wrapper = AttackFlag.wrap(P.attack_flag_counter)
    flag_table:set(wrapper, identifier, NAMESPACE, P.attack_flag_counter)
    return wrapper
end

--[[
Searches for the specified attack flag value and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return AttackFlag
AttackFlag.find = function(identifier, namespace, namespace_is_specified)
    return flag_table:get(identifier, namespace, namespace_is_specified)
end

--[[
Returns a table of all attack flags in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param namespace? string The namespace to search in.
---@return table<number, AttackFlag>
AttackFlag.find_all = function(namespace, namespace_is_specified)
    return flag_table:get_all(namespace, namespace_is_specified)
end

--[[
Returns an AttackFlag wrapper containing the provided attack flag ID.
]]
---@param id number The attack flag ID to wrap.
---@return AttackFlag
AttackFlag.wrap = function(id)
    return new_proxy(unwrap(id), metatable)
end


-- ========== Metatables ==========

---@class AttackFlag
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field namespace string The namespace of the attack flag.
---@field identifier string The identifier of the attack flag.

local mt_name = "AttackFlag"

W.AttackFlag = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return proxy[t] end
        if k == "RAPI" then return mt_name end
        
        -- Getter
        return flag_table[proxy[t]][k]
    end,
    
    __newindex = function(t, k, v)
        log.error(mt_name.." has no properties to set", 2)
    end,

    __metatable = mt_wrapper_name(mt_name),
}
metatable = W.AttackFlag


populate_find_table()