-- Alarm

--[[
Custom alarm system separate from GameMaker's alarms.
]]

Alarm = new_class()

run_once(function()
    __alarm_current_id = 0

    __alarm_bank                    = CallbackCache.new()
    __alarm_bank_args               = {}
    __alarm_current_frame           = 0

    __alarm_bank_nopause            = CallbackCache.new()
    __alarm_bank_args_nopause       = {}
    __alarm_current_frame_nopause   = 0
end)



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       number
--@param        time        | number    | The number of frames before the function is called.
--@param        fn          | function  | The function to call.
--@optional     ...         |           | A variable number of arguments to pass to the function.
--[[
Adds a new alarm which calls the provided function
with passed args after the specified amount of time.
Returns the unique ID of the alarm.

The alarms will automatically pause if the game is paused while in a run.
]]
Alarm.add = function(NAMESPACE, time, fn, ...)
    -- Check arguments
    if type(time) ~= "number" then log.error("Alarm.add: time must be a number (you passed in '"..tostring(time).."')", 2) end
    if type(fn) ~= "function" then log.error("Alarm.add: fn must be a function (you passed in '"..tostring(fn).."')", 2) end

    -- Create new subtable at that frame if existn't
    local frame = __alarm_current_frame + time + 1  -- +1 for proper time I think
    local id = __alarm_current_id
    
    __alarm_bank:add(fn, NAMESPACE, 0, frame, id)
    __alarm_bank_args[id] = {...}

    __alarm_current_id = __alarm_current_id + 1

    return id
end


--@static
--@return       number
--@param        time        | number    | The number of frames before the function is called.
--@param        fn          | function  | The function to call.
--@optional     ...         |           | A variable number of arguments to pass to the function.
--[[
Adds a new alarm which calls the provided function
with passed args after the specified amount of time.
Returns the unique ID of the alarm.

The alarms will *not* pause at any point.
]]
Alarm.add_nopause = function(NAMESPACE, time, fn, ...)
    -- Check arguments
    if type(time) ~= "number" then log.error("Alarm.add_nopause: time must be a number (you passed in '"..tostring(time).."')", 2) end
    if type(fn) ~= "function" then log.error("Alarm.add_nopause: fn must be a function (you passed in '"..tostring(fn).."')", 2) end

    -- Create new subtable at that frame if existn't
    local frame = __alarm_current_frame_nopause + time + 1  -- +1 for proper time I think
    local id = __alarm_current_id
    
    __alarm_bank_nopause:add(fn, NAMESPACE, 0, frame, id)
    __alarm_bank_args_nopause[id] = {...}

    __alarm_current_id = __alarm_current_id + 1

    return id
end


--@static
--@return       function
--@param        id          | number    | The unique ID of the alarm to remove.
--[[
Removes and returns an existing alarm.
The ID is the one from @link {`Alarm.add` | Alarm#add}/ @link {`Alarm.add_nopause` | Alarm#add_nopause}.
]]
Alarm.remove = function(id)
    return __alarm_bank:remove(id) or __alarm_bank_nopause:remove(id)
end


--@static
--[[
Removes all alarms from your namespace.

Automatically called when you hotload your mod.
]]
Alarm.remove_all = function(NAMESPACE)
    __alarm_bank:remove_all(NAMESPACE)
    __alarm_bank_nopause:remove_all(NAMESPACE)
end
table.insert(_clear_namespace_functions, Alarm.remove_all)



-- ========== Hooks ==========

Hook.add_post(RAPI_NAMESPACE, gm.constants.__input_system_tick, Callback.Priority.BEFORE, function(self, other, result, args)
    -- Increment frame counter while unpaused
    if not Global.pause then __alarm_current_frame = __alarm_current_frame + 1 end
    __alarm_current_frame_nopause = __alarm_current_frame_nopause + 1

    -- Call functions
    __alarm_bank:loop_and_call_functions(function(fn_table)
        local status, err = pcall(fn_table.fn, table.unpack(__alarm_bank_args[fn_table.id]))
        if not status then
            if (err == nil)
            or (err == "C++ exception") then err = "GameMaker error (see above)" end
            log.warning("\n"..fn_table.namespace..": Alarm (ID '"..fn_table.id.."') failed to execute fully.\n"..err)
        end
    end, __alarm_current_frame)

    -- Call functions (nopause)
    __alarm_bank_nopause:loop_and_call_functions(function(fn_table)
        local status, err = pcall(fn_table.fn, table.unpack(__alarm_bank_args_nopause[fn_table.id]))
        if not status then
            if (err == nil)
            or (err == "C++ exception") then err = "GameMaker error (see above)" end
            log.warning("\n"..fn_table.namespace..": Alarm (ID '"..fn_table.id.."') failed to execute fully.\n"..err)
        end
    end, __alarm_current_frame_nopause)

    __alarm_bank:delete_section(__alarm_current_frame)
    __alarm_bank:delete_section(__alarm_current_frame_nopause)
end)



__class.Alarm = Alarm