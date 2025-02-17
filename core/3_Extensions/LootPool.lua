-- LootPool

LootPool = {}

loot_pool_find_table = {}



-- ========== Constants ==========

local pool_constants = {
    COMMON          = 0,
    UNCOMMON        = 1,
    RARE            = 2,
    EQUIPMENT       = 3,
    BOSS            = 4,
    BOSS_EQUIPMENT  = 5,
    FOOD            = 6,
}

-- Add to class table directly (e.g., LootPool.COMMON)
for k, v in pairs(pool_constants) do
    LootPool[k] = v
end



-- ========== Static Methods ==========

LootPool.new = function(namespace, identifier)
    if not identifier then log.error("No identifier provided", 2) end

    -- Return existing tier if found
    local pool = LootPool.find(identifier, namespace)
    if pool then return pool end

    local loot_pools_array = Array.wrap(gm.variable_global_get("treasure_loot_pools"))
    pool = #loot_pools_array

    -- Create new struct for pool
    local loot_struct = gm.struct_create()
    loot_struct.index                       = pool
    loot_struct.item_tier                   = pool
    loot_struct.drop_pool                   = gm.ds_list_create()
    loot_struct.available_drop_pool         = gm.ds_list_create()
    loot_struct.is_equipment_pool           = false
    loot_struct.command_crate_object_id     = 800   -- White crate

    -- Push onto array
    loot_pools_array:push(loot_struct)

    -- Add to find table
    if not loot_pool_find_table[namespace] then loot_pool_find_table[namespace] = {} end
    loot_pool_find_table[namespace][identifier] = pool
    loot_pool_find_table[pool] = {namespace, identifier}

    return loot_struct
end


LootPool.new_from_tier = function(tier)
    -- Automatically populates pool properties
    -- and sets the tier's `_pool_for_reroll` properties to this
    if not tier then log.error("No tier provided", 2) end
    
    -- Create table with tier nsid
    local tier_lookup = item_tier_find_table[tier]
    local loot_struct = LootPool.new(tier_lookup[1], tier_lookup[2])

    -- Set tier properties
    local tiers_array = Array.wrap(gm.variable_global_get("item_tiers"))
    local tier_struct = tiers_array:get(tier)
    local pool_id = pool.index
    tier_struct.item_pool_for_reroll        = pool_id
    tier_struct.equipment_pool_for_reroll   = pool_id

    return loot_struct
end


LootPool.find = function(identifier, namespace, default_namespace)
    -- Search in namespace
    local namespace_table = loot_pool_find_table[namespace]
    if namespace_table then
        local id = namespace_table[identifier]
        if id then
            local loot_pools_array = Array.wrap(gm.variable_global_get("treasure_loot_pools"))
            return loot_pools_array:get(id)
        end
    end

    -- Also check vanilla tiers if no namespace arg
    if namespace == default_namespace then
        local id = pool_constants[identifier:upper()]
        if id then
            local loot_pools_array = Array.wrap(gm.variable_global_get("treasure_loot_pools"))
            return loot_pools_array:get(id)
        end
    end

    return nil
end



_CLASS["LootPool"] = LootPool