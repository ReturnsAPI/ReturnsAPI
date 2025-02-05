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

Callback.get_type_name = function(cbid)
    if cbid < 0 or cbid >= #callback_list then log.error("Invalid Callback numID", 2) end
    return callback_list[cbid + 1]
end


Callback.add = function(namespace, callback, fn)
    -- Throw error if not numerical ID
    if type(callback) ~= "number" then
        log.error("Invalid Callback type", 2)
    end

    -- Create callback_bank subtable if it does not exist
    if not callback_bank[callback] then
        callback_bank[callback] = {}
    end

    -- Add to subtable
    id_counter = id_counter + 1

    local fn_t = {
        id          = id_counter,
        namespace   = namespace,
        fn          = fn
    }
    local lookup_t = {callback, fn_t}
    id_lookup[id_counter] = lookup_t
    table.insert(callback_bank[callback], fn_t)

    return id_counter
end


Callback.remove = function(id)
    local lookup_t = id_lookup[id]
    if not lookup_t then return end
    id_lookup[id] = nil

    local cbank = callback_bank[lookup_t[1]]
    for i, v in ipairs(cbank) do
        if v == lookup_t[2] then
            table.remove(cbank, i)
            break
        end
    end
end


Callback.remove_all = function(namespace)
    for callback, cbank in pairs(callback_bank) do
        for i = #cbank, 1, -1 do
            local fn_t = cbank[i]
            if fn_t.namespace == namespace then
                id_lookup[fn_t.id] = nil
                table.remove(cbank, i)
            end
        end
    end
end



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    local callback = args[1].value
    local cbank = callback_bank[callback]

    if cbank then
        for _, fn_t in ipairs(cbank) do
            fn_t.fn()   -- fill with wrapped args
        end
    end
end)



return Callback