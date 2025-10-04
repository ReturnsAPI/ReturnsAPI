-- DamageCalculate

DamageCalculate = new_class()

run_once(function()
    __damage_calc_cache = CallbackCache.new()
end)



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       number
--@param        fn          | function  | The function to register. <br>The parameter for it is `api`.
--@overload
--@return       number
--@param        priority    | number    | The priority of the function. <br>Higher values run before lower ones; can be negative. <br>`Callback.Priority.NORMAL` (`0`) by default.
--@param        fn          | function  | The function to register. <br>The parameter for it is `api`.
--[[
Registers a function for modifying damage calculation.
The function runs for both host and client.
Returns the unique ID of the registered function.

**Priority Convention**
To allow for a decent amount of space between priorities,
use the enum values in @link {`Callback.Priority` | Callback#Priority}.
If you need to be more specific than that, try to keep a distance of at least `100`.
]]
DamageCalculate.add = function(NAMESPACE, arg1, arg2)
    if type(arg1) == "function" then
        return __damage_calc_cache:add(arg1, NAMESPACE)
    end
    return __damage_calc_cache:add(arg2, NAMESPACE, arg1)
end


--@static
--@return       function
--@param        id          | number    | The unique ID of the registered function to remove.
--[[
Removes and returns a registered damage calculation function.
The ID is the one from @link {`DamageCalculate.add` | DamageCalculate#add}.
]]
DamageCalculate.remove = function(id)
    return __damage_calc_cache:remove(id)
end


--@static
--[[
Removes all registered damage calculation functions from your namespace.

Automatically called when you hotload your mod.
]]
DamageCalculate.remove_all = function(NAMESPACE)
    __damage_calc_cache:remove_all(NAMESPACE)
end
table.insert(_clear_namespace_functions, DamageCalculate.remove_all)



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
`attack_flags`  | number    | The @link {attack flags | AttackFlag#constants} of the attack.
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
local hook_args     -- Set by current hook call
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

local resolved_hook_args    -- Reset at start of current hook call
local function get_hook_arg(n)  --> RValue*
    -- Dereference correct address and resolve
    -- Move up 8 bytes to go to next arg
    -- Store result so it doesn't need re-resolving
    resolved_hook_args[n] = resolved_hook_args[n]
                            or memory.resolve_pointer_to_type(hook_args:add(n * 8):deref():get_address(), "RValue*")
    return resolved_hook_args[n]
end

local api
local api_internal = {

    damage_mult = function(value, update_damage_number)
        local prev_damage = api.damage
        api.damage = api.damage * value
        params.damage_true = params.damage_true * value

        -- Update damage number
        if update_damage_number ~= false then
            params.damage_fake = params.damage_fake * value

        -- Otherwise, return difference between current and previous damage
        -- This value can then be drawn separately
        else
            return math.ceil(api.damage - prev_damage)
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
            api.damage = api.damage / 2
            params.damage_true = params.damage_true / 2
            params.damage_fake = params.damage_fake / 2

        end
    end

}

api = setmetatable({}, {
    __index = function(t, k)
        -- Get original function arguments
        local arg_num = hook_args_names[k]
        if arg_num then
            return Wrap.wrap(get_hook_arg(arg_num).value)
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
            get_hook_arg(arg_num).value = Wrap.unwrap(v, true)
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

-- Hooks line 105 (right before `draw_damage` call)
memory.dynamic_hook_mid("RAPI.DamageCalculate.damager_calculate_damage", {"r14", "rbp+60h", "rbp+180h"}, {"RValue**", "RValue*", "RValue*"}, 0, ptr:add(0x30E0), function(args)
    -- Store argument array pointer
    hook_args = args[1]
    resolved_hook_args = {}
    
    -- Reset `params` table
    reset_params()

    -- Call registered functions with wrapped arg
    __damage_calc_cache:loop_and_call_functions(function(fn_table)
        local status, err = pcall(fn_table.fn, api)
        if not status then
            if (err == nil)
            or (err == "C++ exception") then err = "GameMaker error (see above)" end
            log.warning("\n"..fn_table.namespace..": DamageCalculate (ID '"..fn_table.id.."') failed to execute fully.\n"..err)
        end
    end)

    -- damage (round up)
    api.damage = math.ceil(api.damage)


    -- ===== Apply params =====
    -- Only need to do this for local variables in the function
    -- Anything that was part of the original arguments
    -- can be get/set directly via `api.<argument>` etc. `api.damage`

    -- damage_true
    args[2].value = math.ceil(args[2].value * params.damage_true)

    -- damage_fake
    args[3].value = math.ceil(args[3].value * params.damage_fake)
end)



-- Public export
__class.DamageCalculate = DamageCalculate