-- DamageDodge

---@class DamageDodgeClass
DamageDodge = new_class()
C.DamageDodge = DamageDodge

run_on_initial_load(function()
    P.damage_dodge_functions = CallbackTable.new()
end)

local damage_dodge_functions = P.damage_dodge_functions

local type            = type
local resolve_pointer = memory.resolve_pointer_to_type  ---@type function
local to_bool         = Util.bool
local unwrap          = Wrap.unwrap


-- ========== Constants ==========

DamageDodge.NONE      = 0
DamageDodge.IMMUNE    = 1  -- Will display "INVINCIBLE" if the actor's immunity frames are over 1000.
DamageDodge.EVADED    = 2
DamageDodge.BLOCKED   = 3
DamageDodge.DEFLECTED = 4  -- Will play the sound effect used for Mercenary's Focused Strike.


-- ========== Internal ==========

-- Original arguments from hooked function
local hook_args  -- Argument array; fetched from most recent midhook call
local hook_args_names = table.enum({
    "hit", "attacker_x", "damage", "ignore_immune"
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
Registers a function that runs whenever actor attack evasion/blocking is checked. <br>
The function runs for both host and client. <br>
Returns the unique ID of the registered function.
]]
---@param fn fun(api: DamageDodge, current_dodge: number) The function to register. <br>The parameters for it are `api, current_dodge`. <br>The function should return a `DamageDodge` constant to change the dodge type.
---@return number
DamageDodge.add = function(NAMESPACE, fn) end

--[[
Registers a function that runs whenever actor attack evasion/blocking is checked. <br>
The function runs for both host and client. <br>
Returns the unique ID of the registered function.

**Priority Convention** <br>
To allow for a decent amount of space between priorities, <br>
use the enum values in @link {`Callback.Priority` | Callback#Priority}. <br>
If you need to be more specific than that, try to keep a distance of at least `100`.
]]
---@param priority number The priority of the function. <br>Higher values run before lower ones; can be negative. <br>`Callback.Priority.NORMAL` (`0`) by default.
---@param fn fun(api: DamageDodge, current_dodge: number) The function to register. <br>The parameters for it are `api, current_dodge`. <br>The function should return a `DamageDodge` constant to change the dodge type.
---@return number
DamageDodge.add = function(NAMESPACE, priority, fn)
    if type(priority) == "function" then
        return damage_dodge_functions:add(priority, NAMESPACE)
    end
    return damage_dodge_functions:add(fn, NAMESPACE, priority)
end

--[[
Removes and returns a registered DamageDodge function. <br>
The ID is the one from @link {`DamageDodge.add` | DamageDodge#add}.
]]
---@param id number The unique ID of the registered function to remove.
---@return function | nil
DamageDodge.remove = function(id)
    return damage_dodge_functions:remove(id)
end

--[[
Removes all registered DamageDodge functions from your namespace.

Automatically called when you hotload your mod.
]]
DamageDodge.remove_all = function(NAMESPACE)
    damage_dodge_functions:remove_all(NAMESPACE)
end
run_on_import(DamageDodge.remove_all)


-- ========== Metatables ==========

---@class DamageDodge
---@field hit            Actor   The actor being hit.
---@field attacker_x     number  The x position of the attacker.
---@field damage         number  The damage of the attack.
---@field ignore_immune  bool    If `true`, ignore immunity (i.e., if `DamageDodge.IMMUNE` is used).

local mt_name = "DamageDodge"

W.DamageDodge = {
    __index = function(t, k)
        -- Get original function arguments
        local arg_num = hook_args_names[k]
        if arg_num then
            return get_hook_arg(arg_num).value
        end

        log.error(mt_name.." has no property '"..k.."'", 2)
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

---@type DamageDodge
local api = setmetatable({}, W.DamageDodge)


-- ========== Hooks ==========

local ptr = gm.get_script_function_address(gm.constants.damage_get_dodge)

-- Hooks line 105 (right before `draw_damage` call)
memory.dynamic_hook_mid("RAPI.DamageDodge.damage_get_dodge", {"r14", "rbp-68h", "rbp-58h", "rbp-48h"}, {"RValue**", "RValue*", "RValue*", "RValue*"}, 0, ptr:add(0x7DA), function(args)
    -- Store argument array pointer
    hook_args = args[1]
    resolved_hook_args = {}

    -- Current evasion status
    -- Pass to all functions
    -- (Check is taken from `damage_get_dodge`)
    local current_dodge = DamageDodge.NONE

    if to_bool(args[2].value) then
        current_dodge = DamageDodge.BLOCKED
    elseif to_bool(args[3].value) then
        current_dodge = DamageDodge.DEFLECTED
    elseif args[4].value == 2 then
        current_dodge = DamageDodge.EVADED
    elseif ((args[4].value == 1) and (not to_bool(get_hook_arg(3).value))) then
        current_dodge = DamageDodge.IMMUNE
    end

    -- Call registered functions
    for i = 1, #damage_dodge_functions do
        local data = damage_dodge_functions[i]
        if data.enabled then
            local status, out = pcall(data.fn, api, current_dodge)
            if not status then
                if out == nil
                or out == "C++ exception" then
                    out = "GameMaker error (see above)"
                end
                log.warning("\n| "..data.namespace..": Error in damage dodge function (ID "..math.floor(data.id)..")\n| "..out)
            end

            -- Process return value
            if     out == DamageDodge.NONE then
                args[2].value = false  -- _blocked
                args[3].value = false  -- _parry
                args[4].value = 0      -- _invincible
                current_dodge = ret

            elseif out == DamageDodge.IMMUNE then
                args[2].value = false  -- _blocked
                args[3].value = false  -- _parry
                args[4].value = 1      -- _invincible
                current_dodge = ret

            elseif out == DamageDodge.EVADED then
                args[2].value = false  -- _blocked
                args[3].value = false  -- _parry
                args[4].value = 2      -- _invincible
                current_dodge = ret

            elseif out == DamageDodge.BLOCKED then
                args[2].value = true   -- _blocked
                current_dodge = ret

            elseif out == DamageDodge.DEFLECTED then
                args[2].value = false  -- _blocked
                args[3].value = true   -- _parry
                current_dodge = ret
            end
        end
    end
end)