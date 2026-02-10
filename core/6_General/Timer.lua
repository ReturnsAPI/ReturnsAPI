-- Timer

-- A native implementation of RoRR's `stopwatch` system.
-- Only runs when unpaused.
-- See usage here:  https://github.com/ReturnsAPI/ReturnsAPI/wiki/Timer

Timer = new_class()

__timer_frame = __timer_frame or 0



-- ========== Instance Methods ==========

methods_timer = {

    start = function(self, duration)
        if duration and (type(duration) ~= "number") then log.error("start: duration must be a number", 2) end
        self.end_time = __timer_frame + (duration or self.duration)
    end,


    stop = function(self)
        self.end_time = __timer_frame
    end

}



-- ========== Metatables ==========

local wrapper_name = "Timer"

make_table_once("metatable_timer_class", {
    
    -- Create new timer
    __call = function(t, duration, autostart)
        if duration and (type(duration) ~= "number") then log.error("Timer: duration must be a number", 2) end
        duration = duration or 0

        return setmetatable({
            duration = duration,
            end_time = __timer_frame + ((autostart and duration) or 0),
        }, metatable_timer)
    end,


    __newindex = function(t, k, v)
        -- Do nothing
    end,


    __metatable = "RAPI.Class."..wrapper_name
})
setmetatable(Timer, metatable_timer_class)


make_table_once("metatable_timer", {
    __index = function(t, k)
        if k == "time_left" then return t.end_time - __timer_frame end
        if k == "finished"  then return __timer_frame >= t.end_time end
        if k == "RAPI"      then return wrapper_name end
        if methods_timer[k] then return methods_timer[k] end
    end,


    __newindex = function(t, k, v)
        -- Do nothing
    end,


    __metatable = "RAPI.Wrapper."..wrapper_name
})



-- ========== Hooks ==========

Hook.add_post(RAPI_NAMESPACE, gm.constants.__input_system_tick, function(self, other, result, args)
    if Util.bool(Global.gameplay_paused) then return end
    __timer_frame = __timer_frame + 1
end)



-- Public export
__class.Timer = Timer
__class_mt.Timer = metatable_timer_class