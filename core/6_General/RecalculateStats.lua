-- RecalculateStats

-- Temporary flawed implementation that simply post-hooks
-- like before while we wait for a better implementation by sarn
-- (Re-adding all the mid-hooks is time consuming)

RecalculateStats = new_class()

run_once(function()
    __recalcstats_cache = CallbackCache.new()
end)



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       number
--@param        fn          | function  | The function to register. <br>The parameter for it is `actor`.
--@optional     priority    | number    | The priority of the function. <br>Higher values run before lower ones; can be negative. <br>`Callback.Priority.NORMAL` (`0`) by default.
--[[
Registers a function for stat recalculation.
*Technical:* This function will run in `recalculate_stats` post-hook.

**Priority Convention**
To allow for a decent amount of space between priorities,
use the enum values in @link {`Callback.Priority` | Callback#Priority}.
If you need to be more specific than that, try to keep a distance of at least `100`.
]]
RecalculateStats.add = function(NAMESPACE, fn, priority)
    return __recalcstats_cache:add(fn, NAMESPACE, priority)
end


--@static
--@name         remove
--@param        id          | number    | The unique ID of the registered function to remove.
--[[
Removes a registered stat recalculation function.
The ID is the one from @link {`RecalculateStats.add` | RecalculateStats#add}.
]]
RecalculateStats.remove = function(id)
    return __recalcstats_cache:remove(id)
end


--@static
--[[
Removes all registered stat recalculation functions from your namespace.

Automatically called when you hotload your mod.
]]
RecalculateStats.remove_all = function(NAMESPACE)
    __recalcstats_cache:remove_all(NAMESPACE)
end
table.insert(_clear_namespace_functions, RecalculateStats.remove_all)



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    local actor = Instance.wrap(self)

    -- Call registered functions with wrapped arg
    __recalcstats_cache:loop_and_call_functions(function(fn_table)
        local status, err = pcall(fn_table.fn, actor)
        if not status then
            if (err == nil)
            or (err == "C++ exception") then err = "GM call error (see above)" end
            log.warning("\n"..fn_table.namespace..": RecalculateStats (ID '"..fn_table.id.."') failed to execute fully.\n"..err)
        end
    end)
end)



-- Public export
__class.RecalculateStats = RecalculateStats