-- AttackInfo

AttackInfo = new_class()



-- ========== Enums ==========

--@enum
AttackInfo.Flag = {
    CD_RESET_ON_KILL            = bit.lshift(1, 0),
    INFLICT_POISON_DOT          = bit.lshift(1, 1),
    CHEF_IGNITE                 = bit.lshift(1, 2),
    STUN_PROC_EF                = bit.lshift(1, 3),
    KNOCKBACK_PROC_EF           = bit.lshift(1, 4), 
    SPAWN_LIGHTNING             = bit.lshift(1, 5),
    SNIPER_BONUS_60             = bit.lshift(1, 6),
    SNIPER_BONUS_30             = bit.lshift(1, 7),
    HAND_STEAM_1                = bit.lshift(1, 8),
    HAND_STEAM_5                = bit.lshift(1, 9),
    DRIFTER_SCRAP_BIT1          = bit.lshift(1, 10),
    DRIFTER_SCRAP_BIT2          = bit.lshift(1, 11),
    DRIFTER_EXECUTE             = bit.lshift(1, 12),
    MINER_HEAT                  = bit.lshift(1, 13),
    COMMANDO_WOUND              = bit.lshift(1, 14),
    COMMANDO_WOUND_DAMAGE       = bit.lshift(1, 15),
    GAIN_SKULL_ON_KILL          = bit.lshift(1, 16),
    GAIN_SKULL_BOOSTED          = bit.lshift(1, 17),
    CHEF_FREEZE                 = bit.lshift(1, 18),
    CHEF_BIGFREEZE              = bit.lshift(1, 19),
    CHEF_FOOD                   = bit.lshift(1, 20),
    INFLICT_ARMOR_STRIP         = bit.lshift(1, 21),
    INFLICT_FLAME_DOT           = bit.lshift(1, 22),
    MERC_AFTERIMAGE_NODAMAGE    = bit.lshift(1, 23),
    PILOT_RAID                  = bit.lshift(1, 24),
    PILOT_RAID_BOOSTED          = bit.lshift(1, 25),
    PILOT_MINE                  = bit.lshift(1, 26),
    INFLICT_ARTI_FLAME_DOT      = bit.lshift(1, 27),
    SAWMERANG                   = bit.lshift(1, 28),
    FORCE_PROC                  = bit.lshift(1, 29)
}



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       AttackInfo
--@param        attack_info | Struct    | The `attack_info` struct to wrap.
--[[
Returns an AttackInfo wrapper containing the provided `attack_info` struct.
]]
AttackInfo.wrap = function(attack_info)
    -- Input:   struct or AttackInfo wrapper
    -- Wraps:   struct
    return make_proxy(Wrap.unwrap(attack_info), metatable_attackinfo)
end



-- ========== Instance Methods ==========

--@section Instance Methods

methods_attackinfo = {

    --@instance
    --[[
    If called, treats the attack's damage as a raw value,
    instead of having been multiplied as a damage coefficient.
    *Technical:* Divides `damage` by `parent.damage`.
    ]]
    use_raw_damage = function(self)
        local parent = self.parent
        if not Instance.exists(parent) then log.error("use_raw_damage: Parent does not exist", 2) end
        
        self.damage = math.ceil(self.damage / parent.damage)
    end,


    --@instance
    --@return       number
    --[[
    Returns the attack's damage *before* critical calculation.
    ]]
    get_damage_nocrit = function(self)
        if Util.bool(self.critical) then
            return math.ceil(self.damage / 2)
        end
        return self.damage
    end,


    --@instance
    --@param        damage      | number    | The damage to set.
    --[[
    Sets the damage of the attack *before* critical calculation.
    ]]
    set_damage = function(self, damage)
        if not damage then log.error("set_damage: Missing damage argument", 2) end
        
        if Util.bool(self.critical) then damage = damage * 2 end
        self.damage = math.ceil(damage)
    end,


    --@instance
    --@param        bool        | bool      | `true` - Crit <br>`false` - Non-crit
    --[[
    Sets whether or not this attack is a critical hit.
    *Technical:* Multiplies/divides `damage` by 2 alongside setting `critical`.
    ]]
    set_critical = function(self, bool)
        if bool == nil then log.error("set_critical: Missing bool argument", 2) end

        -- Enable crit
        if bool and (not Util.bool(self.critical)) then
            self.critical = true
            self.damage = self.damage * 2

        -- Disable crit
        elseif (not bool) and Util.bool(self.critical) then
            self.critical = false
            self.damage = math.ceil(self.damage / 2)

        end
    end,


    get_flag = function(self, flag)
        return bit.band(self.attack_flags, flag) > 0
    end,


    set_flag = function(self, flags, state)
        if type(flags) ~= "table" then flags = table.pack(flags) end
        if state == nil then log.error("set_flags: state argument not provided", 2) end

        for _, flag in ipairs(flags) do
            if bit.band(self.attack_flags, flag) == 0 and state then
                self.attack_flags = self.attack_flags + flag
            end
            if bit.band(self.attack_flags, flag) > 0 and (not state) then
                self.attack_flags = self.attack_flags - flag
            end
        end
    end

}



-- ========== Metatables ==========

local wrapper_name = "AttackInfo"

make_table_once("metatable_attackinfo", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return __proxy[proxy] end
        if k == "RAPI" then return wrapper_name end

        -- Methods
        if methods_attackinfo[k] then
            return methods_attackinfo[k]
        end

        -- Pass to metatable_struct
        return metatable_struct.__index(proxy, k)
    end,


    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
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

    
    __metatable = "RAPI.Wrapper."..wrapper_name
})



__class.AttackInfo = AttackInfo