-- Initialize

Initialize = new_class()

local initialize_bank = {
    priorities = {}
}

local initialized = false



-- ========== Internal ==========

local function RAPI_initialize()
    Global.internal.initialize()
    Class.internal.initialize()
end


Initialize.internal.check_if_done = function()
    if not initialized then log.error("Cannot call method before game initialization; try placing the call within Initialize()", 3) end
end


Initialize.internal.remove_all = function(namespace)
    local priorities_to_remove = {}
    for _, priority in ipairs(initialize_bank.priorities) do
        local ibank_priority = initialize_bank[priority]
        for i = #ibank_priority, 1, -1 do
            local init_table = ibank_priority[i]
            if init_table.namespace == namespace then
                table.remove(ibank_priority, i)
            end
        end
        if #ibank_priority <= 0 then
            initialize_bank[priority] = nil
            table.insert(priorities_to_remove, priority)
        end
    end
    for _, priority in ipairs(priorities_to_remove) do
        Util.table_remove_value(initialize_bank.priorities, priority)
    end
end



-- ========== Static Methods ==========

Initialize.is_done = function()
    return initialized
end



-- ========== Metatables ==========

local function make_metatable_initialize(namespace)
    return {
        __call = function(t, func, priority)
            -- Default priority is 0
            priority = priority or 0

            -- Create initialize_bank priority subtable if it does not exist
            if not initialize_bank[priority] then
                initialize_bank[priority] = {}
                table.insert(initialize_bank.priorities, priority)
                table.sort(initialize_bank.priorities, function(a, b) return a > b end)
            end
            
            -- Add to subtable
            table.insert(initialize_bank[priority], {
                namespace   = namespace,
                fn          = func
            })
        end,


        __metatable = "RAPI.Class.Initialize"
    }
end
setmetatable(Initialize, make_metatable_initialize("RAPI"))



-- ========== Hooks ==========

memory.dynamic_hook("RAPI.initialize", "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.__input_system_tick),
    -- Pre-hook
    {nil,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
        if not initialized then
            initialized = true

            -- Call RAPI initialize first
            RAPI_initialize()
    
            -- Call functions
            -- Do not call them again on hotload
            if not init_hotloaded then
                for _, priority in ipairs(initialize_bank.priorities) do
                    local ibank_priority = initialize_bank[priority]
                    for _, init_table in ipairs(ibank_priority) do
                        local status, err = pcall(init_table.fn)
                        if not status then
                            log.warning("\n"..init_table.namespace..": Initialize failed to execute fully.\n"..err)
                        end
                    end
                end
            end
            init_hotloaded = true
        end
    end}
)



_CLASS["Initialize"] = Initialize
_CLASS_MT_MAKE["Initialize"] = make_metatable_initialize