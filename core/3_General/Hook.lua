-- Hook

-- TODO: easier writing of memory.dynamic_hook
-- create each type of hook once and loop through a lua function table
-- probably shouldnt use internally for performance reasons (although it might be fine idk)

Hook = new_class()

if true then return end



-- ========== Static Methods ==========

--$static
--$return       string
--$param        num_id      | number    | The numerical ID of the callback type.
--[[
Returns the string name of the callback type with the given ID.
]]
Callback.get_type_name = function(num_id)
    if num_id < 0 or num_id >= #callback_constants then return nil end
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



_CLASS["Hook"] = Hook