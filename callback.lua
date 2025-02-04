-- Callback

Callback = {}

local callback_bank = {}    -- All Callback.onWhatever tables are proxies; actual functions stored in here
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



-- ========== Internal ==========

-- Populate Callbacks with every
-- type having its own table

for i, v in ipairs(callback_list) do
    local t = {}
    setmetatable(t, metatable_callback_type)
    Callback[v] = ReadOnly.new(t)
    callback_bank[Callback[v]] = {}
end



-- ========== Static Methods ==========

Callback.get_type_name = function(cbid)
    if cbid < 0 or cbid >= #callback_list then log.error("Invalid Callback numID", 2) end
    return callback_list[cbid + 1]
end


Callback.remove = function(id)
    local t = id_lookup[id]
    if not t then return end
    id_lookup[id] = nil
    table.remove(callback_bank[t[1]], t[2])
end



-- ========== Metatables ==========

setmetatable(Callback, {
    __index = function(t, k)
        if type(k) == "number" then     -- Item on_acquired, etc.
            local t = {}
            setmetatable(t, metatable_callback_type)
            Callback[k] = ReadOnly.new(t)
            callback_bank[Callback[k]] = {}
            return
        end

        log.error("Invalid Callback type", 2)
    end,


    __metatable = "Callback"
})


metatable_callback_type = {
    __index = {

        add = function(self, fn)
            id_counter = id_counter + 1

            local t = {
                -- id          = cbank.id_counter,
                namespace   = "TODO",
                fn          = fn
            }
            id_lookup[id_counter] = {self, t}
            table.insert(callback_bank[self], t)

            return id_counter
        end

    },


    __metatable = "CallbackType"
}



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    local cbid = args[1].value
    local cbank = nil

    -- Standard callbacks
    if cbid < #callback_list then
        local name = callback_list[cbid + 1]
        cbank = callback_bank[Callback[name]]

    -- Content specific callbacks (e.g., Item on_acquired)
    elseif Callback[cbid] then
        cbank = callback_bank[Callback[cbid]]
    end
        
    if cbank then
        for _, fn_table in pairs(cbank) do
            fn_table.fn()   -- fill with wrapped args
        end
    end
end)



return ReadOnly.new(Callback)