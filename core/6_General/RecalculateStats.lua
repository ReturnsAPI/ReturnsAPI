-- RecalculateStats

RecalculateStats = new_class()

run_once(function()
    __recalcstats_cache = CallbackCache.new()
end)



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       number
--@param        fn          | function  | The function to register. <br>The parameters for it are `actor, api`.
--@overload
--@return       number
--@param        priority    | number    | The priority of the function. <br>Higher values run before lower ones; can be negative. <br>`Callback.Priority.NORMAL` (`0`) by default.
--@param        fn          | function  | The function to register. <br>The parameters for it are `actor, api`.
--[[
Registers a function for stat recalculation.
Returns the unique ID of the registered function.

*Technical:* This function will run in `recalculate_stats` pre-hook.

**Priority Convention**
To allow for a decent amount of space between priorities,
use the enum values in @link {`Callback.Priority` | Callback#Priority}.
If you need to be more specific than that, try to keep a distance of at least `100`.
]]
RecalculateStats.add = function(NAMESPACE, arg1, arg2)
    if type(arg1) == "function" then
        return __recalcstats_cache:add(arg1, NAMESPACE)
    end
    return __recalcstats_cache:add(arg2, NAMESPACE, arg1)
end


--@static
--@return       function
--@param        id          | number    | The unique ID of the registered function to remove.
--[[
Removes and returns a registered stat recalculation function.
The ID is the one from @link {`RecalculateStats.add` | RecalculateStats#add}.
]]
RecalculateStats.remove = function(id)
    return __recalcstats_cache:remove(id)
end


--@static
--[[
Removes all registered stat recalculation functions from your namespace.

Automatically called when you hotload your mod.
]]
RecalculateStats.remove_all = function(NAMESPACE)
    __recalcstats_cache:remove_all(NAMESPACE)
end
table.insert(_clear_namespace_functions, RecalculateStats.remove_all)



-- ========== Internal ==========

--@section `api`

--[[
### Methods
Method | Arguments | Notes
| - | - | -
`maxhp_add( value )`                        | `value` (number) <br>* The value to add.          | 
`maxhp_mult( value )`                       | `value` (number) <br>* The value to multiply by.  | 
`hp_regen_add( value )`                     | `value` (number) <br>* The value to add.          | 
`hp_regen_mult( value )`                    | `value` (number) <br>* The value to multiply by.  | 
`damage_add( value )`                       | `value` (number) <br>* The value to add.          | 
`damage_mult( value )`                      | `value` (number) <br>* The value to multiply by.  | 
`attack_speed_add( value )`                 | `value` (number) <br>* The value to add.          | 
`attack_speed_mult( value )`                | `value` (number) <br>* The value to multiply by.  | 
`critical_chance_add( value )`              | `value` (number) <br>* The value to add.          | 
`critical_chance_mult( value )`             | `value` (number) <br>* The value to multiply by.  | 
`maxshield_add( value )`                    | `value` (number) <br>* The value to add.          | 
`maxshield_mult( value )`                   | `value` (number) <br>* The value to multiply by.  | 
`maxshield_add_from_maxhp( value )`         | `value` (number) <br>* The value to add.          | Adds `maxshield` based on % of `maxhp` (without modifying `maxhp`).
`maxhp_convert_to_maxshield( value )`       | `value` (number) <br>* The value to convert.      | Converts % of `maxhp` to `maxshield`. <br>This value *can* be greater than `1.0`.
`maxbarrier_add( value )`                   | `value` (number) <br>* The value to add.          | 
`maxbarrier_mult( value )`                  | `value` (number) <br>* The value to multiply by.  | 
`armor_add( value )`                        | `value` (number) <br>* The value to add.          | 
`armor_mult( value )`                       | `value` (number) <br>* The value to multiply by.  |  
`cooldown_mult( value )`                    | `value` (number) <br>* The value to multiply by.  | E.g., To reduce cooldowns by 70%, multiply by `0.3`.
`equipment_cooldown_mult( value )`          | `value` (number) <br>* The value to multiply by.  | E.g., To reduce cooldown by 70%, multiply by `0.3`.
`knockback_cap_add( value )`                | `value` (number) <br>* The value to add.          | Damage threshold to get staggered by an attack. <br> Base value is `1e+25` for players (i.e., can only <br>get stunned from attacks marked as such).
`knockback_cap_mult( value )`               | `value` (number) <br>* The value to multiply by.  | 
`pHmax_add( value )`                        | `value` (number) <br>* The value to add.          | 
`pHmax_mult( value )`                       | `value` (number) <br>* The value to multiply by.  | 
`pVmax_add( value )`                        | `value` (number) <br>* The value to add.          | 
`pVmax_mult( value )`                       | `value` (number) <br>* The value to multiply by.  | 
`pGravity1_add( value )`                    | `value` (number) <br>* The value to add.          | 
`pGravity1_mult( value )`                   | `value` (number) <br>* The value to multiply by.  | 
`pGravity2_add( value )`                    | `value` (number) <br>* The value to add.          | 
`pGravity2_mult( value )`                   | `value` (number) <br>* The value to multiply by.  | 
`skill_secondary.max_stock_add( value )`    | `value` (number) <br>* The value to add.          | 
`skill_secondary.cooldown_mult( value )`    | `value` (number) <br>* The value to multiply by.  | 
`skill_utility.max_stock_add( value )`      | `value` (number) <br>* The value to add.          | 
`skill_utility.cooldown_mult( value )`      | `value` (number) <br>* The value to multiply by.  | 
`skill_special.max_stock_add( value )`      | `value` (number) <br>* The value to add.          | 
`skill_special.cooldown_mult( value )`      | `value` (number) <br>* The value to multiply by.  | 
]]


local params

local function reset_params()
    params = {
        --skill_primary = {},
        skill_secondary = {},
        skill_utility = {},
        skill_special = {},
    }

    params.maxhp_add = 0 -- health capacity
    params.maxhp_mult = 1

    params.hp_regen_add = 0 -- amount added to hp every frame
    params.hp_regen_mult = 1

    params.damage_add = 0 -- "base damage" stat, multiplied by skill and proc damage percents
    params.damage_mult = 1

    params.attack_speed_add = 0 -- multiplier for speed of attack animations
    params.attack_speed_mult = 1

    params.critical_chance_add = 0 -- percent chance to do double damage
    params.critical_chance_mult = 1

    params.maxshield_add = 0 -- additional layer of hp that instantly recovers after 7 seconds spent untouched
    params.maxshield_mult = 1

    -- Health-Shield interactions
    -- Don't really like this but can't think of a better idea
    -- This should exist though since it's already an established thing from RoR2
    -- Both of these are additive, and can go over 1.0
    --      * E.g., Transcendence would add `1.5 + 0.25*(stack-1)`
    params.maxshield_add_from_maxhp   = 0   -- Adds maxshield based on x% of maxhp; e.g., 1.0 adds maxshield equal to maxhp
    params.maxhp_convert_to_maxshield = 0   -- Converts x% of maxhp to maxshield
    
    params.maxbarrier_add = 0
    params.maxbarrier_mult = 1

    params.armor_add = 0 -- damage reduction using a special non-linear formula -- negative values result in increased damage up to +100%
    params.armor_mult = 1

    params.cooldown_mult = 1 -- multiplier for skill cooldowns
    params.equipment_cooldown_mult = 1 -- multiplier for equipment cooldown

    params.knockback_cap_add = 0 -- damage threshold for being staggered
    params.knockback_cap_mult = 1

    params.pHmax_add = 0 -- horizontal movement speed, in pixels/frame
    params.pHmax_mult = 1

    params.pVmax_add = 0 -- vertical speed applied when jumping
    params.pVmax_mult = 1

    params.pGravity1_add = 0 -- downward acceleration while in the air
    params.pGravity1_mult = 1

    params.pGravity2_add = 0 -- downward acceleration while ascending and holding jump input after jumping
    params.pGravity2_mult = 1

    -- primary skills usually can't be meaningfully given stocks or reduced cooldowns, so
    --params.skill_primary.stock_add = 0
    --params.skill_primary.cooldown_mult = 1
    params.skill_secondary.max_stock_add = 0 -- capacity for usable 'stocks' of the skill
    params.skill_secondary.cooldown_mult = 1 -- multiplier for individual skill cooldown
    params.skill_utility.max_stock_add = 0
    params.skill_utility.cooldown_mult = 1
    params.skill_special.max_stock_add = 0
    params.skill_special.cooldown_mult = 1
end
reset_params()

local api = {}

for param, value in pairs(params) do
    if type(value) == "number" then -- standard
        local fn
        if string.sub(param, -4, -1) == "mult" then
            fn = function(multiplier)
                params[param] = params[param] * multiplier
            end
        else
            fn = function(adder)
                params[param] = params[param] + adder
            end
        end
        api[param] = fn
    elseif type(value) == "table" then
        api[param] = ReadOnly.new({
            max_stock_add = function(stock)
                params[param].max_stock_add = params[param].max_stock_add + stock
            end,
            cooldown_mult = function(mult)
                params[param].cooldown_mult = params[param].cooldown_mult * mult
            end,
        })
    end
end

api = ReadOnly.new(api)

local gather_params = function(actor)
    -- Reset the `params` table
    reset_params()

    -- Gather params
    -- Call registered functions with wrapped arg
    __recalcstats_cache:loop_and_call_functions(function(fn_table)
        local status, err = pcall(fn_table.fn, actor, api)
        if not status then
            if (err == nil)
            or (err == "C++ exception") then err = "GameMaker error (see above)" end
            log.warning("\n"..fn_table.namespace..": RecalculateStats (ID '"..fn_table.id.."') failed to execute fully.\n"..err)
        end
    end)
end



-- ========== Hooks ==========

Hook.add_pre(RAPI_NAMESPACE, gm.constants.recalculate_stats, Callback.internal.FIRST, function(self, other, result, args)
    gather_params(self)
end)


local ptr = gm.get_script_function_address(gm.constants.recalculate_stats)

-- Hooks line 28 (`knockback_cap = knockback_cap_base`)
-- IDA: Constant 15901314; hook below
memory.dynamic_hook_mid("RAPI.RecalculateStats.knockback_cap", {"rbx"}, {"RValue*"}, 0, ptr:add(0xAE4), function(args)
    args[1].value = (args[1].value + params.knockback_cap_add) * params.knockback_cap_mult
end)

-- Hooks line 29 (`cdr = 1 - power ...`)
-- IDA: Enum 68; hook below
memory.dynamic_hook_mid("RAPI.RecalculateStats.cdr", {"rbp-D0h"}, {"RValue*"}, 0, ptr:add(0xBD8), function(args)
    -- the internal value is unintuitive, so invert it in the API to be a standard multiplier
    args[1].value = 1 - ((1 - args[1].value) * params.cooldown_mult)
end)

-- Hooks line 33 (between `_maxhp += (infusion_hp ...` and `_maxhp *= (1 + ...` (Bitter Root))
-- IDA: Look for constants 81 and 40, and several lines below hook value the returns are added to
memory.dynamic_hook_mid("RAPI.RecalculateStats.maxhp", {"rbp+A8h"}, {"RValue*"}, 0, ptr:add(0xEE3), function(args)
    -- maxhp
    -- runs between vanilla additive and multiplicative modifiers, so both operations can be in the same hook
    local finalized = (args[1].value + params.maxhp_add) * params.maxhp_mult
    params.__original_finalized_hp = finalized

    -- Reduce maxhp from Health -> Shield conversion
    -- Don't have to worry about <= 0 since it's handled later
    finalized = finalized * (1 - params.maxhp_convert_to_maxshield)

    args[1].value = finalized
end)

-- Hooks line 109 (`hp_regen = _hp_regen`)
-- IDA: Look for constants 0.03 and two 0.006s; hook value below
memory.dynamic_hook_mid("RAPI.RecalculateStats.hp_regen", {"rax"}, {"RValue*"}, 0, ptr:add(0x2509), function(args)
    -- no multiplicative regen modifiers in vanilla
    args[1].value = (args[1].value + params.hp_regen_add) * params.hp_regen_mult
end)

-- Hooks line 64 (`_damage += ((_temp_item_stack ...`)
-- IDA: Look for constants 0.5, 4, 1; hook value several lines below (last add)
memory.dynamic_hook_mid("RAPI.RecalculateStats.damage", {"rbp+98h"}, {"RValue*"}, 0, ptr:add(0x1744), function(args)
    -- runs between vanilla additive and multiplicative modifiers, so both operations can be in the same hook
    -- prevent value from going below 0 because vanilla doesn't protect against it
    args[1].value = math.max(0, (args[1].value + params.damage_add) * params.damage_mult)
end)

-- Hooks line 98 (var _maxshield = maxshield_base + ...`)
-- IDA: Look for constants 60, 20 (and enums 37, 98); hook below
memory.dynamic_hook_mid("RAPI.RecalculateStats.maxshield", {"rax"}, {"RValue*"}, 0, ptr:add(0x1E0F), function(args)
    -- no multiplicative shield modifiers in vanilla
    local finalized = (
        args[1].value
        + params.maxshield_add
        + (params.maxshield_add_from_maxhp * params.__original_finalized_hp)
        + (params.maxhp_convert_to_maxshield * params.__original_finalized_hp)
    ) * params.maxshield_mult

    -- prevent value from going below 0 because vanilla doesn't protect against it
    args[1].value = math.max(0, finalized)
end)

-- Hooks line 127 (`critical_chance = _critical_chance`)
-- IDA: Look for constants 5 and 9 after (and enums 33, 120, 28); hook a few lines *above*
memory.dynamic_hook_mid("RAPI.RecalculateStats.critical_chance", {"rbp+2F0h"}, {"RValue*"}, 0, ptr:add(0x2A5B), function(args)
    -- no multiplicative crit chance modifiers in vanilla
    args[1].value = (args[1].value + params.critical_chance_add) * params.critical_chance_mult
end)

-- Hooks line 135 (`attack_speed = _attack_speed`)
-- IDA: Look for constants 0.1, 0.3, 1; hook after some conditional
memory.dynamic_hook_mid("RAPI.RecalculateStats.attack_speed", {"rbp+350h"}, {"RValue*"}, 0, ptr:add(0x31C9), function(args)
    -- no multiplicative attack speed modifiers in vanilla
    args[1].value = (args[1].value + params.attack_speed_add) * params.attack_speed_mult
end)

-- Hooks line 151 (`pHmax_raw = max( ...`)
-- IDA: Constants 3, 180 (enum 7); hook down
memory.dynamic_hook_mid("RAPI.RecalculateStats.pHmax", {"rax"}, {"RValue*"}, 0, ptr:add(0x3E6C), function(args)
    -- runs before BUFF_ID.imp_eye multiplier
    args[1].value = (args[1].value + params.pHmax_add) * params.pHmax_mult
end)

-- Hooks line 165 (`armor = _armor`)
-- IDA: Look for constants 1000, 999999, 30 (x2) (enums 22, 110, 50); hook down
memory.dynamic_hook_mid("RAPI.RecalculateStats.armor", {"rax"}, {"RValue*"}, 0, ptr:add(0x4424), function(args)
    -- no multiplicative armor modifiers in vanilla
    args[1].value = (args[1].value + params.armor_add) * params.armor_mult
end)

-- Hooks line 170 (`equipment_cdr = 1 - (1 ...`)
-- IDA: Constants 0.75, 0.95 (enums 61, 85); hook below
memory.dynamic_hook_mid("RAPI.RecalculateStats.equipment_cdr", {"rax"}, {"RValue*"}, 0, ptr:add(0x4915), function(args)
    -- the internal value is unintuitive, so invert it in the API to be a standard multiplier
    args[1].value = 1 - ((1 - args[1].value) * params.equipment_cooldown_mult)
end)

-- pVmax, pGravity1, pGravity2 (post-hook)
gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    if not params then return end

    self.pVmax     = (self.pVmax     + params.pVmax_add)     * params.pVmax_mult
    self.pGravity1 = (self.pGravity1 + params.pGravity1_add) * params.pGravity1_mult
    self.pGravity2 = (self.pGravity2 + params.pGravity2_add) * params.pGravity2_mult
    
    -- delete params table
    params = nil
end)

-- Hooks line 196 (`maxbarrier = (maxhp + ...`)
-- IDA: Look for constants 1, 0.2 (enums 92); hook below
memory.dynamic_hook_mid("RAPI.RecalculateStats.maxbarrier", {"rax"}, {"RValue*"}, 0, ptr:add(0x533A), function(args)
    args[1].value = math.max(0, (args[1].value + params.maxbarrier_add) * params.maxbarrier_mult)
end)


local class_skill = Global.class_skill

local index_to_table = {
    [1] = "skill_secondary",
    [2] = "skill_utility",
    [3] = "skill_special",
}

-- this gets called extremely frequently -- 12 times when an actor spawns, and 4 times each time stats are recaculated. needs to be optimal as possible
-- local _actorskill = Struct.new(gm.constants.ActorSkill, nil, 0, nil)  -- Create empty ActorSkill to grab the script name
-- ^ this actually throws an error on startup so don't

gm.post_script_hook(gm.constants["skill_recalculate_stats@anon@8392@ActorSkill@scr_actor_skills"], function(self, other, result, args)
    if not params then return end

    local self_struct = Struct.wrap(self)

    -- Get skill_id
    local skill_id = self_struct.skill_id or 0
    local skill = Skill.wrap(skill_id)

    -- Check if skill is primary
    local is_primary = skill.is_primary or false
    if is_primary then return end

    local slot_index = self_struct.slot_index
    local modifiers = params[index_to_table[slot_index]]
    if not modifiers then return end

    -- add stock
    local max_stock = self_struct.max_stock
    max_stock = math.max(1, max_stock + modifiers.max_stock_add)
    self_struct.max_stock = max_stock

    -- modify cooldown
    local cooldown = self_struct.cooldown
    cooldown = math.floor(math.max(30, cooldown * modifiers.cooldown_mult))
    self_struct.cooldown = cooldown

    -- start cooldown if necessary. ugly because orig already calls this before this hook, but oh well
    local auto_restock = skill.auto_restock or false
    if auto_restock then
        -- Autobinds `self_struct` as self/other
        -- (See Struct class metatable for specifics of this)
        self_struct.skill_start_cooldown()
    end
end)



-- Public export
__class.RecalculateStats = RecalculateStats