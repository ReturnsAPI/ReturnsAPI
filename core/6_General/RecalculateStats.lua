-- RecalculateStats

-- Temporary flawed implementation that simply post-hooks
-- like before while we wait for a better implementation by sarn
-- (Re-adding all the mid-hooks is time consuming)

RecalculateStats = new_class()

run_once(function()
    __stats_callback_bank = { priorities = {} }
    __stats_callback_id_counter = 0
    __stats_callback_id_lookup = {}
end)



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@param        func        | function  | The function to register. <br>The parameter for it is `actor`.
--@optional     priority    | number    | The priority of the function. <br>Higher values run before lower ones; can be negative. <br>`Callback.Priority.NORMAL` (`0`) by default.
--[[
Registers a function for stat recalculation.
*Technical:* This function will run in `recalculate_stats` post-hook.

**Priority Convention**
To allow for a decent amount of space between priorities,
use the enum values in @link {`Callback.Priority` | Callback#Priority}.
If you need to be more specific than that, try to keep a distance of at least `100`.
]]
RecalculateStats.add = function(namespace, func, priority)
    -- Default priority is 0
    priority = priority or 0

    -- Create __stats_callback_bank priority subtable if it does not exist
    if not __stats_callback_bank[priority] then
        __stats_callback_bank[priority] = {}
        table.insert(__stats_callback_bank.priorities, priority)
        table.sort(__stats_callback_bank.priorities, function(a, b) return a > b end)
    end

    -- Add to subtable
    table.insert(__stats_callback_bank[priority], {
        namespace   = namespace,
        fn          = func
    })
end


--@static
--[[
Removes all registered stat recalculation functions from your namespace.

Automatically called when you hotload your mod.
]]
RecalculateStats.remove_all = function(namespace)
    for priority, subtable in pairs(__stats_callback_bank) do
        if type(priority) == "number" then
            for i = #subtable, 1, -1 do
                if subtable[i].namespace == namespace then
                    table.remove(subtable, i)
                end
            end
            if #subtable <= 0 then
                __stats_callback_bank[priority] = nil
                Util.table_remove_value(__stats_callback_bank.priorities, priority)
            end
        end
    end
end
table.insert(_clear_namespace_functions, RecalculateStats.remove_all)



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    local actor = Instance.wrap(self)
    
    -- Loop through each priority table of the callback type
    for _, priority in ipairs(__stats_callback_bank.priorities) do
        local subtable = __stats_callback_bank[priority]

        -- Loop through priority table
        -- and call registered functions with wrapped args
        for _, fn_table in ipairs(subtable) do
            local status, err = pcall(fn_table.fn, actor)
            if not status then
                if (err == nil)
                or (err == "C++ exception") then err = "GM call error (see above)" end
                log.warning("\n"..fn_table.namespace:gsub("%.", "-")..": RecalculateStats function failed to execute fully.\n"..err)
            end
        end
    end
end)



-- Public export
__class.RecalculateStats = RecalculateStats