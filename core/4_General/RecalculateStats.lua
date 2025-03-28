-- RecalculateStats

RecalculateStats = new_class()

if not __recalc_stats_callbacks then __recalc_stats_callbacks = {} end  -- Preserve on hotload



-- ========== Static Methods ==========

RecalculateStats.add = function(namespace, fn)
    if not __recalc_stats_callbacks[namespace] then __recalc_stats_callbacks[namespace] = {} end

    table.insert(__recalc_stats_callbacks[namespace], fn)
end

RecalculateStats.remove_all = function(namespace)
    __recalc_stats_callbacks[namespace] = nil
end



-- ========== Internal ==========

local params = {
    --skill_primary = {},
    skill_secondary = {},
    skill_utility = {},
    skill_special = {},
}

local function reset_params()
    params.maxhp_add = 0 -- health capacity
    params.maxhp_mult = 1

    params.hp_regen_add = 0 -- amount added to hp every frame
    params.hp_regen_mult = 1

    params.pHmax_add = 0 -- horizontal movement speed, in pixels/frame
    params.pHmax_mult = 1

    params.pVmax_add = 0 -- vertical speed applied when jumping
    params.pVmax_mult = 1

    params.pGravity1_add = 0 -- downward acceleration while in the air
    params.pGravity1_mult = 1

    params.pGravity2_add = 0 -- downward acceleration while ascending and holding jump input after jumping
    params.pGravity2_mult = 1

    params.damage_add = 0 -- "base damage" stat, multiplied by skill and proc damage percents
    params.damage_mult = 1

    params.attack_speed_add = 0 -- multiplier for speed of attack animations
    params.attack_speed_mult = 1

    params.critical_chance_add = 0 -- percent chance to do double damage
    params.critical_chance_mult = 1

    params.maxshield_add = 0 -- additional layer of hp that instantly recovers after 7 seconds spent untouched
    params.maxshield_mult = 1

    params.armor_add = 0 -- damage reduction using a special non-linear formula -- negative values result in increased damage up to +100%
    params.armor_mult = 1

    params.cooldown_mult = 1 -- multiplier for skill cooldowns
    params.equipment_cooldown_mult = 1 -- multiplier for equipment cooldown

    params.knockback_cap_add = 0 -- damage threshold for being staggered
    params.knockback_cap_mult = 1

    params.maxbarrier_add = 0
    params.maxbarrier_mult = 1

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

local function gather_params(self)
    reset_params()

    -- local inst = Instance.wrap(self)     -- self is already 'Actor' or 'Player'

    -- Debug
    -- Just leave this here; it should never run
    if type(self) == "userdata" then
        print("gather_params: userdata detected")
        print(getmetatable(self).__name)
    end

    for namespace, funcs in pairs(__recalc_stats_callbacks) do
        for _, fn in ipairs(funcs) do
            fn(self, api)
        end
    end
end



-- ========== Hooks ==========

memory.dynamic_hook("RAPI.recalculate_stats", "void*", {"CInstance*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.recalculate_stats),
    -- Pre-hook
    {function(ret_val, self, other, result, arg_count, args)
        gather_params(Instance.wrap(self.id))   -- TODO use converter when iDeath is done
    end,

    -- Post-hook
    nil}
)

local ptr = gm.get_script_function_address(gm.constants.recalculate_stats)

memory.dynamic_hook_mid("RAPI.RecalculateStats.knockback_cap", {"rbx"}, {"RValue*"}, 0, ptr:add(0x96d), function(args)
    args[1].value = (args[1].value + params.knockback_cap_add) * params.knockback_cap_mult
end)

memory.dynamic_hook_mid("RAPI.RecalculateStats.cdr", {"rdi"}, {"RValue*"}, 0, ptr:add(0xa6c), function(args)
    -- the internal value is unintuitive, so invert it in the API to be a standard multiplier
    args[1].value = 1 - ((1 - args[1].value) * params.cooldown_mult)
end)
memory.dynamic_hook_mid("RAPI.RecalculateStats.maxhp", {"rcx"}, {"RValue*"}, 0, ptr:add(0xd7e), function(args)
    -- runs between vanilla additive and multiplicative modifiers, so both operations can be in the same hook
    args[1].value = (args[1].value + params.maxhp_add) * params.maxhp_mult
end)
-- added to hp every step/frame
memory.dynamic_hook_mid("RAPI.RecalculateStats.hp_regen", {"rax"}, {"RValue*"}, 0, ptr:add(0x22e7), function(args)
    -- no multiplicative regen modifiers in vanilla
    args[1].value = (args[1].value + params.hp_regen_add) * params.hp_regen_mult
end)
memory.dynamic_hook_mid("RAPI.RecalculateStats.damage", {"rax"}, {"RValue*"}, 0, ptr:add(0x156b), function(args)
    -- runs between vanilla additive and multiplicative modifiers, so both operations can be in the same hook
    -- prevent value from going below 0 because vanilla doesn't protect against it
    args[1].value = math.max(0, (args[1].value + params.damage_add) * params.damage_mult)
end)

memory.dynamic_hook_mid("RAPI.RecalculateStats.maxshield", {"rax"}, {"RValue*"}, 0, ptr:add(0x1bdf), function(args)
    -- no multiplicative shield modifiers in vanilla
    -- prevent value from going below 0 because vanilla doesn't protect against it
    args[1].value = math.max(0, (args[1].value + params.maxshield_add) * params.maxshield_mult)
end)

memory.dynamic_hook_mid("RAPI.RecalculateStats.critical_chance", {"rdx"}, {"RValue*"}, 0, ptr:add(0x28c7), function(args)
    -- no multiplicative crit chance modifiers in vanilla
    args[1].value = (args[1].value + params.critical_chance_add) * params.critical_chance_mult
end)

memory.dynamic_hook_mid("RAPI.RecalculateStats.attack_speed", {"rdx"}, {"RValue*"}, 0, ptr:add(0x3034), function(args)
    -- no multiplicative attack speed modifiers in vanilla
    args[1].value = (args[1].value + params.attack_speed_add) * params.attack_speed_mult
end)

memory.dynamic_hook_mid("RAPI.RecalculateStats.pHmax", {"rax"}, {"RValue*"}, 0, ptr:add(0x3c06), function(args)
    -- runs between vanilla additive and multiplicative modifiers, so both operations can be in the same hook
    args[1].value = (args[1].value + params.pHmax_add) * params.pHmax_mult
end)

memory.dynamic_hook_mid("RAPI.RecalculateStats.armor", {"rax"}, {"RValue*"}, 0, ptr:add(0x4187), function(args)
    -- runs between vanilla additive and multiplicative modifiers, so both operations can be in the same hook
    args[1].value = (args[1].value + params.armor_add) * params.armor_mult
end)

memory.dynamic_hook_mid("RAPI.RecalculateStats.equipment_cdr", {"rdi"}, {"RValue*"}, 0, ptr:add(0x4675), function(args)
    -- the internal value is unintuitive, so invert it in the API to be a standard multiplier
    args[1].value = 1 - ((1 - args[1].value) * params.equipment_cooldown_mult)
end)

memory.dynamic_hook_mid("RAPI.RecalculateStats.pVmax", {"rbx"}, {"RValue*"}, 0, ptr:add(0x4811), function(args)
    args[1].value = (args[1].value + params.pVmax_add) * params.pVmax_mult
end)

memory.dynamic_hook_mid("RAPI.RecalculateStats.pGravity1", {"rbx"}, {"RValue*"}, 0, ptr:add(0x4858), function(args)
    args[1].value = (args[1].value + params.pGravity1_add) * params.pGravity1_mult
end)

memory.dynamic_hook_mid("RAPI.RecalculateStats.pGravity2", {"rbx"}, {"RValue*"}, 0, ptr:add(0x489f), function(args)
    args[1].value = (args[1].value + params.pGravity2_add) * params.pGravity2_mult
end)

memory.dynamic_hook_mid("RAPI.RecalculateStats.maxbarrier", {"rax"}, {"RValue*"}, 0, ptr:add(0x5053), function(args)
    args[1].value = math.max(0, (args[1].value + params.maxbarrier_add) * params.maxbarrier_mult)
end)

local ActorSkill_recalculate_stats = gm.constants.anon_ActorSkill_gml_GlobalScript_scr_actor_skills_83921016_ActorSkill_gml_GlobalScript_scr_actor_skills
local class_skill = Global.class_skill

local index_to_table = {
    [1] = "skill_secondary",
    [2] = "skill_utility",
    [3] = "skill_special",
}

-- this gets called extremely frequently -- 12 times when an actor spawns, and 4 times each time stats are recaculated. needs to be optimal as possible
memory.dynamic_hook("RAPI.ActorSkill.skill_recalculate_stats", "void*", {"YYObjectBase*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(ActorSkill_recalculate_stats),
    -- Pre-hook
    {nil,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
        local self_cdata = ffi.cast("YYObjectBase*", memory.get_usertype_pointer(self))
        local self_struct = Struct.wrap_yyobjectbase(self_cdata)

        -- Get skill_id
        local skill_id = self_struct.skill_id or 0

        -- Check if skill is primary
        local is_primary = class_skill:get(skill_id):get(17) or false
        if is_primary then return end
        
        gather_params(self_struct.parent)

        local skill_index = self_struct.slot_index or 1
        local modifiers = params[index_to_table[skill_index]]
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
        local auto_restock = class_skill:get(skill_id):get(10) or false
        if auto_restock then
            local skill_start_cooldown = self_struct.skill_start_cooldown

            -- TODO verify that this actually works
            skill_start_cooldown(self_struct.value, self_struct.value)
        end
    end}
)



__class.RecalculateStats = RecalculateStats