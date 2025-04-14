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
    Global.internal.initialize()
    Class.internal.initialize()
    ItemTier.internal.initialize()
    LootPool.internal.initialize()
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



-- ========== Static Methods ==========

--$static
--$return   bool
--[[
Adds a new function to run during ReturnsAPI's initialization loop.
This happens after all vanilla content has loaded.
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


--$static
--$return   bool
--[[
Returns `true` if ReturnsAPI's initialization loop has started.
This happens after all vanilla content has loaded.
]]
Initialize.has_started = function()
    return __initialized_started
end


--$static
--$return   bool
--[[
Returns `true` if ReturnsAPI's initialization loop has finished.
]]
Initialize.is_done = function()
    return __initialized_done
end



-- ========== Hooks ==========

Memory.dynamic_hook("RAPI.Initialize.__input_system_tick", "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.__input_system_tick),
    -- Pre-hook
    {nil,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
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
                            log.warning("\n"..init_table.namespace:gsub(".", "-")..": Initialize failed to execute fully.\n"..err)
                        end
                    end
                end
            end

            -- Initialize.is_done
            __initialized_done = true
        end
        initialize_done_this_load = true
    end}
)



-- Public export
__class.Initialize = Initialize