-- Initialize

Initialize = {}

local initialize_bank = {}
initialize_bank.priorities = {}

local initialized = false



-- ========== Metatable ==========

metatable_initialize = {
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
        table.insert(initialize_bank[priority], func)
    end,


    __metatable = "RAPI.Class.Initialize"
}
setmetatable(Initialize, metatable_initialize)



-- ========== Initialize ==========

memory.dynamic_hook("RAPI.initialize", "void*", {"void*", "void*", "void*", "int", "void*"}, memory.pointer.new(tonumber(ffi.cast("int64_t", gmf.__input_system_tick))),
    -- Pre-hook
    function(ret_val, self, other, result, arg_count, args)
        
    end,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
        if not initialized then
            initialized = true
    
            -- Call functions
            for _, priority in ipairs(initialize_bank.priorities) do
                local ibank_priority = initialize_bank[priority]
                for _, fn in ipairs(ibank_priority) do
                    fn()
                end
            end
        end
    end
)



_CLASS["Initialize"] = Initialize
_CLASS_MT["Initialize"] = metatable_initialize