-- Alarm

--[[
Custom alarm system separate from GameMaker's alarms.
]]
---@class Alarm
Alarm = new_class()
C.Alarm = Alarm

run_on_initial_load(function()
    P.alarm_functions             = {}  ---@type table<integer, CallbackTable>
    P.alarm_functions_nopause     = {}  ---@type table<integer, CallbackTable>
    P.alarm_function_args         = {}  ---@type table<integer, table>
    P.alarm_id_to_table           = {}  ---@type table<integer, CallbackTable> Stores which CallbackTable a function is in.
    P.alarm_counter               = {value = 0} -- Shared counter for all alarm `CallbackTable`s.
    P.alarm_current_frame         = 0
    P.alarm_current_frame_nopause = 0
end)

local alarm_functions         = P.alarm_functions
local alarm_functions_nopause = P.alarm_functions_nopause
local alarm_function_args     = P.alarm_function_args
local alarm_id_to_table       = P.alarm_id_to_table
local alarm_counter           = P.alarm_counter

local type          = type
local table_pack    = table.pack
local table_unpack  = table.unpack
local math_max      = math.max
local math_round    = math.round
local gm_global_get = gm.variable_global_get    ---@type function


-- ========== Static Methods ==========

--[[
Registers a function under an alarm, which calls it <br>
with passed args after the specified amount of time. <br>
Returns the unique ID of the alarm.

The alarms will automatically pause if the game is paused while in a run.
]]
---@param time integer The number of frames before the function is called. <br>Fractional values are rounded to the nearest integer. <br>Minimum `1`.
---@param fn function The function to register.
---@param ... any A variable amount of arguments to pass to the function.
---@return number
Alarm.add = function(NAMESPACE, time, fn, ...)
    -- Check arguments
    if type(time) ~= "number" then throw("time must be a number (got '"..tostring(time).."')", "add") end
    if type(fn) ~= "function" then throw("fn must be a function (got '"..tostring(fn).."')", "add") end

    -- Create new CallbackTable for the frame if it does not exist
    local frame = P.alarm_current_frame + math_max(math_round(time), 1) + 1  -- +1 for proper time I think
    local alarm_table = alarm_functions[frame]
    if not alarm_table then
        alarm_table = CallbackTable.new(alarm_counter)
        alarm_functions[frame] = alarm_table
    end

    local id = alarm_table:add(fn, NAMESPACE)
    alarm_function_args[id] = table_pack(...)
    alarm_id_to_table[id]   = alarm_table

    return id
end

--[[
Registers a function under an alarm, which calls it <br>
with passed args after the specified amount of time. <br>
Returns the unique ID of the alarm.

The alarms will *not* pause at any point.
]]
---@param time integer The number of frames before the function is called. <br>Fractional values are rounded to the nearest integer. <br>Minimum `1`.
---@param fn function The function to register.
---@param ... any A variable amount of arguments to pass to the function.
---@return number
Alarm.add_nopause = function(NAMESPACE, time, fn, ...)
    -- Check arguments
    if type(time) ~= "number" then throw("time must be a number (got '"..tostring(time).."')", "add_nopause") end
    if type(fn) ~= "function" then throw("fn must be a function (got '"..tostring(fn).."')", "add_nopause") end

    -- Create new CallbackTable for the frame if it does not exist
    local frame = P.alarm_current_frame_nopause + math_max(math_round(time), 1) + 1  -- +1 for proper time I think
    local alarm_table = alarm_functions_nopause[frame]
    if not alarm_table then
        alarm_table = CallbackTable.new(alarm_counter)
        alarm_functions_nopause[frame] = alarm_table
    end

    local id = alarm_table:add(fn, NAMESPACE)
    alarm_function_args[id] = table_pack(...)
    alarm_id_to_table[id]   = alarm_table

    return id
end

--[[
Removes and returns a registered function.
The ID is the one from @link {`Alarm.add` | Alarm#add}/ @link {`Alarm.add_nopause` | Alarm#add_nopause}.
]]
---@param id integer The ID of the function to remove.
---@return function | nil
Alarm.remove = function(id)
    local alarm_table = alarm_id_to_table[id]
    if not alarm_table then return end
    return alarm_table:remove(id)
end

--[[
Removes all registered functions in your namespace.

Automatically called when you hotload your mod.
]]
Alarm.remove_all = function(NAMESPACE)
    for _, t in pairs(alarm_functions) do
        t:remove_all(NAMESPACE)
    end
    for _, t in pairs(alarm_functions_nopause) do
        t:remove_all(NAMESPACE)
    end
end
run_on_import(Alarm.remove_all)


-- ========== Hooks ==========

gm.post_script_hook(gm.constants.__input_system_tick, function(self, other, result, args)
    local frame         = P.alarm_current_frame
    local frame_nopause = P.alarm_current_frame_nopause
    
    -- Increment frame counters
    if not gm_global_get("pause") then
        frame = frame + 1
    end
    frame_nopause = frame_nopause + 1

    -- Call registered functions
    local alarm_table = alarm_functions[frame]
    if alarm_table then
        for i = 1, #alarm_table do
            local data = alarm_table[i]
            local id   = data.id
            local args = alarm_function_args[id]
            local status, out = pcall(data.fn, table_unpack(args))
            if not status then
                if out == nil
                or out == "C++ exception" then
                    out = "GameMaker error (see above)"
                end
                log.warning("\n| "..data.namespace..": Error in alarm function (ID "..math.floor(id)..")\n| "..out)
            end
            alarm_function_args[id] = nil
        end
        alarm_functions[frame] = nil
    end

    -- Call registered functions (nopause)
    local alarm_table = alarm_functions_nopause[frame_nopause]
    if alarm_table then
        for i = 1, #alarm_table do
            local data = alarm_table[i]
            local id   = data.id
            local args = alarm_function_args[id]
            local status, out = pcall(data.fn, table_unpack(args))
            if not status then
                if out == nil
                or out == "C++ exception" then
                    out = "GameMaker error (see above)"
                end
                log.warning("\n| "..data.namespace..": Error in alarm function (ID "..math.floor(id)..")\n| "..out)
            end
            alarm_function_args[id] = nil
        end
        alarm_functions_nopause[frame_nopause] = nil
    end
    
    P.alarm_current_frame         = frame
    P.alarm_current_frame_nopause = frame_nopause
end)