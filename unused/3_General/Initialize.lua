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



-- ========== Static Methods ==========

Initialize.is_done = function()
    return initialized
end



-- ========== Metatables ==========

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



-- ========== Hooks ==========

memory.dynamic_hook("RAPI.initialize", "void*", {"void*", "void*", "void*", "int", "void*"}, memory.pointer.new(tonumber(ffi.cast("int64_t", gmf.__input_system_tick))),
    -- Pre-hook
    function(ret_val, self, other, result, arg_count, args)
        
    end,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
        if not initialized then
            initialized = true

            -- Call RAPI initialize first
            RAPI_initialize()
    
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