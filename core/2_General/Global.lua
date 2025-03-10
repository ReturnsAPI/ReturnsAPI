-- Global

Global = new_class()

local structures = {}



-- ========== Internal ==========

Global.internal.initialize = function()
    -- Cache for some globals; add to it if needed
    structures = {
        item_tiers              = Array.wrap(gm.variable_global_get("item_tiers")),
        treasure_loot_pools     = Array.wrap(gm.variable_global_get("treasure_loot_pools")),
    }
end



-- ========== Metatables ==========

metatable_global = {
    __index = function(t, k)
        if structures[k] then return structures[k] end
        return Wrap.wrap(gm.variable_global_get(k))
    end,


    __newindex = function(t, k, v)
        if structures[k] then log.error("Do not set global variable '"..k.."'", 2) end
        gm.variable_global_set(k, Wrap.unwrap(v))
    end,


    __metatable = "RAPI.Class.Global"
}
setmetatable(Global, metatable_global)



_CLASS["Global"] = Global
_CLASS_MT["Global"] = metatable_global