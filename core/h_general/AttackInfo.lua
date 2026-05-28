-- AttackInfo

---@class AttackInfoClass
AttackInfo = new_class()
C.AttackInfo = AttackInfo

local proxy = P.proxy
local metatable
local metatable_struct = W.Struct

local type      = type
local ceil      = math.ceil
local floor     = math.floor
local max       = math.max
local new_proxy = new_proxy
local to_bool   = Util.bool
local unwrap    = Wrap.unwrap

local kb_standard = Actor.KnockbackKind.STANDARD


-- ========== Static Methods ==========

--[[
Returns an AttackInfo wrapper containing the provided `attack_info` struct.
]]
---@param attack_info Struct The `attack_info` struct to wrap.
---@return AttackInfo
AttackInfo.wrap = function(attack_info)
    return new_proxy(unwrap(attack_info), metatable)
end


-- ========== Wrapper Methods ==========

---@class AttackInfo
local methods = {}

--[[
If called, treats the attack's damage as a raw value, <br>
instead of having been multiplied as a damage coefficient.

*Technical:* Divides `damage` by `parent.damage`.
]]
methods.use_raw_damage = function(self)
    local parent = self.parent
    if not Instance.exists(parent) then throw("parent does not exist") end
    
    local p_damage = parent.damage
    self.damage = (p_damage > 0 and ceil(self.damage / p_damage)) or 0
end

--[[
Returns the attack's damage *before* critical calculation.
]]
---@return number
methods.get_damage_nocrit = function(self)
    if to_bool(self.critical) then
        return ceil(self.damage / 2)
    end
    return self.damage
end

--[[
Sets the damage of the attack *before* critical calculation.
]]
---@param damage number The damage to set.
methods.set_damage = function(self, damage)
    if not damage then throw("Missing damage argument") end
    
    if to_bool(self.critical) then damage = damage * 2 end
    self.damage = math.ceil(damage)
end

--[[
Sets whether or not this attack is a critical hit.

*Technical:* Multiplies/divides `damage` by 2 alongside setting `critical`.
]]
---@param bool boolean `true` - Crit <br>`false` - Non-crit
methods.set_critical = function(self, bool, ignore_spotter)
    if bool == nil then throw("Missing bool argument") end

    -- Enable crit
    if bool and (not to_bool(self.critical)) then
        self.critical = true
        self.damage = self.damage * 2

    -- Disable crit
    elseif (not bool) and to_bool(self.critical) then
        self.critical = false
        self.damage = math.ceil(self.damage / 2)
    end
end

--[[
Sets the knockback (stun) that is applied to hit actors.
]]
---@param direction number The direction of knockback. <br>`-1` is left, and `1` is right. <br>Other values will stretch/compress the sprite horizontally.
---@param duration? number The duration of knockback (in frames). <br>`20` by default.
---@param force? number The force of knockback (in some unknown metric). <br>`3` by default.
---@param kind? number The @link {kind | Actor#KnockbackKind} of knockback. <br>`Actor.KnockbackKind.STANDARD` (`1`) by default.
methods.set_knockback = function(self, direction, duration, force, kind)
    self.knockback_direction = direction
    self.stun                = (duration or 20) / (1.5 * 60)
    self.knockback           = force or 3
    self.knockback_kind      = kind  or kb_standard
end

--[[
Returns `true` if the attack flag is active, and `false` otherwise.
]]
---@param flag number The @link {flag | AttackFlag#Constants} to check.
---@return boolean
methods.get_flag = function(self, flag)
    flag = unwrap(flag)

    if flag <= AttackFlag.FORCE_PROC then
        return (self.attack_flags & (1 << flag)) > 0
    end

    if  flag >= AttackFlag.CUSTOM_START
    and flag <= __attack_flag_counter then
        local group = floor(flag / 32)
        local flag_group = self["attack_flags_group_"..group]
        if flag_group then
            return (flag_group & (1 << (flag % 32))) > 0
        end
    end

    return false
end

--[[
Sets the state of the specified attack flag(s).
]]
---@param flag number | table A @link {flag | AttackFlag#Constants} or table of flags to modify.
---@param state boolean `true` - Enable flag(s) <br>`false` - Disable flag(s)
methods.set_flag = function(self, flag, state)
    if type(flag) ~= "table" or flag.RAPI then flag = {flag} end
    if state == nil then throw("state argument not provided") end

    local attack_flags_group_count  ---@type number The number of attack flag groups present.
    local attack_flags_group = {}   ---@type table<number, number> Array table of u32s (groups).

    for _, fl in ipairs(flag) do
        fl = unwrap(fl)  ---@type number

        -- Vanilla
        if fl <= AttackFlag.FORCE_PROC then
            fl = 1 << fl

            -- Toggle
            local flags = self.attack_flags
            if ((flags & fl) == 0) and state then
                self.attack_flags = flags + fl
            elseif ((flags & fl) > 0) and (not state) then
                self.attack_flags = flags - fl
            end

        -- Custom
        elseif fl >= AttackFlag.CUSTOM_START
           and fl <= P.attack_flag_counter then

            -- Since the original `attack_flags` is a u32,
            -- flags over 2^31 need to be stored in new integers

            local group = floor(fl / 32)  -- The u32 (group) this flag is in
            local flag  = 1 << (fl % 32)  ---@type number Position within the u32 (group)
            
            if not attack_flags_group_count then
                attack_flags_group_count = self.attack_flags_group_count or 0
            end
            if not attack_flags_group[group] then
                attack_flags_group[group] = self["attack_flags_group_"..group] or 0
            end
            
            -- Update number of groups present
            attack_flags_group_count = max(attack_flags_group_count, group)

            -- Toggle
            local u32 = attack_flags_group[group]
            if ((u32 & flag) == 0) and state then
                attack_flags_group[group] = u32 + flag
            elseif ((u32 & flag) > 0) and (not state) then
                attack_flags_group[group] = u32 - flag
            end
        end
    end

    -- Store values back into struct
    if attack_flags_group_count then
        self.attack_flags_group_count = attack_flags_group_count

        -- Set unintialized flag groups to 0
        for group = 1, attack_flags_group_count do
            self["attack_flags_group_"..group] = attack_flags_group[group] or 0
        end
    end
end


-- ========== Metatables ==========

---@class AttackInfo
---@field value Struct The value being wrapped.
---@field RAPI string The name of this wrapper.

local mt_name = "AttackInfo"

W.AttackInfo = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return proxy[t] end
        if k == "RAPI" then return mt_name end

        -- Methods
        local method = methods[k]
        if method then return method end

        -- Getter
        return proxy[t][k]
    end,

    __newindex = function(t, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI" then
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
metatable = W.AttackInfo


-- ========== Hooks ==========

-- Write custom attack flags
gm.post_script_hook(gm.constants.write_attackinfo, function(self, other, result, args)
    local info  = args[1].value  ---@type Struct
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
    local info  = result.value  ---@type Struct
    local count = gm.readbyte()

    if count > 0 then
        info.attack_flags_group_count = count

        for group = 1, count do
            info["attack_flags_group_"..group] = gm.readuint()
        end
    end
end)