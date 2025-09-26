-- DamageDodge

DamageDodge = new_class()

run_once(function()
    __damage_dodge_cache = CallbackCache.new()
end)



-- ========== Constants ==========

--@section Constants

--[[
`IMMUNE` will read as "INVINCIBLE" if an actor's immunity frames are over 1000.
]]

--@constants
--[[
NONE        0
IMMUNE      1
EVADED      2
BLOCKED     3
DEFLECTED   4
]]

local dodge_constants = {
    NONE        = 0,
    IMMUNE      = 1,
    EVADED      = 2,
    BLOCKED     = 3,
    DEFLECTED   = 4
}

-- Add to DamageDodge directly (e.g., DamageDodge.IMMUNE)
for k, v in pairs(dodge_constants) do
    DamageDodge[k] = v
end



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       number
--@param        fn          | function  | The function to register. <br>The parameter for it is `api, current_dodge`.
--@overload
--@return       number
--@param        priority    | number    | The priority of the function. <br>Higher values run before lower ones; can be negative. <br>`Callback.Priority.NORMAL` (`0`) by default.
--@param        fn          | function  | The function to register. <br>The parameter for it is `api, current_dodge`.
--[[
Registers a function that runs whenever actor attack evasion/blocking is checked.
The function runs for both host and client.
Returns the unique ID of the registered function.

**Priority Convention**
To allow for a decent amount of space between priorities,
use the enum values in @link {`Callback.Priority` | Callback#Priority}.
If you need to be more specific than that, try to keep a distance of at least `100`.
]]
DamageDodge.add = function(NAMESPACE, arg1, arg2)
    if type(arg1) == "function" then
        return __damage_dodge_cache:add(arg1, NAMESPACE)
    end
    return __damage_dodge_cache:add(arg2, NAMESPACE, arg1)
end


--@static
--@name         remove
--@param        id          | number    | The unique ID of the registered function to remove.
--[[
Removes a registered DamageDodge function.
The ID is the one from @link {`DamageDodge.add` | DamageDodge#add}.
]]
DamageDodge.remove = function(id)
    return __damage_dodge_cache:remove(id)
end


--@static
--[[
Removes all registered DamageDodge functions from your namespace.

Automatically called when you hotload your mod.
]]
DamageDodge.remove_all = function(NAMESPACE)
    __damage_dodge_cache:remove_all(NAMESPACE)
end
table.insert(_clear_namespace_functions, DamageDodge.remove_all)



-- ========== Internal ==========

--@section `api`

--[[
### Properties
These can all be get/set to.
Property | Type | Description
| - | - | -
`hit`           | Actor     | The actor being hit.
`attacker_x`    | number    | The x position of the attacker.
`damage`        | number    | The damage of the attack.
`ignore_immune` | bool      | If `true`, ignore immunity (i.e., if `DamageDodge.IMMUNE` is used).

<br>

### Forcing a dodge
Return a @link {DamageDodge constant | DamageDodge#Constants}.
If `DamageDodge.NONE` is returned, existing evasion will be removed.
]]


local params = {}

-- Original arguments from hooked function
local hook_args     -- Set by current hook call
local hook_args_names = {
    hit             = 0,
    attacker_x      = 1,
    damage          = 2,
    ignore_immune   = 3
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

local api = setmetatable({}, {
    __index = function(t, k)
        -- Get original function arguments
        local arg_num = hook_args_names[k]
        if arg_num then
            return Wrap.wrap(get_hook_arg(arg_num).value)
        end

        log.error("api has no property '"..k.."'", 2)
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

    __metatable = "RAPI.DamageDodge.api"
})

local function reset_params()
    params.damage_true = 1
    params.damage_fake = 1
end



-- ========== Hooks ==========

local ptr = gm.get_script_function_address(gm.constants.damage_get_dodge)

-- Hooks line 105 (right before `draw_damage` call)
memory.dynamic_hook_mid("RAPI.DamageDodge.damage_get_dodge", {"r14", "rbp-68h", "rbp-58h", "rbp-48h"}, {"RValue**", "RValue*", "RValue*", "RValue*"}, 0, ptr:add(0x7DA), function(args)
    -- Store argument array pointer
    hook_args = args[1]
    resolved_hook_args = {}
    
    -- Reset `params` table
    reset_params()

    -- Current evasion status
    -- Pass to all functions
    -- (Check is taken from `damage_get_dodge`)
    local current_dodge = DamageDodge.NONE

    if Util.bool(args[2].value) then
        current_dodge = DamageDodge.BLOCKED
    elseif Util.bool(args[3].value) then
        current_dodge = DamageDodge.DEFLECTED
    elseif args[4].value == 2 then
        current_dodge = DamageDodge.EVADED
    elseif ((args[4].value == 1) and (not Util.bool(get_hook_arg(3).value))) then
        current_dodge = DamageDodge.IMMUNE
    end

    -- Call registered functions with wrapped arg
    __damage_dodge_cache:loop_and_call_functions(function(fn_table)
        local status, ret = pcall(fn_table.fn, api, current_dodge)
        if not status then
            if (ret == nil)
            or (ret == "C++ exception") then ret = "GameMaker error (see above)" end
            log.warning("\n"..fn_table.namespace..": DamageDodge (ID '"..fn_table.id.."') failed to execute fully.\n"..ret)
        end

        -- Process return value
        if      ret == DamageDodge.NONE then
            args[2].value = false   -- _blocked
            args[3].value = false   -- _parry
            args[4].value = 0       -- _invincible
            current_dodge = ret

        elseif  ret == DamageDodge.IMMUNE then
            args[2].value = false   -- _blocked
            args[3].value = false   -- _parry
            args[4].value = 1       -- _invincible
            current_dodge = ret

        elseif  ret == DamageDodge.EVADED then
            args[2].value = false   -- _blocked
            args[3].value = false   -- _parry
            args[4].value = 2       -- _invincible
            current_dodge = ret

        elseif  ret == DamageDodge.BLOCKED then
            args[2].value = true    -- _blocked
            current_dodge = ret

        elseif  ret == DamageDodge.DEFLECTED then
            args[2].value = false   -- _blocked
            args[3].value = true    -- _parry
            current_dodge = ret
            
        end
    end)
end)



-- Public export
__class.DamageDodge = DamageDodge