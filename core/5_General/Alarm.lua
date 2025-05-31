-- Alarm

-- TODO write docs

Alarm = new_class()

run_once(function()
    __alarm_bank = {}
    __alarm_bank_lookup = {}
    __alarm_current_frame = 0
    __alarm_id_counter = 0
end)



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       number
--@param        time        | number    | The number of frames before the function is called.
--@param        fn          | function  | The function to call.
--@optional     ...         |           | A variable number of arguments to pass to the function.
--[[
Creates a new alarm which calls the provided function
with passed args after the specified amount of time.
Returns the unique ID of the alarm.
]]
Alarm.new = function(namespace, time, fn, ...)
    -- Check arguments
    if type(time) ~= "number" then log.error("Alarm.add: time must be a number", 2) end
    if type(fn) ~= "function" then log.error("Alarm.add: fn must be a function", 2) end

    -- Create new subtable at that frame if existn't
    local frame = __alarm_current_frame + time + 1  -- +1 for proper time I think
    if not __alarm_bank[frame] then __alarm_bank[frame] = {} end

    local alarm = {
        id          = __alarm_id_counter,
        namespace   = namespace,
        fn          = fn,
        args        = {...},
        frame       = frame
    }

    -- Add alarm to subtable
    table.insert(__alarm_bank[frame], alarm)
    __alarm_bank_lookup[__alarm_id_counter] = alarm
    if not __alarm_bank_lookup[namespace] then __alarm_bank_lookup[namespace] = {} end
    table.insert(__alarm_bank_lookup[namespace], alarm)

    local current_id = __alarm_id_counter
    __alarm_id_counter = __alarm_id_counter + 1

    -- Return numerical ID for removability
    return current_id
end


Alarm.remove = function(id)
    -- Lookup by ID
    local alarm = __alarm_bank_lookup[id]
    if not alarm then return end

    -- Remove from tables
    local subtable = __alarm_bank[alarm.frame]
    if subtable then
        Util.table_remove_value(subtable, alarm)
        if #subtable <= 0 then __alarm_bank[alarm.frame] = nil end
    end
    
    local subtable = __alarm_bank_lookup[alarm.namespace]
    if subtable then
        Util.table_remove_value(subtable, alarm)
        if #subtable <= 0 then __alarm_bank_lookup[alarm.namespace] = nil end
    end

    __alarm_bank_lookup[id] = nil
end


Alarm.remove_all = function(namespace)
    local subtable = __alarm_bank_lookup[namespace]
    if not subtable then return end

    -- Look through namespace lookup table
    -- and remove alarm tables from other tables
    for _, alarm in pairs(subtable) do
        __alarm_bank_lookup[alarm.id] = nil
        local frame_table = __alarm_bank[alarm.frame]
        if frame_table then
            Util.table_remove_value(frame_table, alarm)
            if #frame_table <= 0 then __alarm_bank[alarm.frame] = nil end
        end
    end

    __alarm_bank_lookup[namespace] = nil
end



-- ========== Hooks ==========

memory.dynamic_hook("RAPI.Alarm.__input_system_tick", "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.__input_system_tick),
    -- Pre-hook
    {nil,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
        -- Increment frame counter while unpaused
        if not Global.pause then __alarm_current_frame = __alarm_current_frame + 1 end

        -- Call functions
        local subtable = __alarm_bank[__alarm_current_frame]
        if subtable then
            for _, alarm in ipairs(subtable) do
                local status, err = pcall(alarm.fn, table.unpack(alarm.args))
                if not status then
                    if (err == nil)
                    or (err == "C++ exception") then err = "GM call error (see above)" end
                    log.warning("\n"..alarm.namespace:gsub("%.", "-")..": Alarm failed to execute fully.\n"..err)
                end
            end

            __alarm_bank[__alarm_current_frame] = nil
        end
    end}
)



__class.Alarm = Alarm