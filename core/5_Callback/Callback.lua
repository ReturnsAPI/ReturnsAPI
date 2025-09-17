-- Callback

Callback = new_class()

run_once(function()
    __callback_cache = CallbackCache.new()
end)

local callback_arg_types = {}



-- ========== Constants and Enums ==========

--@section Constants

--@constants
--[[
ON_LOAD 0
POST_LOAD 1
ON_STEP 2
PRE_STEP 3
POST_STEP 4
ON_DRAW 5
PRE_HUD_DRAW 6
ON_HUD_DRAW 7
POST_HUD_DRAW 8
CAMERA_ON_VIEW_CAMERA_UPDATE 9
ON_SCREEN_REFRESH 10
ON_GAME_START 11
ON_GAME_END 12
ON_DIRECTOR_POPULATE_SPAWN_ARRAYS 13
ON_STAGE_START 14
ON_SECOND 15
ON_MINUTE 16
ON_ATTACK_CREATE 17
ON_ATTACK_HIT 18
ON_ATTACK_HANDLE_START 19
ON_ATTACK_HANDLE_END 20
ON_DAMAGE_BLOCKED 21
ON_ENEMY_INIT 22
ON_ELITE_INIT 23
ON_DEATH 24
ON_PLAYER_INIT 25
ON_PLAYER_STEP 26
PRE_PLAYER_HUD_DRAW 27
ON_PLAYER_HUD_DRAW 28
ON_PLAYER_INVENTORY_UPDATE 29
ON_PLAYER_DEATH 30
ON_CHECKPOINT_RESPAWN 31
ON_INPUT_PLAYER_DEVICE_UPDATE 32
ON_PICKUP_COLLECTED 33
ON_PICKUP_ROLL 34
ON_EQUIPMENT_USE 35
POST_EQUIPMENT_USE 36
ON_INTERACTABLE_ACTIVATE 37
ON_HIT_PROC 38
ON_DAMAGED_PROC 39
ON_KILL_PROC 40
NET_MESSAGE_ON_RECEIVED 41
CONSOLE_ON_COMMAND 42
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


--@section Enums

--@enum
Callback.Priority = {
    NORMAL  = 0,
    BEFORE  = 1000,
    AFTER   = -1000
}



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       string
--@param        num_id      | number    | The numerical ID of the callback type (`0` to `42`).
--[[
Returns the string name of the callback type with the given ID.
]]
Callback.get_type_name = function(num_id)
    if num_id < 0 or num_id >= #callback_constants then return nil end
    return callback_constants[num_id + 1]
end


--@static
--@return       number
--@param        callback    | number    | The @link {callback type | Callback#constants} to register under.
--@param        fn          | function  | The function to register. <br>The parameters for it depend on the callback type (see below).
--@optional     priority    | number    | The priority of the function. <br>Higher values run before lower ones; can be negative. <br>`Callback.Priority.NORMAL` (`0`) by default.
--[[
Registers a function under a callback type.
Returns the unique ID of the registered function.

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
`ON_ATTACK_CREATE`                  | 
`ON_ATTACK_HIT`                     | 
`ON_ATTACK_HANDLE_START`            | 
`ON_ATTACK_HANDLE_END`              | 
`ON_DAMAGE_BLOCKED`                 | 
`ON_ENEMY_INIT`                     | 
`ON_ELITE_INIT`                     | 
`ON_DEATH`                          | `actor` (Actor) - The actor that died <br>`out_of_bounds` (bool) - `true` if the actor died by falling out of bounds
`ON_PLAYER_INIT`                    | 
`ON_PLAYER_STEP`                    | 
`PRE_PLAYER_HUD_DRAW`               | 
`ON_PLAYER_HUD_DRAW`                | 
`ON_PLAYER_INVENTORY_UPDATE`        | 
`ON_PLAYER_DEATH`                   | 
`ON_CHECKPOINT_RESPAWN`             | 
`ON_INPUT_PLAYER_DEVICE_UPDATE`     | 
`ON_PICKUP_COLLECTED`               | 
`ON_PICKUP_ROLL`                    | 
`ON_EQUIPMENT_USE`                  | 
`POST_EQUIPMENT_USE`                | 
`ON_INTERACTABLE_ACTIVATE`          | 
`ON_HIT_PROC`                       | 
`ON_DAMAGED_PROC`                   | 
`ON_KILL_PROC`                      | 
`NET_MESSAGE_ON_RECEIVED`           | 
`CONSOLE_ON_COMMAND`                | 
]]
Callback.add = function(namespace, callback, fn, priority)
    -- Throw error if not numerical ID
    if type(callback) ~= "number" then
        log.error("Callback.add: Invalid Callback type", 2)
    end

    -- Throw error if not function
    if type(fn) ~= "function" then
        log.error("Callback.add: No function provided", 2)
    end

    return __callback_cache:add(fn, namespace, priority, callback)
end


--@static
--@name         remove
--@param        id          | number    | The unique ID of the registered function to remove.
--[[
Removes a registered callback function.
The ID is the one from @link {`Callback.add` | Callback#add}.
]]
Callback.remove = function(id)
    return __callback_cache:remove(id)
end


--@static
--@name         remove_all
--[[
Removes all registered callbacks functions from your namespace.

Automatically called when you hotload your mod.
]]
Callback.remove_all = function(namespace)
    __callback_cache:remove_all(namespace)
end
table.insert(_clear_namespace_functions, Callback.remove_all)



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
                if      i == 1 then arg = Packet.wrap(arg)
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
        local status, err = pcall(fn_table.fn, table.unpack(wrapped_args))
        if not status then
            if (err == nil)
            or (err == "C++ exception") then err = "GM call error (see above)" end
            log.warning("\n"..fn_table.namespace:gsub("%.", "-")..": Callback of type '"..callback_type_id.."' failed to execute fully.\n"..err)
        end
    end, callback_type_id)
end)



__class.Callback = Callback