-- Callback

Callback = new_class()

run_once(function()
    __callback_bank = {}
    __callback_id_counter = 0
    __callback_id_lookup = {}
end)

-- Table structures:

-- __callback_bank = {
--     [Callback.ON_LOAD] = {                   -- Callback type
--         priorities = { ... }                 -- List of priorities for the callback
--         [0] = {                              -- Priority 0
--             {
--                 id          = 1,             -- `fn_table`
--                 namespace   = namespace,
--                 fn          = fn,
--                 priority    = priority
--             },
--             {
--                 id          = 2,
--                 namespace   = namespace,
--                 fn          = fn,
--                 priority    = priority
--             },
--             ...
--         },
--         [1000] = ...                         -- Priority 1000
--     },
--     [Callback.POST_LOAD] = ...
-- }

-- __callback_id_lookup = {
--     [1] = {                                  -- ID 1
--         Callback.ON_LOAD,                    -- Element 1 - Callback type
--         {
--             id          = 1,                 -- Element 2 - `fn_table`
--             namespace   = namespace,
--             fn          = fn,
--             priority    = priority
--         }
--     },
--     [2] = ...                                -- ID 2
-- }


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
Callback.Priority = ReadOnly.new({
    NORMAL  = 0,
    BEFORE  = 1000,
    AFTER   = -1000
})



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       string
--@param        num_id      | number    | The numerical ID of the callback type.
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
        log.error("Callback.add: Invalid Callback type", 2)
    end

    -- Throw error if not function
    if type(fn) ~= "function" then
        log.error("Callback.add: No function provided", 2)
    end

    -- All callbacks have the same priority (0) unless specified
    -- Higher numbers run before lower ones (can be negative)
    priority = priority or 0

    -- Create __callback_bank subtables if they do not exist
    if not __callback_bank[callback] then
        __callback_bank[callback] = { priorities = {} }
    end
    local cbank_callback = __callback_bank[callback]
    if not cbank_callback[priority] then
        cbank_callback[priority] = {}
        table.insert(cbank_callback.priorities, priority)
        table.sort(cbank_callback.priorities, function(a, b) return a > b end)
    end

    -- Add to subtable
    local fn_table = {
        id          = __callback_id_counter,
        namespace   = namespace,
        fn          = fn,
        priority    = priority
    }
    local lookup_table = {callback, fn_table}
    __callback_id_lookup[__callback_id_counter] = lookup_table
    table.insert(__callback_bank[callback][priority], fn_table)
    
    local current_id = __callback_id_counter
    __callback_id_counter = __callback_id_counter + 1

    -- Return numerical ID for removability
    return current_id
end


--@static
--@param        id          | number    | The unique ID of the registered function to remove.
--[[
Removes a registered callback function.
The ID is the one from @link {`Callback.add` | Callback#add}.
]]
Callback.remove = function(id)
    -- Look up ID
    local lookup_table = __callback_id_lookup[id]
    if not lookup_table then return end
    __callback_id_lookup[id] = nil

    -- Remove from table of relevant callback type and priority
    local priority = lookup_table[2].priority
    local cbank_callback = __callback_bank[lookup_table[1]]
    local cbank_priority = cbank_callback[priority]
    Util.table_remove_value(cbank_priority, lookup_table[2])
    if #cbank_priority <= 0 then
        cbank_callback[priority] = nil
        Util.table_remove_value(cbank_callback.priorities, priority)
    end
end


--@static
--[[
Removes all registered callbacks functions from your namespace.

Automatically called when you hotload your mod.
]]
Callback.remove_all = function(namespace)
    for _, cbank_callback in pairs(__callback_bank) do
        for priority, cbank_priority in pairs(cbank_callback) do
            if type(priority) == "number" then
                for i = #cbank_priority, 1, -1 do
                    local fn_table = cbank_priority[i]
                    if fn_table.namespace == namespace then
                        __callback_id_lookup[fn_table.id] = nil
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



-- ========== Hooks ==========

memory.dynamic_hook("RAPI.Callback.callback_execute", "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.callback_execute),
    -- Pre-hook
    {nil,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
        local arg_count = arg_count:get()
        local args_typed = ffi.cast(__args_typed, args:get_address())
    
        -- Check if any registered callbacks
        -- exist for the current callback
        local callback = tonumber(args_typed[0].i64)
        local cbank_callback = __callback_bank[callback]
        if not cbank_callback then return end
    
        local wrapped_args = {}
    
        -- Wrap args (standard callbacks, e.g., `Callback.ON_LOAD`)
        if callback < #callback_constants then
            local arg_types = callback_arg_types[callback]  -- From `Global.class_callback[callback]`
            for i, arg_type in ipairs(arg_types) do
    
                local arg = RValue.to_wrapper(args_typed[i])
                
                -- Wrap as certain wrappers depending on arg type
                if arg then
                    if      arg_type:match("Instance") and arg == -4    then arg = __invalid_instance   -- Wrap as invalid Instance if -4
                    elseif  arg_type:match("AttackInfo")                then arg = AttackInfo.wrap(arg) -- Assuming `arg` is a Struct wrapper
                    elseif  arg_type:match("HitInfo")                   then arg = HitInfo.wrap(arg)
                    elseif  arg_type:match("Equipment")                 then arg = Equipment.wrap(arg)
                    end
                end
    
                -- Packet and Message edge cases (41 - net_message_onReceived)
                if callback == Callback.NET_MESSAGE_ON_RECEIVED then
                    if      i == 1 then arg = Packet.wrap(arg)
                    elseif  i == 2 then arg = Buffer.wrap(arg)
                    end
                end
                
                table.insert(wrapped_args, arg)
            end
    
        -- Wrap args (content callbacks, e.g., `<item>.on_acquired`)
        else
            for i = 1, arg_count - 1 do  
                table.insert(wrapped_args, RValue.to_wrapper(args_typed[i]))
            end
        end
    
        -- Loop through each priority table of the callback type
        for _, priority in ipairs(cbank_callback.priorities) do
            local cbank_priority = cbank_callback[priority]
    
            -- Loop through priority table
            -- and call registered functions with wrapped args
            for _, fn_table in ipairs(cbank_priority) do
                fn_table.fn(table.unpack(wrapped_args))
            end
        end
    end}
)



__class.Callback = Callback