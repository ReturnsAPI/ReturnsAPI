-- LootPool

LootPool = new_class()

loot_pool_find_table = {}



-- ========== Constants ==========

local pool_constants = {
    COMMON          = 0,
    UNCOMMON        = 1,
    RARE            = 2,
    EQUIPMENT       = 3,
    BOSS            = 4,
    BOSS_EQUIPMENT  = 5,
    FOOD            = 6
}
local pool_constants_flipped = {}

-- Add to LootPool directly (e.g., LootPool.COMMON)
for k, v in pairs(pool_constants) do
    LootPool[k] = v
    pool_constants_flipped[v] = k
end



-- ========== Static Methods ==========

LootPool.new = function(namespace, identifier)
    Initialize.internal.check_if_done()
    if not identifier then log.error("No identifier provided", 2) end

    -- Return existing pool if found
    local pool = LootPool.find(identifier, namespace)
    if pool then return pool end

    local loot_pools_array = Global.treasure_loot_pools
    pool = #loot_pools_array

    -- Create new struct for pool
    local loot_struct = Struct.new()
    loot_struct.namespace                   = namespace     -- RAPI custom variable
    loot_struct.identifier                  = identifier    -- RAPI custom variable
    loot_struct.index                       = pool
    loot_struct.item_tier                   = pool
    loot_struct.drop_pool                   = List.new()
    loot_struct.available_drop_pool         = List.new()
    loot_struct.is_equipment_pool           = false
    loot_struct.command_crate_object_id     = 800   -- White crate

    -- Push onto array
    loot_pools_array:push(loot_struct)

    -- Add to find table
    if not loot_pool_find_table[namespace] then loot_pool_find_table[namespace] = {} end
    loot_pool_find_table[namespace][identifier] = pool
    loot_pool_find_table[pool] = {namespace = namespace, identifier = identifier}

    return LootPool.wrap(pool)
end


LootPool.new_from_tier = function(namespace, tier)
    Initialize.internal.check_if_done()
    
    -- Automatically populates pool properties
    -- and sets the tier's `_pool_for_reroll` properties to this
    if not tier then log.error("No tier provided", 2) end
    tier = Wrap.unwrap(tier)
    
    -- Create table with tier nsid
    local tier_lookup = item_tier_find_table[tier]
    if not tier_lookup then tier_lookup = {namespace = nil, identifier = pool_constants_flipped[tier]} end
    local pool = LootPool.new(namespace, tier_lookup.identifier)

    -- Set tier properties
    local tiers_array = Global.item_tiers
    local tier_struct = tiers_array:get(tier)
    tier_struct.item_pool_for_reroll        = pool.value
    tier_struct.equipment_pool_for_reroll   = pool.value

    return pool
end


LootPool.find = function(identifier, namespace, default_namespace)
    -- Search in namespace
    local namespace_table = loot_pool_find_table[namespace]
    if namespace_table then
        local id = namespace_table[identifier]
        if id then return LootPool.wrap(id) end
    end

    -- Also check vanilla tiers if no namespace arg
    if namespace == default_namespace then
        local id = pool_constants[identifier:upper()]
        if id then return LootPool.wrap(id) end
    end

    return nil
end


LootPool.wrap = function(pool)
    return Proxy.new(Wrap.unwrap(pool), metatable_loot_pool)
end



-- ========== Instance Methods ==========

methods_loot_pool = {

    add = function(self, item)
        List.wrap(self.drop_pool):add(Item.wrap(item).object_id)
    end,


    remove = function(self, item)
        List.wrap(self.drop_pool):delete_value(Item.wrap(item).object_id)
    end,


    roll = function(self, required_loot_tags, disallowed_loot_tags)
        local required_sum, disallowed_sum = required_loot_tags or 0, disallowed_loot_tags or 0

        if type(required_loot_tags) == "table" then
            required_sum = 0
            for _, v in ipairs(required_loot_tags) do
                required_sum = required_sum + v
            end
        end

        if type(disallowed_loot_tags) == "table" then
            disallowed_sum = 0
            for _, v in ipairs(disallowed_loot_tags) do
                disallowed_sum = disallowed_sum + v
            end
        end
        
        local holder = RValue.new_holder_scr(3)
        holder[0] = RValue.new(self.value)
        holder[1] = RValue.new(required_sum)
        holder[2] = RValue.new(disallowed_sum)
        local out = RValue.new(0)
        gmf.treasure_loot_pool_roll(nil, nil, out, 3, holder)
        local obj_id = out.value

        local holder = RValue.new_holder_scr(1)
        holder[0] = RValue.new(obj_id)
        local out = RValue.new(0)
        gmf.object_to_item(nil, nil, out, 1, holder)
        local item = out.value

        if item ~= -1 then item = Item.wrap(item)
        else item = nil
        end

        -- Return both the Item wrapper and item object_index
        return item, obj_id
    end,


    new_command_crate = function(self)
        -- TODO generates a new command crate object for the loot pool
    end,

}



-- ========== Metatables ==========

metatable_loot_pool = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(t) end
        if k == "RAPI" then return getmetatable(t):sub(14, -1) end

        -- Methods
        if methods_loot_pool[k] then
            return methods_loot_pool[k]
        end

        -- Getter
        local loot_struct = Global.treasure_loot_pools:get(Proxy.get(t))
        return loot_struct[k]
    end,


    __newindex = function(t, k, v)
        -- Setter
        local loot_struct = Global.treasure_loot_pools:get(Proxy.get(t))
        loot_struct[k] = Wrap.unwrap(v)
    end,

    
    __metatable = "RAPI.Wrapper.LootPool"
}



-- ========== Hooks ==========

-- Custom loot pools are not auto-populated by the game
memory.dynamic_hook("RAPI.loot_pool_populate", "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.run_create),
    -- Pre-hook
    {nil,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
        local loot_pools_array = Global.treasure_loot_pools
        size = #loot_pools_array

        for i = 7, size - 1 do
            local pool_struct = loot_pools_array:get(i)
            local drop_pool = List.wrap(pool_struct.drop_pool)
            local available_drop_pool = List.wrap(pool_struct.available_drop_pool)
            available_drop_pool:clear()

            local list_size = #drop_pool
            for j = 0, list_size - 1 do
                local item_obj = drop_pool:get(j)

                -- TODO check if item is unlocked first

                available_drop_pool:add(item_obj)
            end
        end
    end}
)



__class.LootPool = LootPool