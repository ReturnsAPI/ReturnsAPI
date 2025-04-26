-- AttackInfo

AttackInfo = new_class()



-- ========== Enums ==========

--@section Enums

--@enum
AttackInfo.Tracer = ReadOnly.new({
    NONE                    = 0,
    WISPG                   = 1,
    WISPG2                  = 2,
    PILOT_RAID              = 3,
    PILOT_RAID_BOOSTED      = 4,
    PILOT_PRIMARY           = 5,
    PILOT_PRIMARY_STRONG    = 6,
    PILOT_PRIMARY_ALT       = 7,
    COMMANDO1               = 8,
    COMMANDO2               = 9,
    COMMANDO3               = 10,
    COMMANDO3_R             = 11,
    SNIPER1                 = 12,
    SNIPER2                 = 13,
    ENGI_TURRET             = 14,
    ENFORCER1               = 15,
    ROBOMANDO1              = 16,
    ROBOMANDO2              = 17,
    BANDIT1                 = 18,
    BANDIT2                 = 19,
    BANDIT2_R               = 20,
    BANDIT3                 = 21,
    BANDIT3_R               = 22,
    ACRID                   = 23,
    NO_SPARKS_ON_MISS       = 24,
    END_SPARKS_ON_PIERCE    = 25,
    DRILL                   = 26,
    PLAYER_DRONE            = 27
})



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       AttackInfo
--@param        attack_info | Struct    | The `attack_info` struct to wrap.
--[[
Returns an AttackInfo wrapper containing the provided `attack_info` struct.
]]
AttackInfo.wrap = function(attack_info)
    return Proxy.new(Wrap.unwrap(attack_info), metatable_attackinfo)
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
    end

}



-- ========== Metatables ==========

make_table_once("metatable_attackinfo", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" or k == "yy_object_base" then return Proxy.get(proxy) end
        if k == "RAPI" then return getmetatable(proxy):sub(14, -1) end

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

    
    __metatable = "RAPI.Wrapper.AttackInfo"
})



__class.AttackInfo = AttackInfo