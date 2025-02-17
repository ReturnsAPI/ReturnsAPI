-- ItemTier

ItemTier = {}

item_tier_find_table = {}



-- ========== Constants ==========

local tier_constants = {
    COMMON      = 0,
    UNCOMMON    = 1,
    RARE        = 2,
    EQUIPMENT   = 3,
    BOSS        = 4,
    SPECIAL     = 5,
    FOOD        = 6,
    NOTIER      = 7
}

-- Add to class table directly (e.g., ItemTier.COMMON)
for k, v in pairs(tier_constants) do
    ItemTier[k] = v
end



-- ========== Static Methods ==========

ItemTier.new = function(namespace, identifier)
    if not identifier then log.error("No identifier provided", 2) end

    -- Return existing tier if found
    local tier = ItemTier.find(identifier, namespace)
    if tier then return tier end

    local tiers_array = Array.wrap(gm.variable_global_get("item_tiers"))
    tier = #tiers_array

    -- Create new struct for tier
    local tier_struct = gm.struct_create()
    tier_struct.index                       = tier
    tier_struct.text_color                  = "w"
    tier_struct.pickup_color                = Color.WHITE
    tier_struct.pickup_color_bright         = Color.WHITE
    tier_struct.item_pool_for_reroll        = tier
    tier_struct.equipment_pool_for_reroll   = tier
    tier_struct.ignore_fair                 = false
    tier_struct.fair_item_value             = 1
    tier_struct.pickup_particle_type        = -1
    tier_struct.spawn_sound                 = 57

    -- Push onto array
    tiers_array:push(tier_struct)

    -- Add to find table
    if not item_tier_find_table[namespace] then item_tier_find_table[namespace] = {} end
    item_tier_find_table[namespace][identifier] = tier
    item_tier_find_table[tier] = {namespace, identifier}

    return tier
end


ItemTier.find = function(identifier, namespace, default_namespace)
    -- Search in namespace
    local namespace_table = item_tier_find_table[namespace]
    if namespace_table then
        local id = namespace_table[identifier]
        if id then return id end
    end

    -- Also check vanilla tiers if no namespace arg
    if namespace == default_namespace then
        local id = tier_constants[identifier:upper()]
        if id then return id end
    end

    return nil
end



_CLASS["ItemTier"] = ItemTier