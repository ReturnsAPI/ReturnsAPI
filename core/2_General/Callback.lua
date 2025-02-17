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

local callback_arg_types = {}



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
    local cbank_callback = callback_bank[callback]
    if not cbank_callback[priority] then
        cbank_callback[priority] = {}
        table.insert(cbank_callback.priorities, priority)
        table.sort(cbank_callback.priorities, function(a, b) return a > b end)
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
            if #cbank_priority <= 0 then
                cbank_callback[priority] = nil
                Util.table_remove_value(cbank_callback.priorities, priority)
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
                if #cbank_priority <= 0 then
                    cbank_callback[priority] = nil
                    Util.table_remove_value(cbank_callback.priorities, priority)
                end
            end
        end
    end
end



-- DEBUG
Callback.generate_arg_type_table = function()
    local callback_type_array = Array.wrap(gm.variable_global_get("class_callback"))
    local str = ""

    for num_id, _ in ipairs(callback_list) do
        local arg_types = callback_type_array[num_id][3]
        str = str.."\n\n"..(num_id - 1).." ("..Callback.get_type_name(num_id - 1)..")"

        callback_arg_types[num_id - 1] = {}

        for i = 1, #arg_types do
            local arg_type = arg_types[i]
            table.insert(callback_arg_types[num_id - 1], arg_type)
            str = str.."\n  "..arg_type
        end

        -- for _, arg_type in pairs(arg_types) do
        --     table.insert(callback_arg_types[num_id - 1], arg_type)
        --     print(arg_type)
        -- end
    end

    print(str)
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

        local wrapped_args = {}

        -- Wrap args (standard callbacks)
        if callback < #callback_list then
            local arg_types = callback_arg_types[callback]
            for i, arg_type in ipairs(arg_types) do

                local arg, is_instance_id = rvalue_to_lua(args_typed[i])
                if is_instance_id then arg = gm.CInstance.instance_id_to_CInstance[arg] end

                if      arg_type:match("Instance_oP")       then arg = Instance_wrap_internal(arg, metatable_player)
                elseif  arg_type:match("Instance_pActor")   then arg = Instance_wrap_internal(arg, metatable_actor, true)
                elseif  arg_type:match("Instance")          then arg = Instance_wrap_internal(arg)
                -- elseif  arg_type:match("AttackInfo")        then TODO
                -- elseif  arg_type:match("HitInfo")           then TODO
                end

                -- TODO Also add edge case for Callback 41 somewhere
                
                table.insert(wrapped_args, arg)
            end

        -- Wrap args (content callbacks)
        else
            for i = 1, arg_count - 1 do

                local arg, is_instance_id = rvalue_to_lua(args_typed[i])
                if is_instance_id then arg = gm.CInstance.instance_id_to_CInstance[arg] end
                
                table.insert(wrapped_args, Wrap.wrap(arg))
            end

        end

        -- Call functions
        for _, priority in ipairs(cbank_callback.priorities) do
            local cbank_priority = cbank_callback[priority]

            for _, fn_table in ipairs(cbank_priority) do
                fn_table.fn(table.unpack(wrapped_args))
            end
        end
    end
)



_CLASS["Callback"] = Callback