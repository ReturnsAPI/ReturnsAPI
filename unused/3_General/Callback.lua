-- Callback

Callback = new_class()

local callback_bank = {}
local id_counter = 0
local id_lookup = {}

-- local callback_list = {
--     "onLoad", "postLoad", "onStep", "preStep", "postStep",
--     "onDraw", "preHUDDraw", "onHUDDraw", "postHUDDraw", "camera_onViewCameraUpdate",
--     "onScreenRefresh", "onGameStart", "onGameEnd", "onDirectorPopulateSpawnArrays",
--     "onStageStart", "onSecond", "onMinute", "onAttackCreate", "onAttackHit", "onAttackHandleStart",
--     "onAttackHandleEnd", "onDamageBlocked", "onEnemyInit", "onEliteInit", "onDeath", "onPlayerInit", "onPlayerStep",
--     "prePlayerHUDDraw", "onPlayerHUDDraw", "onPlayerInventoryUpdate", "onPlayerDeath",
--     "onCheckpointRespawn", "onInputPlayerDeviceUpdate", "onPickupCollected", "onPickupRoll", "onEquipmentUse", "postEquipmentUse", "onInteractableActivate",
--     "onHitProc", "onDamagedProc", "onKillProc",
--     "net_message_onReceived", "console_onCommand"
-- }

local callback_arg_types = {}



-- ========== Constants and Enums ==========

--$constants
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


--$enum
Callback.Priority = ReadOnly.new({
    BEFORE  = 1000,
    AFTER   = -1000
})



-- ========== Static Methods ==========

--$static
--$return       string
--$param        num_id      | number    | The numerical ID of the callback type.
--[[
Returns the string name of the callback type with the given ID.
]]
Callback.get_type_name = function(num_id)
    if num_id < 0 or num_id >= #callback_constants then log.error("Invalid Callback numID", 2) end
    return callback_constants[num_id + 1]
end


--$static
--$return       number
--$param        callback    | number    | The $callback type, Callback#constants$ to register under.
--$param        fn          | function  | The function to register. <br>The parameters for it depend on the callback type (see below).
--$optional     priority    | number    | The priority of the function. <br>Higher values run before lower ones; can be negative. <br>`0` by default.
--[[
Registers a function under a callback type.
Returns the unique ID of the registered callback.

**Convention**
To allow for a decent amount of space between priorities,
use the enum values in $`Callback.Priority`, Callback#Priority$.
If you need to be more specific than that, try to keep a distance of at least `100`.

--$ptable

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
`ON_DEATH`                          | 
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
        log.error("Invalid Callback type", 2)
    end

    -- All callbacks have the same priority (0) unless specified
    -- Higher numbers run before lower ones (can be negative)
    priority = priority or 0

    -- Create callback_bank subtables if they do not exist
    if not callback_bank[callback] then
        callback_bank[callback] = {}
        callback_bank[callback].priorities = {}
    end
    local cbank_callback = callback_bank[callback]
    if not cbank_callback[priority] then
        cbank_callback[priority] = {}
        table.insert(cbank_callback.priorities, priority)
        table.sort(cbank_callback.priorities, function(a, b) return a > b end)
    end

    -- Add to subtable
    id_counter = id_counter + 1

    local fn_table = {
        id          = id_counter,
        namespace   = namespace,
        fn          = fn,
        priority    = priority
    }
    local lookup_table = {callback, fn_table}
    id_lookup[id_counter] = lookup_table
    table.insert(callback_bank[callback][priority], fn_table)

    return id_counter
end


--$static
--$param        id          | number    | The unique ID of the registered callback to remove.
--[[
Removes a registered callback function.
The ID is the one from $`Callback.add`, Callback#add$.
]]
Callback.remove = function(id)
    local lookup_table = id_lookup[id]
    if not lookup_table then return end
    id_lookup[id] = nil

    local cbank_callback = callback_bank[lookup_table[1]]
    for priority, cbank_priority in pairs(cbank_callback) do
        if type(priority) == "number" then
            for i, v in ipairs(cbank_priority) do
                if v == lookup_table[2] then
                    table.remove(cbank_priority, i)
                    break
                end
            end
            if #cbank_priority <= 0 then
                cbank_callback[priority] = nil
                Util.table_remove_value(cbank_callback.priorities, priority)
            end
        end
    end
end


--$static
--[[
Removes all registered callbacks functions from your namespace.
]]
Callback.remove_all = function(namespace)
    for _, cbank_callback in pairs(callback_bank) do
        for priority, cbank_priority in pairs(cbank_callback) do
            if type(priority) == "number" then
                for i = #cbank_priority, 1, -1 do
                    local fn_table = cbank_priority[i]
                    if fn_table.namespace == namespace then
                        id_lookup[fn_table.id] = nil
                        table.remove(cbank_priority, i)
                    end
                end
                if #cbank_priority <= 0 then
                    cbank_callback[priority] = nil
                    Util.table_remove_value(cbank_callback.priorities, priority)
                end
            end
        end
    end
end



-- ========== Internal ==========

-- Generate list of argument types for each callback
local callback_type_array = gm.variable_global_get("class_callback")
-- local str = ""

for num_id, _ in ipairs(callback_constants) do
    local arg_types = gm.array_get(gm.array_get(callback_type_array, num_id - 1), 2)
    -- str = str.."\n\n"..(num_id - 1).." ("..Callback.get_type_name(num_id - 1)..")"

    callback_arg_types[num_id - 1] = {}

    for i = 0, gm.array_length(arg_types) - 1 do
        local arg_type = gm.array_get(arg_types, i)
        table.insert(callback_arg_types[num_id - 1], arg_type)
        -- str = str.."\n  "..arg_type
    end
end

-- print(str)



-- ========== Hooks ==========

memory.dynamic_hook("RAPI.Callback.callback_execute", "void*", {"void*", "void*", "void*", "int", "void*"}, memory.pointer.new(tonumber(ffi.cast("int64_t", gmf.callback_execute))),
    -- Pre-hook
    function(ret_val, self, other, result, arg_count, args)
        
    end,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
        local arg_count = arg_count:get()
        local args_typed = ffi.cast("struct RValue**", args:get_address())

        local callback = tonumber(args_typed[0].i64)
        local cbank_callback = callback_bank[callback]
        if not cbank_callback then return end

        local wrapped_args = {}

        -- Wrap args (standard callbacks)
        if callback < #callback_constants then
            local arg_types = callback_arg_types[callback]
            for i, arg_type in ipairs(arg_types) do

                local arg, is_instance_id = rvalue_to_lua(args_typed[i])
                if is_instance_id then arg = gm.CInstance.instance_id_to_CInstance[arg] end

                if      arg_type:match("Instance_oP")       then arg = Instance.internal.wrap(arg, metatable_player)
                elseif  arg_type:match("Instance_pActor")   then arg = Instance.internal.wrap(arg, metatable_actor, true)
                elseif  arg_type:match("Instance")          then arg = Instance.internal.wrap(arg)
                elseif  arg_type:match("AttackInfo")        then arg = AttackInfo.wrap(arg)
                elseif  arg_type:match("HitInfo")           then arg = HitInfo.wrap(arg)
                end
                
                table.insert(wrapped_args, arg)
            end

        -- Wrap args (content callbacks)
        else
            for i = 1, arg_count - 1 do

                local arg, is_instance_id = rvalue_to_lua(args_typed[i])
                if is_instance_id then arg = gm.CInstance.instance_id_to_CInstance[arg] end
                
                table.insert(wrapped_args, Wrap.wrap(arg))
            end
        end

        -- Call functions
        for _, priority in ipairs(cbank_callback.priorities) do
            local cbank_priority = cbank_callback[priority]

            for _, fn_table in ipairs(cbank_priority) do
                fn_table.fn(table.unpack(wrapped_args))
            end
        end
    end
)



_CLASS["Callback"] = Callback