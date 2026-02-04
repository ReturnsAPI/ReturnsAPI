-- Callback

Callback = new_class()

run_once(function()
    __callback_cache            = CallbackCache.new()
    __custom_callback_cache     = FindCache.new()
    __custom_callback_counter   = 0
end)

local callback_arg_types = {}



-- ========== Constants and Enums ==========

--@section Constants

--@constants
--[[
ON_LOAD                             0
POST_LOAD                           1
ON_STEP                             2
PRE_STEP                            3
POST_STEP                           4
ON_DRAW                             5
PRE_HUD_DRAW                        6
ON_HUD_DRAW                         7
POST_HUD_DRAW                       8
CAMERA_ON_VIEW_CAMERA_UPDATE        9
ON_SCREEN_REFRESH                   10
ON_GAME_START                       11
ON_GAME_END                         12
ON_DIRECTOR_POPULATE_SPAWN_ARRAYS   13
ON_STAGE_START                      14
ON_SECOND                           15
ON_MINUTE                           16
ON_ATTACK_CREATE                    17
ON_ATTACK_HIT                       18
ON_ATTACK_HANDLE_START              19
ON_ATTACK_HANDLE_END                20
ON_DAMAGE_BLOCKED                   21
ON_ENEMY_INIT                       22
ON_ELITE_INIT                       23
ON_DEATH                            24
ON_PLAYER_INIT                      25
ON_PLAYER_STEP                      26
PRE_PLAYER_HUD_DRAW                 27
ON_PLAYER_HUD_DRAW                  28
ON_PLAYER_INVENTORY_UPDATE          29
ON_PLAYER_DEATH                     30
ON_CHECKPOINT_RESPAWN               31
ON_INPUT_PLAYER_DEVICE_UPDATE       32
ON_PICKUP_COLLECTED                 33
ON_PICKUP_ROLL                      34
ON_EQUIPMENT_USE                    35
POST_EQUIPMENT_USE                  36
ON_INTERACTABLE_ACTIVATE            37
ON_HIT_PROC                         38
ON_DAMAGED_PROC                     39
ON_KILL_PROC                        40
NET_MESSAGE_ON_RECEIVED             41
CONSOLE_ON_COMMAND                  42
]]

local callback_constants = {
    "ON_LOAD", "POST_LOAD", "ON_STEP", "PRE_STEP", "POST_STEP",
    "ON_DRAW", "PRE_HUD_DRAW", "ON_HUD_DRAW", "POST_HUD_DRAW", "CAMERA_ON_VIEW_CAMERA_UPDATE",
    "ON_SCREEN_REFRESH", "ON_GAME_START", "ON_GAME_END", "ON_DIRECTOR_POPULATE_SPAWN_ARRAYS",
    "ON_STAGE_START", "ON_SECOND", "ON_MINUTE", "ON_ATTACK_CREATE", "ON_ATTACK_HIT", "ON_ATTACK_HANDLE_START",
    "ON_ATTACK_HANDLE_END", "ON_DAMAGE_BLOCKED", "ON_ENEMY_INIT", "ON_ELITE_INIT", "ON_DEATH", "ON_PLAYER_INIT", "ON_PLAYER_STEP",
    "PRE_PLAYER_HUD_DRAW", "ON_PLAYER_HUD_DRAW", "ON_PLAYER_INVENTORY_UPDATE", "ON_PLAYER_DEATH",
    "ON_CHECKPOINT_RESPAWN", "ON_INPUT_PLAYER_DEVICE_UPDATE", "ON_PICKUP_COLLECTED", "ON_PICKUP_ROLL", "ON_EQUIPMENT_USE", "POST_EQUIPMENT_USE", "ON_INTERACTABLE_ACTIVATE",
    "ON_HIT_PROC", "ON_DAMAGED_PROC", "ON_KILL_PROC",
    "NET_MESSAGE_ON_RECEIVED", "CONSOLE_ON_COMMAND"
}

-- Add to Callback directly (e.g., Callback.ON_DEATH)
for i, v in ipairs(callback_constants) do
    Callback[v] = i - 1
end

-- Generate list of argument types for each callback
for num_id, _ in ipairs(callback_constants) do
    local class_callback = Global.class_callback
    local arg_types = class_callback:get(num_id - 1):get(2)
    callback_arg_types[num_id - 1] = {}
    for i, v in ipairs(arg_types) do
        table.insert(callback_arg_types[num_id - 1], v)
    end
end


--[[
The following are custom callbacks added by ReturnsAPI.
]]

--@constants
--[[
CUSTOM_START    10000
]]
Callback.CUSTOM_START = 10000

--@constants
--[[
ON_HEAL             10000
ON_SHIELD_BREAK     10001
ON_SKILL_ACTIVATE   10002
ON_EQUIPMENT_SWAP   10003
]]
local custom_callbacks = {
    "ON_HEAL",
    "ON_SHIELD_BREAK",
    "ON_SKILL_ACTIVATE",
    "ON_EQUIPMENT_SWAP",
}
for i, v in ipairs(custom_callbacks) do
    Callback[v] = Callback.CUSTOM_START + i - 1
end



--@section Enums

--@enum
Callback.Priority = {
    NORMAL  = 0,
    BEFORE  = 1000,
    AFTER   = -1000
}

Callback.internal.FIRST = 1000000000



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       string
--@param        num_id      | number    | The numerical ID of the callback type (`0` to `42`).
--[[
Returns the string name of the callback type with the given ID.
]]
Callback.get_type_name = function(num_id)
    if num_id >= Callback.CUSTOM_START then
        local t = __custom_callback_cache:get(num_id)
        return t.namespace.."-"..t.identifier
    end

    return callback_constants[num_id + 1]
end


--@static
--@return       Callback
--@param        callback    | number    | The @link {callback type | Callback#constants} to register under.
--@param        fn          | function  | The function to register. <br>The parameters for it depend on the callback type (see below).
--@overload
--@return       Callback
--@param        callback    | number    | The @link {callback type | Callback#constants} to register under.
--@param        priority    | number    | The priority of the function. <br>Higher values run before lower ones; can be negative. <br>`Callback.Priority.NORMAL` (`0`) by default.
--@param        fn          | function  | The function to register. <br>The parameters for it depend on the callback type (see below).
--[[
Registers a function under a callback type.
Returns a Callback wrapper of the unique ID of the registered function.

**Priority Convention**
To allow for a decent amount of space between priorities,
use the enum values in @link {`Callback.Priority` | Callback#Priority}.
If you need to be more specific than that, try to keep a distance of at least `100`.

--@ptable

**Callbacks**
Parameters are listed in order for each callback.
Callback                            | Parameters
| --------------------------------- | ----------
`ON_LOAD`                           | None
`POST_LOAD`                         | None
`ON_STEP`                           | None
`PRE_STEP`                          | None
`POST_STEP`                         | None
`ON_DRAW`                           | None
`PRE_HUD_DRAW`                      | None
`ON_HUD_DRAW`                       | None
`POST_HUD_DRAW`                     | None
`CAMERA_ON_VIEW_CAMERA_UPDATE`      | None
`ON_SCREEN_REFRESH`                 | None
`ON_GAME_START`                     | None
`ON_GAME_END`                       | None
`ON_DIRECTOR_POPULATE_SPAWN_ARRAYS` | None
`ON_STAGE_START`                    | None
`ON_SECOND`                         | `minute` (number) - Current minute on the timer <br>`second` (number) - Current second on the timer
`ON_MINUTE`                         | `minute` (number) - Current minute on the timer <br>`second` (number) - Current second on the timer
`ON_ATTACK_CREATE`                  | `attack_info` (AttackInfo)
`ON_ATTACK_HIT`                     | `hit_info` (HitInfo)
`ON_ATTACK_HANDLE_START`            | `attack_info` (AttackInfo)
`ON_ATTACK_HANDLE_END`              | `attack_info` (AttackInfo)
`ON_DAMAGE_BLOCKED`                 | `actor` (Actor) <br>`?` (?) <br>`?` (number)
`ON_ENEMY_INIT`                     | `actor` (Actor)
`ON_ELITE_INIT`                     | `actor` (Actor)
`ON_DEATH`                          | `actor` (Actor) - The actor that died <br>`out_of_bounds` (bool) - `true` if the actor died by falling out of bounds
`ON_PLAYER_INIT`                    | `player` (Player)
`ON_PLAYER_STEP`                    | `player` (Player)
`PRE_PLAYER_HUD_DRAW`               | `player` (Player) <br>`x` (number) <br>`y` (number)
`ON_PLAYER_HUD_DRAW`                | `player` (Player) <br>`x` (number) <br>`y` (number)
`ON_PLAYER_INVENTORY_UPDATE`        | `player` (Player)
`ON_PLAYER_DEATH`                   | `player` (Player)
`ON_CHECKPOINT_RESPAWN`             | `player` (Player)
`ON_INPUT_PLAYER_DEVICE_UPDATE`     | `?` (number)
`ON_PICKUP_COLLECTED`               | `pickup` (Instance) <br>`actor` (Actor) 
`ON_PICKUP_ROLL`                    | `?` (?)
`ON_EQUIPMENT_USE`                  | `player` (Player) <br>`equipment` (Equipment) <br>`?` (bool) <br>`?` (number)
`POST_EQUIPMENT_USE`                | `player` (Player) <br>`equipment` (Equipment) <br>`?` (bool) <br>`?` (number)
`ON_INTERACTABLE_ACTIVATE`          | `interactable` (Instance) <br>`player` (Player)
`ON_HIT_PROC`                       | `attacker` (Actor) <br>`target` (Actor) <br>`hit_info` (HitInfo)
`ON_DAMAGED_PROC`                   | `actor` (Actor) <br>`hit_info` (HitInfo)
`ON_KILL_PROC`                      | `target` (Actor) <br>`attacker` (Actor)
`NET_MESSAGE_ON_RECEIVED`           | `packet` (Packet) <br>`buffer` (Buffer) <br>`buffer_tell` (number) <br>`player` (Player)
`CONSOLE_ON_COMMAND`                | `command` (string)

**ReturnsAPI Custom Callbacks**
The following are custom callbacks added by ReturnsAPI.
Callback                            | Parameters
| --------------------------------- | ----------
`ON_HEAL`                           | `actor` (Actor) - The actor that is being healed. <br>`amount` (table) - The heal value; access with `.value`. <br><br>Set `amount.value` to change the heal value. <br>This is called *before* healing is applied, and does <br>*not* cover passive health regeneration or Sprouting Egg.
`ON_SHIELD_BREAK`                   | `actor` (Actor) <br>`hit_info` (HitInfo) <br><br>This only runs when the actor loses shield <br>from taking damage, not when setting `shield`.
`ON_SKILL_ACTIVATE`                 | `actor` (Actor) <br>`slot` (number)
`ON_EQUIPMENT_SWAP`                 | `actor` (Actor) <br>`new` (Equipment) <br>`old` (Equipment) <br><br>Runs *before* the equipment is actually set for the actor.
]]
Callback.add = function(NAMESPACE, callback, arg2, arg3)
    -- Throw error if not numerical ID
    if type(callback) ~= "number" then
        log.error("Callback.add: Invalid Callback type", 2)
    end

    -- Throw error if not function
    if  (type(arg2) ~= "function")
    and (type(arg3) ~= "function") then
        log.error("Callback.add: No function provided", 2)
    end

    -- Default priority (0)
    if type(arg2) == "function" then
        return Callback.wrap(__callback_cache:add(arg2, NAMESPACE, 0, callback))
    end

    -- Custom priority
    return Callback.wrap(__callback_cache:add(arg3, NAMESPACE, arg2, callback))
end


--@static
--@return       Callback
--@param        callback    | number    | The @link {callback type | Callback#constants} to register under.
--@param        fn          | function  | The function to register. <br>The parameters for it are `self, other`, followed <br>by parameters of the callback type (see above).
--@overload
--@return       Callback
--@param        callback    | number    | The @link {callback type | Callback#constants} to register under.
--@param        priority    | number    | The priority of the function. <br>Higher values run before lower ones; can be negative. <br>`Callback.Priority.NORMAL` (`0`) by default.
--@param        fn          | function  | The function to register. <br>The parameters for it are `self, other`, followed <br>by parameters of the callback type (see above).
--[[
Variant of @link {`Callback.add` | Callback#add} that passes `self, other`
as the first two arguments to the callback function,
which may have useful context for some callback types.
]]
Callback.add_SO = function(NAMESPACE, callback, arg2, arg3)
    -- Throw error if not numerical ID
    if type(callback) ~= "number" then
        log.error("Callback.add_SO: Invalid Callback type", 2)
    end

    -- Throw error if not function
    if  (type(arg2) ~= "function")
    and (type(arg3) ~= "function") then
        log.error("Callback.add_SO: No function provided", 2)
    end

    -- Default priority (0)
    if type(arg2) == "function" then
        return Callback.wrap(__callback_cache:add(arg2, NAMESPACE, 0, callback, nil, {SO = true}))
    end

    -- Custom priority
    return Callback.wrap(__callback_cache:add(arg3, NAMESPACE, arg2, callback, nil, {SO = true}))
end


--@static
--[[
Removes all registered callbacks functions from your namespace.

Automatically called when you hotload your mod.
]]
Callback.remove_all = function(NAMESPACE)
    __callback_cache:remove_all(NAMESPACE)
end
table.insert(_clear_namespace_functions, Callback.remove_all)



--@static
--@return       Callback
--@param        id          | number    | The callback function ID to wrap.
--[[
Returns a Callback wrapper containing the provided callback function ID.
]]
Callback.wrap = function(id)
    -- Input:   number or Callback wrapper
    -- Wraps:   number
    return make_proxy(Wrap.unwrap(id), metatable_callback)
end



-- ========== Static Methods (Custom Callbacks) ==========

--[[
---

## Static Methods (Custom Callbacks)
]]

--@static
--@return   number
--@param    identifier      | string    | The identifier for the custom callback.
--[[
Creates a new custom callback with the given identifier if it does not already exist,
or returns the existing one if it does.
]]
Callback.new = function(NAMESPACE, identifier)
    if not identifier then log.error("Callback.new: No identifier provided", 2) end

    -- Return existing custom callback if found
    local callback = Callback.find(identifier, NAMESPACE, true)
    if callback then return callback end

    -- Get next usable ID
    local id = Callback.CUSTOM_START + __custom_callback_counter
    __custom_callback_counter = __custom_callback_counter + 1

    -- Add to cache
    __custom_callback_cache:set(
        {
            id          = id,
            namespace   = NAMESPACE,
            identifier  = identifier
        },
        identifier, NAMESPACE, id
    )

    return id
end


--@static
--@return       number or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified custom callback and returns it.
If no namespace is provided, searches in your mod's namespace.
]]
Callback.find = function(identifier, namespace, namespace_is_specified)
    -- Check in find table
    local cached = __custom_callback_cache:get(identifier, namespace, true)
    if cached then return cached.id end

    return nil
end


--@static
--@return       Any or nil
--@param        callback    | number    | The custom callback to call.
--@optional     ...         |           | Optional values to pass to callback functions. <br>No wrapping/unwrapping is done on these <br>since this system is entirely Lua-sided.
--[[
Call a custom callback; this should generally only be done by the custom callback creator.
The return value is whatever the most recent return value of a callback function was.
]]
Callback.call = function(callback, ...)
    if (type(callback) ~= "number") or (callback < Callback.CUSTOM_START) then
        log.error("Callback.call: callback is invalid (must be a custom callback with ID "..Callback.CUSTOM_START.."+)", 2)
    end

    if not __callback_cache.sections[callback] then return end

    local args = table.pack(...)

    -- Call registered functions with wrapped args
    local return_value
    __callback_cache:loop_and_call_functions(function(fn_table)
        local status, ret = pcall(fn_table.fn, table.unpack(args))
        if not status then
            if (ret == nil)
            or (ret == "C++ exception") then ret = "GameMaker error (see above)" end
            log.warning("\n"..fn_table.namespace..": Callback (ID '"..fn_table.id.."') of type '"..(Callback.get_type_name(callback) or callback).."' failed to execute fully.\n"..ret)
        end

        -- Return value
        if ret then return_value = ret end
    end, callback)

    return return_value
end


--@static
--@return       bool
--@param        callback    | number    | The callback to check.
--[[
Returns `true` if there are any callback functions present for the specified type.
You can use this as a check before running any logic for `Callback.call`.
]]
Callback.has_any = function(callback)
    return __callback_cache:section_count(callback) > 0
end



-- ========== Instance Methods ==========

--@section Instance Methods

methods_callback = {

    --@instance
    --@return       function
    --[[
    Removes and returns the registered callback function.
    ]]
    remove = function(self)
        return __callback_cache:remove(self.value)
    end,
    

    --@instance
    --@return       bool
    --[[
    Returns `true` if the callback function is enabled.
    ]]
    is_enabled = function(self)
        local fn_table = __callback_cache.id_lookup[self.value]

        return (fn_table and fn_table.enabled)
            or false
    end,


    --@instance
    --@param        bool        | bool      | `true` - Enable function <br>`false` - Disable function
    --[[
    Toggles the enabled status of the registered callback function.
    ]]
    toggle = function(self, bool)
        if type(bool) ~= "boolean" then log.error("toggle: bool is invalid", 2) end
        return __callback_cache:toggle(self.value, bool)
    end

}



-- ========== Metatables ==========

local wrapper_name = "Callback"

make_table_once("metatable_callback", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return __proxy[proxy] end
        if k == "RAPI" then return wrapper_name end
        
        -- Methods
        if methods_callback[k] then
            return methods_callback[k]
        end
    end,
    

    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end
        
        log.error(wrapper_name.." has no properties to set", 2)
    end,


    __metatable = "RAPI.Wrapper."..wrapper_name
})



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    local callback_type_id = args[1].value
    if not __callback_cache.sections[callback_type_id] then return end

    local wrapped_args = {}

    -- Wrap args (standard callbacks, e.g., `Callback.ON_LOAD`)
    if callback_type_id < #callback_constants then
        local arg_types = callback_arg_types[callback_type_id]  -- From `Global.class_callback[callback_type_id]`
        for i, arg_type in ipairs(arg_types) do

            local arg = Wrap.wrap(args[i + 1].value)
            
            -- Wrap as certain wrappers depending on arg type
            if arg then
                if      arg_type:match("Instance") and arg == -4    then arg = __invalid_instance   -- Wrap as invalid Instance if -4
                elseif  arg_type:match("AttackInfo")                then arg = AttackInfo.wrap(arg) -- Assuming `arg` is a Struct wrapper
                elseif  arg_type:match("HitInfo")                   then arg = HitInfo.wrap(arg)
                elseif  arg_type:match("Equipment")                 then arg = Equipment.wrap(arg)
                end
            end

            -- Packet and Message edge cases (41 - net_message_onReceived)
            if callback_type_id == Callback.NET_MESSAGE_ON_RECEIVED then
                if      i == 1 then arg = Packet.wrap(arg)  -- `nil` if packet ID is not in use
                elseif  i == 2 then arg = Buffer.wrap(arg)
                end
            end
            
            table.insert(wrapped_args, arg)
        end

    -- Wrap args (content callbacks, e.g., `<item>.on_acquired`)
    else
        for i = 2, #args do
            table.insert(wrapped_args, Wrap.wrap(args[i].value))
        end
    end

    -- Call registered functions with wrapped args
    __callback_cache:loop_and_call_functions(function(fn_table)
        local status, ret, wrapped_self, wrapped_other

        -- Standard call
        if not fn_table.data.SO then
            status, ret = pcall(fn_table.fn, table.unpack(wrapped_args))

        -- SO call
        else
            if not wrapped_self  then wrapped_self  = Wrap.wrap(self)  end
            if not wrapped_other then wrapped_other = Wrap.wrap(other) end
            status, ret = pcall(fn_table.fn, wrapped_self, wrapped_other, table.unpack(wrapped_args))
        end

        if not status then
            if (ret == nil)
            or (ret == "C++ exception") then ret = "GameMaker error (see above)" end
            log.warning("\n"..fn_table.namespace..": Callback (ID '"..fn_table.id.."') of type '"..(Callback.get_type_name(callback_type_id) or callback_type_id).."' failed to execute fully.\n"..ret)
        end

        -- Result modification
        if ret then result.value = Wrap.unwrap(ret) end
    end, callback_type_id)
end)



-- ========== RAPI Custom Callbacks ==========

-- 10000 : onHeal
Callback.new(RAPI_NAMESPACE, "onHeal")

Hook.add_pre(RAPI_NAMESPACE, gm.constants.actor_heal_networked, Callback.internal.FIRST, function(self, other, result, args)
    if not Callback.has_any(Callback.ON_HEAL) then return end

    -- Runs for both host and client, but value modification does nothing for client
    local actor  = args[1].value
    local amount = { value = args[2].value } -- Allows for passing modification to next callback function

    Callback.call(Callback.ON_HEAL, actor, amount)
    args[2].value = amount.value
end)

-- For effects that use `lifesteal` (e.g., Leeching Seed)
-- Hooks line 30.5 (between `var amount =` and `actor_heal_raw` call)
local ptr = gm.get_script_function_address(gm.constants.damager_proc_posthit_clientandserver)
memory.dynamic_hook_mid("RAPI.Callback.damager_proc_posthit_clientandserver", {"r12", "rbp-D0h"}, {"RValue**", "RValue*"}, 0, ptr:add(0x1172), function(args)
    if not Callback.has_any(Callback.ON_HEAL) then return end
    
    local actor  = Instance.wrap(memory.resolve_pointer_to_type(args[1]:deref():get_address(), "RValue*").value)
    local amount = { value = args[2].value } -- Allows for passing modification to next callback function

    Callback.call(Callback.ON_HEAL, actor, amount)
    args[2].value = amount.value
end)

-- For effects that use `oEfHeal2Nosync` (e.g., Monster Tooth)
-- Hooks line 22 (right after `place_meeting` check)
local ptr = gm.get_object_function_address("gml_Object_oEfHeal2Nosync_Step_2")
memory.dynamic_hook_mid("RAPI.Callback.gml_Object_oEfHeal2Nosync_Step_2_2", {"r14", "rbp-D0h"}, {"RValue*", "RValue*"}, 0, ptr:add(0x1155), function(args)
    if not Callback.has_any(Callback.ON_HEAL) then return end
    
    local actor  = Instance.wrap(args[1].value)
    local oHeal  = args[2].value
    local amount = { value = oHeal.value }  -- Allows for passing modification to next callback function
                                            -- `.value` here is the heal value

    Callback.call(Callback.ON_HEAL, actor, amount)
    oHeal.value = amount.value
end)


-- 10001 : onShieldBreak
Callback.new(RAPI_NAMESPACE, "onShieldBreak")

Callback.add(RAPI_NAMESPACE, Callback.ON_DAMAGED_PROC, Callback.internal.FIRST, function(actor, hit_info)
    if not Callback.has_any(Callback.ON_SHIELD_BREAK) then return end

    -- Check for shield break
    local actor_data = Instance.get_data(actor)
    if actor.shield <= 0 then
        if actor_data.shield_active then
            actor_data.shield_active = false
            Callback.call(Callback.ON_SHIELD_BREAK, actor, hit_info)
        end
    else actor_data.shield_active = true
    end
end)


-- 10002 : onSkillActivate
Callback.new(RAPI_NAMESPACE, "onSkillActivate")

Hook.add_post(RAPI_NAMESPACE, gm.constants.skill_activate, Callback.internal.FIRST, function(self, other, result, args)
    if not Callback.has_any(Callback.ON_SKILL_ACTIVATE) then return end

    local actor = self
    local slot  = args[1].value

    Callback.call(Callback.ON_SKILL_ACTIVATE, actor, slot)
end)


-- 10003 : onEquipmentSwap
Callback.new(RAPI_NAMESPACE, "onEquipmentSwap")

Hook.add_pre(RAPI_NAMESPACE, gm.constants.equipment_set, Callback.internal.FIRST, function(self, other, result, args)
    if not Callback.has_any(Callback.ON_EQUIPMENT_SWAP) then return end

    local actor = args[1].value
    local new   = (args[2].value ~= -1 and Equipment.wrap(args[2].value)) or nil
    local old   = actor:equipment_get()

    Callback.call(Callback.ON_EQUIPMENT_SWAP, actor, new, old)
end)



__class.Callback = Callback