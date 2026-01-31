-- AttackInfo

--[[
AttackInfo wrappers are "children" of @link {`Struct` | Struct}, and can use its properties and instance methods.
]]

AttackInfo = new_class()



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         |           | *Read-only.* The `sol.YYObjectBase*` being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.
]]



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
        if not Instance.exists(parent) then log.error("use_raw_damage: parent does not exist", 2) end
        
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
    --@param        bool            | bool      | `true` - Crit <br>`false` - Non-crit
    --[[
    Sets whether or not this attack is a critical hit.
    
    *Technical:* Multiplies/divides `damage` by 2 alongside setting `critical`.
    ]]
    set_critical = function(self, bool, ignore_spotter)
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


    --@instance
    --@param        direction   | number    | The direction of knockback. <br>`-1` is left, and `1` is right. <br>Other values will stretch/compress the sprite horizontally.
    --@optional     duration    | number    | The duration of knockback (in frames). <br>`20` by default.
    --@optional     force       | number    | The force of knockback (in some unknown metric). <br>`3` by default.
    --@optional     kind        | number    | The @link {kind | Actor#KnockbackKind} of knockback. <br>`Actor.KnockbackKind.STANDARD` (`1`) by default.
    --[[
    Sets the knockback (stun) that is applied to hit actors.
    ]]
    set_knockback = function(self, direction, duration, force, kind)
        self.knockback_direction    = direction
        self.stun                   = (duration or 20) / (1.5 * 60)
        self.knockback              = force or 3
        self.knockback_kind         = kind  or Actor.KnockbackKind.STANDARD
    end,


    --@instance
    --@return       bool
    --@param        flag        | number    | The @link {flag | AttackFlag#Constants} to check.
    --[[
    Returns `true` if the attack flag is active, and `false` otherwise.
    ]]
    get_flag = function(self, flag)
        flag = Wrap.unwrap(flag)

        if flag <= AttackFlag.FORCE_PROC then
            return (self.attack_flags & (1 << flag)) > 0
        end

        if  flag >= AttackFlag.CUSTOM_START
        and flag <= __attack_flag_counter then
            local group = math.floor(flag / 32)
            local flag_group = self["attack_flags_group_"..group]
            if flag_group then
                return (flag_group & (1 << (flag % 32))) > 0
            end
        end

        return false
    end,


    --@instance
    --@param        flag        | number or table   | A @link {flag | AttackFlag#Constants} or table of flags to modify.
    --@param        state       | bool              | `true` - Enable flag(s) <br>`false` - Disable flag(s)
    --[[
    Sets the state of the specified attack flag(s).
    ]]
    set_flag = function(self, flag, state)
        if (type(flag) ~= "table") or flag.RAPI then flag = table.pack(flag) end
        if state == nil then log.error("set_flags: state argument not provided", 2) end

        local attack_flags_group_count
        local attack_flags_group = {}

        for _, fl in ipairs(flag) do
            fl = Wrap.unwrap(fl)

            -- Vanilla
            if fl <= AttackFlag.FORCE_PROC then
                fl = 1 << fl

                -- Toggle
                if ((self.attack_flags & fl) == 0) and state then
                    self.attack_flags = self.attack_flags + fl
                end
                if ((self.attack_flags & fl) > 0) and (not state) then
                    self.attack_flags = self.attack_flags - fl
                end

            -- Custom
            elseif fl >= AttackFlag.CUSTOM_START
               and fl <= __attack_flag_counter then
                local group = math.floor(fl / 32)
                local flag  = 1 << (fl % 32)
                
                -- Only access variables once per `set_flag` call
                -- and store locally to prevent unnecessary GM calls
                if not attack_flags_group_count then
                    attack_flags_group_count = self.attack_flags_group_count or 0
                end
                if not attack_flags_group[group] then
                    attack_flags_group[group] = self["attack_flags_group_"..group] or 0
                end
                
                -- Update highest group count
                attack_flags_group_count = math.max(attack_flags_group_count, group)

                -- Toggle
                if ((attack_flags_group[group] & flag) == 0) and state then
                    attack_flags_group[group] = attack_flags_group[group] + flag
                end
                if ((attack_flags_group[group] & flag) > 0) and (not state) then
                    attack_flags_group[group] = attack_flags_group[group] - flag
                end
            end
        end

        if attack_flags_group_count then
            self.attack_flags_group_count = attack_flags_group_count

            -- Set unintialized flag groups to 0
            for group = 1, attack_flags_group_count do
                self["attack_flags_group_"..group] = attack_flags_group[group] or 0
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



-- ========== Hooks ==========

-- Write custom attack flags
gm.post_script_hook(gm.constants.write_attackinfo, function(self, other, result, args)
    local info = args[1].value
    local count = info.attack_flags_group_count or 0
    
    gm.writebyte(count)

    if count > 0 then
        for group = 1, count do
            gm.writeuint(info["attack_flags_group_"..group])
        end
    end
end)


-- Read custom attack flags
gm.post_script_hook(gm.constants.read_attackinfo, function(self, other, result, args)
    local info = result.value
    local count = gm.readbyte()
    
    info.attack_flags_group_count = count

    if count > 0 then
        for group = 1, count do
            info["attack_flags_group_"..group] = gm.readuint()
        end
    end
end)



__class.AttackInfo = AttackInfo