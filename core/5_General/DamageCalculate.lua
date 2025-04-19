-- DamageCalculate

DamageCalculate = new_class()

run_once(function()
    __damage_calc_callbacks = {}
end)



-- ========== Static Methods ==========

--$static
--$param        fn          | function  | The function to register. <br>The parameters for it are `actor, target, api`.
--[[
Registers a function for modifying damage calculation.
]]
DamageCalculate.add = function(namespace, fn)
    -- Create namespace subtable if it does not exist
    if not __damage_calc_callbacks[namespace] then __damage_calc_callbacks[namespace] = {} end

    table.insert(__damage_calc_callbacks[namespace], fn)
end


--$static
--[[
Removes all registered damage calculation functions from your namespace.

Automatically called when you hotload your mod.
]]
DamageCalculate.remove_all = function(namespace)
    __damage_calc_callbacks[namespace] = nil
end



-- ========== Internal ==========

local params = {}

-- Original arguments from hooked function
local hook_args
local hook_args_names = {
    hit_info        = 0,
    true_hit        = 1,
    hit             = 2,
    damage          = 3,
    critical        = 4,
    parent          = 5,
    proc            = 6,
    attack_flags    = 7,
    damage_col      = 8,
    team            = 9,
    climb           = 10,
    percent_hp      = 11,
    xscale          = 12,
    hit_x           = 13,
    hit_y           = 14
}

local api
local api_internal = {

    damage_mult = function(value, update_damage_number)
        local prev_damage = api.damage
        api.damage = math.ceil(api.damage * value)
        params.damage_true = math.ceil(params.damage_true * value)

        -- Update damage number
        if update_damage_number ~= false then
            params.damage_fake = math.ceil(params.damage_fake * value)

        -- Return difference between current and previous damage
        -- This value can then be drawn separately
        else
            return prev_damage - api.damage
        end
    end,


    set_critical = function(bool)
        if bool == nil then log.error("set_critical: Missing bool argument", 2) end

        -- Enable crit
        if (not api.critical) and bool then
            api.critical = true
            api.damage = api.damage * 2
            params.damage_true = params.damage_true * 2
            params.damage_fake = params.damage_fake * 2

        -- Disable crit
        elseif api.critical and (not bool) then
            api.critical = false
            api.damage = math.ceil(api.damage / 2)
            params.damage_true = math.ceil(params.damage_true / 2)
            params.damage_fake = math.ceil(params.damage_fake / 2)

        end
    end

}

api = setmetatable({}, {
    __index = function(t, k)
        -- Get original function arguments
        local arg_num = hook_args_names[k]
        if arg_num then
            return RValue.to_wrapper(hook_args[arg_num])
        end

        -- Methods
        if api_internal[k] then
            return api_internal[k]
        end

        log.error("api has no property or method '"..k.."'", 2)
    end,

    __newindex = function(t, k, v)
        -- Set original function arguments
        local arg_num = hook_args_names[k]
        if arg_num then
            hook_args[arg_num] = RValue.from_wrapper(v)
            return
        end

        log.error("api has no property '"..k.."' to set", 2)
    end,

    __metatable = "RAPI.DamageCalculate.api"
})

local function reset_params()
    params.damage_true = 1
    params.damage_fake = 1
end



-- ========== Hooks ==========

local ptr = gm.get_script_function_address(gm.constants.damager_calculate_damage)

memory.dynamic_hook_mid("RAPI.DamageCalculate.damager_calculate_damage", {"r14", "rbp-40h", "rbp+20h"}, {"RValue**", "RValue*", "RValue*"}, 0, ptr:add(0x438D), Util.jit_off(function(args)
    -- Get argument array (stored in register `r14` with type `RValue**`)
    hook_args = ffi.cast("struct RValue**", args[1]:get_address())
    
    -- Reset `params` table
    reset_params()

    -- Gather params
    -- Loop through all namespace subtables
    for namespace, funcs in pairs(__damage_calc_callbacks) do

        -- Call each registered function in the namespace
        for _, fn in ipairs(funcs) do
            fn(api) -- TODO pass actor, hit, etc.
        end
    end


    -- ===== Apply params =====
    -- Only need to do this for local variables in the function
    -- Anything that was part of the original arguments
    -- can be get/set directly via `api.<argument>` etc. `api.damage`

    -- damage_true
    args[2].value = args[2].value * params.damage_true

    -- damage_fake
    args[3].value = args[3].value * params.damage_fake
end))



-- Public export
__class.DamageCalculate = DamageCalculate