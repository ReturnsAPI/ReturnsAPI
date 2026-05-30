-- Timer

--[[
A native implementation of RoRR's `stopwatch` system. <br>
Only runs when unpaused.
]]
---@class TimerClass
Timer = new_class()
C.Timer = Timer

run_on_initial_load(function()
    P.timer_frame = 0
end)

local metatable

local type    = type
local to_bool = Util.bool


-- ========== Instance Methods ==========

---@class Timer
local methods = {}

methods.start = function(self, duration)
    if duration and (type(duration) ~= "number") then throw("duration must be a number") end
    self.end_time = P.timer_frame + (duration or self.duration)
end

methods.stop = function(self)
    self.end_time = P.timer_frame
end


-- ========== Metatables ==========

---@class TimerClass
---@overload fun(duration: number, autostart: boolean): Timer

local mt_name = "TimerClass"

M.Timer = {
    __call = function(t, duration, autostart)
        -- Create new timer
        if duration and (type(duration) ~= "number") then log.error("Timer: duration must be a number", 2) end
        duration = duration or 0

        return setmetatable({
            duration = duration,
            end_time = P.timer_frame + ((autostart and duration) or 0),
        }, metatable)
    end,

    __newindex = function(t, k, v)
        log.error(mt_name.." has no properties to set", 2)
    end,

    __metatable = mt_class_name(mt_name),
}
setmetatable(Timer, M.Timer)

---@class Timer
---@field RAPI string The name of this wrapper.
---@field time_left number Time left in frames; can be a negative value (which means "time elapsed since end time").
---@field finished boolean `true` if timer is finished.

local mt_name = "Timer"

W.Timer = {
    __index = function(t, k)
        if k == "time_left" then return t.end_time - P.timer_frame end
        if k == "finished"  then return P.timer_frame >= t.end_time end
        if k == "RAPI"      then return mt_name end
        
        -- Methods
        local method = methods[k]
        if method then return method end
    end,

    __newindex = function(t, k, v)
        log.error(mt_name.." has no properties to set", 2)
    end,

    __metatable = mt_wrapper_name(mt_name),
}
metatable = W.Timer


-- ========== Hooks ==========

Hook.add_post(RAPI_NAMESPACE, gm.constants.__input_system_tick, function(self, other, result, args)
    if to_bool(Global.gameplay_paused) then return end
    P.timer_frame = P.timer_frame + 1
end)