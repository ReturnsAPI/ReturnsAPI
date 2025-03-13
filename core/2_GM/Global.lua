-- Global

Global = new_class()

local structures = {}



-- ========== Internal ==========

Global.internal.initialize = function()
    -- Cache for some globals; add to it if needed
    structures = {
        item_log_display_list   = List.wrap(GM.variable_global_get("item_log_display_list")),
        item_tiers              = GM.variable_global_get("item_tiers"),
        custom_object           = GM.variable_global_get("custom_object"),
        treasure_loot_pools     = GM.variable_global_get("treasure_loot_pools")
    }
end



-- ========== Metatables ==========

metatable_global = {
    __index = function(t, k)
        if structures[k] then return structures[k] end

        local holder = ffi.new("struct RValue[1]")
        holder[0] = RValue.new(Wrap.unwrap(k))
        local out = RValue.new(0)
        gmf.variable_global_get(out, nil, nil, 1, holder)
        return RValue.to_wrapper(out)
    end,


    __newindex = function(t, k, v)
        if structures[k] then log.error("Do not set global variable '"..k.."'", 2) end
        
        local holder = ffi.new("struct RValue[2]")
        holder[0] = RValue.new(Wrap.unwrap(k))
        holder[1] = RValue.new(Wrap.unwrap(v))
        gmf.variable_global_set(RValue.new(0), nil, nil, 2, holder)
    end,


    __metatable = "RAPI.Class.Global"
}
setmetatable(Global, metatable_global)



_CLASS["Global"] = Global
_CLASS_MT["Global"] = metatable_global