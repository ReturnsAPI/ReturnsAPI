-- Initialize

Initialize = new_class()

if not __initialize_bank then   -- Preserve on hotload
    __initialize_bank = {
        priorities = {}
    }
end

local initialized_started = false
local initialized = false



-- ========== Internal ==========

local function RAPI_initialize()
    Global.internal.initialize()
    Class.internal.initialize()
    ItemTier.internal.initialize()
    LootPool.internal.initialize()
end


Initialize.internal.check_if_started = function()
    if not initialized_started then log.error("Cannot call method before game initialization has started; try placing the call within Initialize()", 3) end
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
Returns `true` if ReturnsAPI's initialization loop has started.
This happens after all vanilla content is loaded.
]]
Initialize.has_started = function()
    return initialized_started
end


--$static
--$return   bool
--[[
Returns `true` if ReturnsAPI's initialization loop has finished.
]]
Initialize.is_done = function()
    return initialized
end



-- ========== Metatables ==========

local function make_metatable_initialize(namespace)
    return {
        __call = function(t, func, priority)
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
        end,


        __metatable = "RAPI.Class.Initialize"
    }
end
setmetatable(Initialize, make_metatable_initialize(_ENV["!guid"]))



-- ========== Hooks ==========

memory.dynamic_hook("RAPI.Initialize.__input_system_tick", "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.__input_system_tick),
    -- Pre-hook
    {nil,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
        if not initialized then
            -- Initialize.has_started
            initialized_started = true

            -- Call RAPI initialize first
            RAPI_initialize()
    
            -- Call registered functions
            -- Do not call them again on hotload
            if not init_hotloaded then
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
            init_hotloaded = true

            -- Initialize.is_done
            initialized = true
        end
    end}
)



__class.Initialize = Initialize
__class_mt_builder.Initialize = make_metatable_initialize