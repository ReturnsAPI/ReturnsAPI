-- DamageCalculate

DamageCalculate = new_class()

run_once(function()
    __damage_calc_namespace     = {}    -- Contains fn_tables sorted by namespace
    __damage_calc_priority      = {}    -- Contains fn_tables sorted by priority
    __damage_calc_priorities    = {}    -- Contains list of priorities in use (in order)
end)



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@param        fn          | function  | The function to register. <br>The parameters for it are `api`.
--@optional     priority    | number    | The priority of the function. <br>Higher values run before lower ones; can be negative. <br>`Callback.Priority.NORMAL` (`0`) by default.
--[[
Registers a function for modifying damage calculation.
The function runs for both host and client.

**Priority Convention**
To allow for a decent amount of space between priorities,
use the enum values in @link {`Callback.Priority` | Callback#Priority}.
If you need to be more specific than that, try to keep a distance of at least `100`.
]]
DamageCalculate.add = function(namespace, fn, priority)
    -- Default priority is 0
    priority = priority or 0

    local fn_table = {
        namespace   = namespace,
        fn          = fn,
        priority    = priority
    }

    -- Create namespace subtable if it does not exist
    if not __damage_calc_namespace[namespace] then __damage_calc_namespace[namespace] = {} end
    table.insert(__damage_calc_namespace[namespace], fn_table)

    -- Create priority subtable if it does not exist
    if not __damage_calc_priority[priority] then
        __damage_calc_priority[priority] = {}
        table.insert(__damage_calc_priorities, priority)
        table.sort(__damage_calc_priorities, function(a, b) return a > b end)
    end
    table.insert(__damage_calc_priority[priority], fn_table)
end


--@static
--[[
Removes all registered damage calculation functions from your namespace.

Automatically called when you hotload your mod.
]]
DamageCalculate.remove_all = function(namespace)
    local ns_table = __damage_calc_namespace[namespace]
    if not ns_table then return end
    for _, fn_table in pairs(ns_table) do
        local priority = fn_table.priority
        Util.table_remove_value(__damage_calc_priority[priority], fn_table)
        if #__damage_calc_priority[priority] <= 0 then
            __damage_calc_priority[priority] = nil
            Util.table_remove_value(__damage_calc_priorities, priority)
        end
    end
    __damage_calc_namespace[namespace] = nil
end



-- ========== Internal ==========

--@section `api`

--[[
### Properties
These can all be get/set to.
Property | Type | Description
| - | - | -
`hit_info`      | Struct    | The `hit_info` struct. <br>May not exist. <br>Does not exist for clients.
`true_hit`      | Actor(?)  | The actual instance hit. <br>May be different from `hit` (i.e., a worm segment).
`hit`           | Actor     | The actor that was hit.
`damage`        | number    | The damage of the attack.
`critical`      | bool      | `true` if the attack is a critical hit.
`parent`        | Actor     | The parent actor of the attack.
`proc`          | bool      | `true` if the attack can proc.
`attack_flags`  | number    | The attack flags (TODO link this) of the attack.
`damage_col`    | number    | The damage color.
`team`          | number    | The team the attack belongs to.
`climb`         | number    | 
`percent_hp`    | number    | If non-`0`, the minimum damage of the attack is <br>`percent_hp`% of the actor's current health.
`xscale`        | number    | 
`hit_x`         | number    | The x coordinate the attack hit.
`hit_y`         | number    | The y coordinate the attack hit.

<br>

### Methods
Method | Arguments | Description
| - | - | -
`damage_mult( value, update_damage_number )` | `value` (number) <br>* The damage multiplier. <br>* `1` leaves damage unchanged. <br><br>`update_damage_number` (bool) <br>* Whether or not to update the damage number. <br>* `true` by default. | Multiplies damage by `value`. <br>If `update_damage_number` is `false`, the damage number will not be updated; instead, the difference between the new and old damage will be returned, which can be manually drawn.
`set_critical( bool )` | `bool` (bool) <br>* If `true`, the attack will be a critical hit. <br>* If `false`, the attack will not crit. | Sets the critical hit state of the attack.
]]


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

        -- Otherwise, return difference between current and previous damage
        -- This value can then be drawn separately
        else
            return api.damage - prev_damage
        end
    end,


    set_critical = function(bool)
        if bool == nil then log.error("set_critical: Missing bool argument", 2) end

        -- Enable crit
        if bool and (not api.critical) then
            api.critical = true
            api.damage = api.damage * 2
            params.damage_true = params.damage_true * 2
            params.damage_fake = params.damage_fake * 2

        -- Disable crit
        elseif (not bool) and api.critical then
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
            local ret = RValue.to_wrapper(hook_args[arg_num])

            -- Wrap instance as invalid if nil or -4
            if  (k == "parent"
            or   k == "hit"
            or   k == "true_hit")
            and (ret == nil or ret == -4) then
                ret = __invalid_instance
            end

            return ret
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

local ptr = gm.get_script_function_address(gm.constants.damager_calculate_damage)   -- 0x0000000 140B154D0

memory.dynamic_hook_mid("RAPI.DamageCalculate.damager_calculate_damage", {"r14", "rbp-40h", "rbp+20h"}, {"RValue**", "RValue*", "RValue*"}, 0, ptr:add(0x438D), function(args)
    -- Get argument array (stored in register `r14` with type `RValue**`)
    hook_args = ffi.cast(__args_typed_scr, args[1]:get_address())
    
    -- Reset `params` table
    reset_params()

    -- Gather params
    -- Loop through all priorities
    for _, priority in pairs(__damage_calc_priorities) do

        -- Call each registered function in the priority subtable
        local subtable = __damage_calc_priority[priority]
        for _, fn_table in ipairs(subtable) do
            local status, err = pcall(fn_table.fn, api)
            if not status then
                log.warning("\n"..fn_table.namespace:gsub("%.", "-")..": DamageCalculate failed to execute fully.\n"..err)
            end
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
end)



-- Public export
__class.DamageCalculate = DamageCalculate