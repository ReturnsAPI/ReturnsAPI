-- Callback

Callback = {}

local callback_bank = {}    -- All Callback.onWhatever tables are proxies; actual functions stored in here

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

for k, _ in ipairs(Callback.TYPE) do
    local t = {}
    setmetatable(t, metatable_callback)
    Callback[k] = ReadOnly.new(t)
    callback_bank[Callback[k]] = {
        id_counter = 0,
        id_lookup = {},
        fn_tables = {}
    }
end



-- ========== Metatables ==========

metatable_callback = {
    __index = {

        add = function(self, fn)
            local cbank = callback_bank[self]
            cbank.id_counter = cbank.id_counter + 1

            local t = {
                -- id          = cbank.id_counter,
                namespace   = "TODO",
                fn          = fn
            }
            cbank.id_lookup[cbank.id_counter] = t
            table.insert(cbank.fn_tables, t)

            return cbank.id_counter
        end,


        remove = function(self, id)
            local cbank = callback_bank[self]

            local t = cbank.id_lookup[id]
            cbank.id_lookup[id] = nil
            table.remove(cbank.fn_tables, t)

            return t.fn
        end

    },


    __metatable = "Callback"
}



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    local cbid = args[1].value
    if cbid < #callback_list then
        local name = callback_list[cbid + 1]
        local cbank = callback_bank[Callback[name]]

        for _, fn_table in pairs(cbank.fn_tables) do
            fn_table.fn()   -- fill with wrapped args
        end
    end
end)



return ReadOnly.new(Callback)