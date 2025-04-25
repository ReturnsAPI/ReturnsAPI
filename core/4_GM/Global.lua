-- Global

--[[
Allows for accessing global variables via `Global.<variable>`
]]

Global = new_class()

run_once(function()
    __global_cache = {}
end)



-- ========== Internal ==========

Global.internal.initialize = function()
    -- Cache for some globals; add to it if needed
    make_table_once("__global_cache", {
        artifact_cognation_enemy_blacklist  = Map.wrap(GM.variable_global_get("artifact_cognation_enemy_blacklist")),
        custom_object                       = GM.variable_global_get("custom_object"),
        environment_log_display_list        = List.wrap(GM.variable_global_get("environment_log_display_list")),
        item_log_display_list               = List.wrap(GM.variable_global_get("item_log_display_list")),
        item_tiers                          = GM.variable_global_get("item_tiers"),
        stage_progression_order             = GM.variable_global_get("stage_progression_order"),
        treasure_loot_pools                 = GM.variable_global_get("treasure_loot_pools"),
    })
end



-- ========== Metatables ==========

metatable_global = {
    __index = function(t, k)
        -- Check cache
        if __global_cache[k] then return __global_cache[k] end

        local holder = RValue.new_holder(1)
        holder[0] = RValue.new(k)
        local out = RValue.new(0)
        gmf.variable_global_get(out, nil, nil, 1, holder)
        return RValue.to_wrapper(out)
    end,


    __newindex = function(t, k, v)
        -- Prevent setting any global that is in cache
        if __global_cache[k] then log.error("Do not set global variable '"..k.."'", 2) end
        
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(k)
        holder[1] = RValue.from_wrapper(v)
        gmf.variable_global_set(RValue.new(0), nil, nil, 2, holder)
    end,


    __metatable = "RAPI.Class.Global"
}
setmetatable(Global, metatable_global)



-- Public export
__class.Global = Global
__class_mt.Global = metatable_global