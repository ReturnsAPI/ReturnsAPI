-- Initialize

Initialize = new_class()

run_once(function()
    __initialize_cache = CallbackCache.new()

    __initialized_started = false
    __initialized_done = false
end)

-- Call initialize *once* every hotload
local initialize_done_this_rapi_load = false



-- ========== Internal ==========

Initialize.internal.check_if_started = function()
    if not __initialized_started then log.error("Cannot call method before game initialization has started; try placing the call within Initialize.add()", 3) end
end


Initialize.internal.remove_all = function(NAMESPACE)
    __initialize_cache:remove_all(NAMESPACE)
end
table.insert(_clear_namespace_functions, Initialize.internal.remove_all)



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@param        fn          | function  | The function to register.
--@overload
--@param        priority    | number    | The priority of the function. <br>Higher values run before lower ones; can be negative. <br>`Callback.Priority.NORMAL` (`0`) by default.
--@param        fn          | function  | The function to register.
--[[
Adds a new function to run during ReturnsAPI's initialization loop.
This happens after all vanilla content has loaded.

**Priority Convention**
To allow for a decent amount of space between priorities,
use the enum values in @link {`Callback.Priority` | Callback#Priority}.
If you need to be more specific than that, try to keep a distance of at least `100`.
]]
Initialize.add = function(NAMESPACE, arg1, arg2)
    if type(arg1) == "function" then
        return __initialize_cache:add(arg1, NAMESPACE)
    end
    return __initialize_cache:add(arg2, NAMESPACE, arg1)
end


--@static
--@return   bool
--[[
Returns `true` if ReturnsAPI's initialization loop has started.
This happens after all vanilla content has loaded.
]]
Initialize.has_started = function()
    return __initialized_started
end


--@static
--@return   bool
--[[
Returns `true` if ReturnsAPI's initialization loop has finished.
]]
Initialize.is_done = function()
    return __initialized_done
end



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.__input_system_tick, function(self, other, result, args)
    if not initialize_done_this_rapi_load then
        -- Initialize.has_started
        __initialized_started = true

        -- Call RAPI initialize first
        run_RAPI_initialize()   -- in Internal.lua

        -- Call registered functions
        -- Do not call them again on hotload
        if not __initialized_done then

            __initialize_cache:loop_and_call_functions(function(fn_table)
                local status, err = pcall(fn_table.fn)
                if not status then
                    if (err == nil)
                    or (err == "C++ exception") then err = "GameMaker error (see above)" end
                    log.warning("\n"..fn_table.namespace..": Initialize (ID '"..fn_table.id.."') failed to execute fully.\n"..err)
                end
            end)
        end

        -- Initialize.is_done
        __initialized_done = true
    end

    initialize_done_this_rapi_load = true
end)



-- Public export
__class.Initialize = Initialize