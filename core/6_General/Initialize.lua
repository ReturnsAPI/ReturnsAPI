-- Initialize

Initialize = new_class()

run_once(function()
    __initialize_bank = { priorities = {} }

    __initialized_started = false
    __initialized_done = false
end)

local initialize_done_this_load = false



-- ========== Internal ==========

local function RAPI_initialize()
    if Global   then Global.internal.initialize()   end
    if Class    then Class.internal.initialize()    end
    if ItemTier then ItemTier.internal.initialize() end
    if LootPool then LootPool.internal.initialize() end

    -- Class arrays
    if Stage    then Stage.internal.initialize() end
end


Initialize.internal.check_if_started = function()
    if not __initialized_started then log.error("Cannot call method before game initialization has started; try placing the call within Initialize.add()", 3) end
end


Initialize.internal.remove_all = function(namespace)
    for j = #__initialize_bank.priorities, 1, -1 do
        local priority = __initialize_bank.priorities[j]
        local ibank_priority = __initialize_bank[priority]
        for i = #ibank_priority, 1, -1 do
            local init_table = ibank_priority[i]
            if init_table.namespace == namespace then
                table.remove(ibank_priority, i)
            end
        end
        if #ibank_priority <= 0 then
            __initialize_bank[priority] = nil
            table.remove(__initialize_bank.priorities, j)
        end
    end
end
table.insert(_clear_namespace_functions, Initialize.internal.remove_all)



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@param        fn          | function  | The function to register.
--@optional     priority    | number    | The priority of the function. <br>Higher values run before lower ones; can be negative. <br>`Callback.Priority.NORMAL` (`0`) by default.
--[[
Adds a new function to run during ReturnsAPI's initialization loop.
This happens after all vanilla content has loaded.

**Priority Convention**
To allow for a decent amount of space between priorities,
use the enum values in @link {`Callback.Priority` | Callback#Priority}.
If you need to be more specific than that, try to keep a distance of at least `100`.
]]
Initialize.add = function(namespace, func, priority)
    -- Default priority is 0
    priority = priority or 0

    -- Create __initialize_bank priority subtable if it does not exist
    if not __initialize_bank[priority] then
        __initialize_bank[priority] = {}
        table.insert(__initialize_bank.priorities, priority)
        table.sort(__initialize_bank.priorities, function(a, b) return a > b end)
    end
    
    -- Add to subtable
    table.insert(__initialize_bank[priority], {
        namespace   = namespace,
        fn          = func
    })
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
    if not initialize_done_this_load then
        -- Initialize.has_started
        __initialized_started = true

        -- Call RAPI initialize first
        RAPI_initialize()

        -- Call registered functions
        -- Do not call them again on hotload
        if not __initialized_done then
            for _, priority in ipairs(__initialize_bank.priorities) do
                local ibank_priority = __initialize_bank[priority]
                for __, init_table in ipairs(ibank_priority) do
                    local status, err = pcall(init_table.fn)
                    if not status then
                        if (err == nil)
                        or (err == "C++ exception") then err = "GM call error (see above)" end
                        log.warning("\n"..init_table.namespace:gsub("%.", "-")..": Initialize failed to execute fully.\n"..err)
                    end
                end
            end
        end

        -- Initialize.is_done
        __initialized_done = true
    end
    initialize_done_this_load = true
end)



-- Public export
__class.Initialize = Initialize