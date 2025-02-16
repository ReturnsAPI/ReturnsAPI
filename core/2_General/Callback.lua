-- Callback

Callback = {}

local callback_bank = {}
local id_counter = 0
local id_lookup = {}

local callback_list = {
    "onLoad", "postLoad", "onStep", "preStep", "postStep",
    "onDraw", "preHUDDraw", "onHUDDraw", "postHUDDraw", "camera_onViewCameraUpdate",
    "onScreenRefresh", "onGameStart", "onGameEnd", "onDirectorPopulateSpawnArrays",
    "onStageStart", "onSecond", "onMinute", "onAttackCreate", "onAttackHit", "onAttackHandleStart",
    "onAttackHandleEnd", "onDamageBlocked", "onEnemyInit", "onEliteInit", "onDeath", "onPlayerInit", "onPlayerStep",
    "prePlayerHUDDraw", "onPlayerHUDDraw", "onPlayerInventoryUpdate", "onPlayerDeath",
    "onCheckpointRespawn", "onInputPlayerDeviceUpdate", "onPickupCollected", "onPickupRoll", "onEquipmentUse", "postEquipmentUse", "onInteractableActivate",
    "onHitProc", "onDamagedProc", "onKillProc",
    "net_message_onReceived", "console_onCommand"
}



-- ========== Enums ==========

-- Generate Callback.TYPE enum
local TYPE = {}
for i, v in ipairs(callback_list) do
    TYPE[v] = i - 1
end

Callback.TYPE = ReadOnly.new(TYPE)



-- ========== Static Methods ==========

Callback.get_type_name = function(num_id)
    if num_id < 0 or num_id >= #callback_list then log.error("Invalid Callback numID", 2) end
    return callback_list[num_id + 1]
end


Callback.add = function(namespace, callback, fn, priority)
    -- Throw error if not numerical ID
    if type(callback) ~= "number" then
        log.error("Invalid Callback type", 2)
    end

    -- All callbacks have the same priority (0) unless specified
    -- Higher numbers run before lower ones (can be negative)
    priority = priority or 0

    -- Create callback_bank subtables if they do not exist
    if not callback_bank[callback] then
        callback_bank[callback] = {}
        callback_bank[callback].priorities = {}
    end
    local cbank = callback_bank[callback]
    if not cbank[priority] then
        cbank[priority] = {}
        table.insert(cbank.priorities, priority)
        table.sort(cbank.priorities, function(a, b) return a > b end)
    end

    -- Add to subtable
    id_counter = id_counter + 1

    local fn_table = {
        id          = id_counter,
        namespace   = namespace,
        fn          = fn,
        priority    = priority
    }
    local lookup_table = {callback, fn_table}
    id_lookup[id_counter] = lookup_table
    table.insert(callback_bank[callback][priority], fn_table)

    return id_counter
end


Callback.remove = function(id)
    local lookup_table = id_lookup[id]
    if not lookup_table then return end
    id_lookup[id] = nil

    local cbank_callback = callback_bank[lookup_table[1]]
    for priority, cbank_priority in pairs(cbank_callback) do
        if type(priority) == "number" then
            for i, v in ipairs(cbank_priority) do
                if v == lookup_table[2] then
                    table.remove(cbank_priority, i)
                    break
                end
            end
        end
    end
end


Callback.remove_all = function(namespace)
    for _, cbank_callback in pairs(callback_bank) do
        for priority, cbank_priority in pairs(cbank_callback) do
            if type(priority) == "number" then
                for i = #cbank_priority, 1, -1 do
                    local fn_table = cbank_priority[i]
                    if fn_table.namespace == namespace then
                        id_lookup[fn_table.id] = nil
                        table.remove(cbank_priority, i)
                    end
                end
            end
        end
    end
end



-- ========== Hooks ==========

-- gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
--     local callback = args[1].value
--     local cbank = callback_bank[callback]

--     if cbank then
--         for _, fn_table in ipairs(cbank) do
--             fn_table.fn()   -- fill with wrapped args
--         end
--     end
-- end)

memory.dynamic_hook("RAPI.callback_execute", "void*", {"void*", "void*", "void*", "int", "void*"}, memory.pointer.new(tonumber(ffi.cast("int64_t", gmf.callback_execute))),
    -- Pre-hook
    function(ret_val, self, other, result, arg_count, args)
        
    end,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
        local arg_count = arg_count:get()
        local args_typed = ffi.cast("struct RValue**", args:get_address())

        local callback = tonumber(args_typed[0].i64)
        local cbank_callback = callback_bank[callback]

        if not cbank_callback then return end

        for _, priority in ipairs(cbank_callback.priorities) do
            local cbank_priority = cbank_callback[priority]

            for _, fn_table in ipairs(cbank_priority) do
                fn_table.fn()   -- fill with wrapped args
            end
        end
    end
)



_CLASS["Callback"] = Callback