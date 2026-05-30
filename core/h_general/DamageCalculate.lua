-- DamageCalculate

--[[
This class provides a way to modify `attack_info` structs on-hit *before* they are applied to the target.
]]
---@class DamageCalculateClass
DamageCalculate = new_class()
C.DamageCalculate = DamageCalculate

run_on_initial_load(function()
    P.damage_calc_functions = CallbackTable.new()
end)

local damage_calc_functions = P.damage_calc_functions

local type            = type
local ceil            = math.ceil
local resolve_pointer = memory.resolve_pointer_to_type  ---@type function
local unwrap          = Wrap.unwrap


-- ========== Internal ==========

local params = {}

local function reset_params()
    params.damage_true = 1
    params.damage_fake = 1
end

-- Original arguments from hooked function
local hook_args  -- Argument array; fetched from most recent midhook call
local hook_args_names = table.enum({
    "hit_info",   "true_hit", "hit",   "damage",
    "critical",   "parent",   "proc",  "attack_flags",
    "damage_col", "team",     "climb", "percent_hp",
    "xscale",     "hit_x",    "hit_y",
}, 0)

local resolved_hook_args  -- Reset at start of most recent midhook call

-- Get *n*th arg from argument array, indexed from `0`.
---@return sol.RValue*
local function get_hook_arg(n)
    -- Dereference correct address and resolve
    -- Move up 8 bytes to go to next arg
    -- Store result so it doesn't need re-resolving
    local result = resolved_hook_args[n]
    if not result then
        result = resolve_pointer(hook_args:add(n * 8):deref():get_address(), "RValue*")
        resolved_hook_args[n] = result
    end
    return result
end


-- ========== Static Methods ==========

--[[
Registers a function for modifying damage calculation. <br>
The function runs for both host and client. <br>
Returns the unique ID of the registered function.
]]
---@param fn fun(api: DamageCalculate) The function to register. <br>The parameter for it is `api`.
---@return number
DamageCalculate.add = function(NAMESPACE, fn) end

--[[
Registers a function for modifying damage calculation. <br>
The function runs for both host and client. <br>
Returns the unique ID of the registered function.

**Priority Convention** <br>
To allow for a decent amount of space between priorities, <br>
use the enum values in @link {`Callback.Priority` | Callback#Priority}. <br>
If you need to be more specific than that, try to keep a distance of at least `100`.
]]
---@param priority number The priority of the function. <br>Higher values run before lower ones; can be negative. <br>`Callback.Priority.NORMAL` (`0`) by default.
---@param fn fun(api: DamageCalculate) The function to register. <br>The parameter for it is `api`.
---@return number
DamageCalculate.add = function(NAMESPACE, priority, fn)
    if type(priority) == "function" then
        return damage_calc_functions:add(priority, NAMESPACE)
    end
    return damage_calc_functions:add(fn, NAMESPACE, priority)
end

--[[
Removes and returns a registered damage calculation function. <br>
The ID is the one from @link {`DamageCalculate.add` | DamageCalculate#add}.
]]
---@param id number The unique ID of the registered function to remove.
---@return function | nil
DamageCalculate.remove = function(id)
    return damage_calc_functions:remove(id)
end

--[[
Removes all registered damage calculation functions from your namespace.

Automatically called when you hotload your mod.
]]
DamageCalculate.remove_all = function(NAMESPACE)
    damage_calc_functions:remove_all(NAMESPACE)
end
run_on_import(DamageCalculate.remove_all)


-- ========== Wrapper Methods ==========

---@class DamageCalculate
local methods = {}

--[[
Multiplies damage by `value`.

If `update_damage_number` is `false`, the damage number will <br>
not be updated; instead, the difference between the new and old <br>
damage will be returned, which can be manually drawn.
]]
---@param value number The damage multiplier. <br>`1` leaves damage unchanged.
---@param update_damage_number? boolean Whether or not to update the damage number. <br>`true` by default.
methods.damage_mult = function(value, update_damage_number)
    local prev_damage = api.damage
    api.damage = api.damage * value
    params.damage_true = params.damage_true * value

    -- Update damage number
    if update_damage_number ~= false then
        params.damage_fake = params.damage_fake * value

    -- Otherwise, return difference between current and previous damage
    -- This value can then be drawn separately
    else
        return ceil(api.damage - prev_damage)
    end
end

--[[
Sets the critical hit state of the attack.
]]
---@param bool boolean If `true`, the attack will be a critical hit. <br>If `false`, the attack will not crit.
methods.set_critical = function(bool)
    if bool == nil then throw("Missing bool argument") end

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


-- ========== Metatables ==========

---@class DamageCalculate
---@field hit_info      Struct   The `hit_info` struct. <br>May not exist. <br>Does not exist for clients.
---@field true_hit      Actor    The actual instance hit. <br>May be different from `hit` (i.e., a worm segment).
---@field hit           Actor    The actor that was hit.
---@field damage        number   The damage of the attack.
---@field critical      boolean  `true` if the attack is a critical hit.
---@field parent        Actor    The parent actor of the attack.
---@field proc          boolean  `true` if the attack can proc.
---@field attack_flags  number   The @link {attack flags | AttackFlag#constants} of the attack.
---@field damage_col    number   The damage color.
---@field team          number   The team the attack belongs to.
---@field climb         number   
---@field percent_hp    number   If non-`0`, the minimum damage of the attack is <br>`percent_hp`% of the actor's current health.
---@field xscale        number   
---@field hit_x         number   The x coordinate the attack hit.
---@field hit_y         number   The y coordinate the attack hit.

local mt_name = "DamageCalculate"

W.DamageCalculate = {
    __index = function(t, k)
        -- Get original function arguments
        local arg_num = hook_args_names[k]
        if arg_num then
            return get_hook_arg(arg_num).value
        end

        -- Methods
        local method = methods[k]
        if method then return method end

        log.error(mt_name.." has no property or method '"..k.."'", 2)
    end,

    __newindex = function(t, k, v)
        -- Set original function arguments
        local arg_num = hook_args_names[k]
        if arg_num then
            get_hook_arg(arg_num).value = unwrap(v)
            return
        end

        log.error(mt_name.." has no property '"..k.."' to set", 2)
    end,

    __metatable = mt_wrapper_name(mt_name),
}

-- Make single instance of wrapper

---@type DamageCalculate
local api = setmetatable({}, W.DamageCalculate)


-- ========== Hooks ==========

local ptr = gm.get_script_function_address(gm.constants.damager_calculate_damage)

-- Hooks line 105 (right before `draw_damage` call)
memory.dynamic_hook_mid("RAPI.DamageCalculate.damager_calculate_damage", {"r14", "rbp+60h", "rbp+180h"}, {"RValue**", "RValue*", "RValue*"}, 0, ptr:add(0x30E0), function(args)
    -- Store argument array pointer
    hook_args = args[1]
    resolved_hook_args = {}
    
    -- Reset `params` table
    reset_params()

    -- Call registered functions
    for i = 1, #damage_calc_functions do
        local data = damage_calc_functions[i]
        if data.enabled then
            local status, out = pcall(data.fn, api)
            if not status then
                if out == nil
                or out == "C++ exception" then
                    out = "GameMaker error (see above)"
                end
                log.warning("\n| "..data.namespace..": Error in damage calculate function (ID "..math.floor(data.id)..")\n| "..out)
            end
        end
    end

    -- damage (round up)
    api.damage = ceil(api.damage)


    -- ===== Apply params =====
    -- Only need to do this for local variables in the function
    -- Anything that was part of the original arguments
    -- can be get/set directly via `api.<argument>` etc. `api.damage`

    -- damage_true
    args[2].value = ceil(args[2].value * params.damage_true)

    -- damage_fake
    args[3].value = ceil(args[3].value * params.damage_fake)
end)