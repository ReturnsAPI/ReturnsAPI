-- Item

local rapi_name = class_gm_to_rapi["class_item"]
Item = _CLASS[rapi_name]



-- ========== Enums ==========

-- Moved to ItemTier
-- Item.TIER = ReadOnly.new({
--     common      = 0,
--     uncommon    = 1,
--     rare        = 2,
--     equipment   = 3,
--     boss        = 4,
--     special     = 5,
--     food        = 6,
--     notier      = 7
-- })


Item.LOOT_TAG = Proxy.new({
    category_damage                 = 1,
    category_healing                = 2,
    category_utility                = 4,
    equipment_blacklist_enigma      = 8,
    equipment_blacklist_chaos       = 16,
    equipment_blacklist_activator   = 32,
    item_blacklist_engi_turrets     = 64,
    item_blacklist_vendor           = 128,
    item_blacklist_infuser          = 256
})


Item.STACK_KIND = Proxy.new({
    normal          = 0,
    temporary_blue  = 1,
    temporary_red   = 2,
    any             = 3,
    temporary_any   = 4
})



-- ========== Static Methods ==========

Item.new = function(namespace, identifier)
    if not identifier then log.error("No identifier provided", 2) end

    -- Return existing item if found
    local item = Item.find(identifier, namespace)
    if item then return item end

    -- Create new
    -- TODO: Pass proper args for this
    item = Item.wrap(gm.item_create(
        namespace,
        identifier,
        nil,
        7,      -- tier
        gm.object_add_w(namespace, identifier, gm.constants.pPickupItem),
        0       -- loot_tags (?)
    ))

    return item
end



-- ========== Instance Methods ==========

methods_class[rapi_name] = {

    create = function(self, x, y, target)
        local object_id = self.object_id
        if object_id == nil
        or object_id == -1 then return nil end

        -- This function spawns the item 40 px above, so add 40 to y in the call
        gm.item_drop_object(object_id, x, y + 40, Wrap.unwrap(target), false)

        -- Look for drop (because gm.item_drop_object does not actually return the instance for some reason)
        local drop = nil
        local drops = Instance.find_all(gm.constants.pPickupItem) --, gm.constants.oCustomObject_pPickupItem)   -- TODO
        for _, d in ipairs(drops) do
            local dData = Instance.get_data(d)
            if math.abs(d.x - x) <= 1 and math.abs(d.y - y) <= 1
            and (not dData.returned_drop) then
                drop = d
                dData.returned_drop = true
                break
            end
        end

        return drop
    end,


    set_sprite = function(self, sprite)
        sprite = Wrap.unwrap(sprite)
        self.sprite_id = sprite
        gm.object_set_sprite_w(self.object_id, sprite)  -- Set item object sprite
    end,


    set_tier = function(self, tier)
        tier = Wrap.unwrap(tier)
        self.tier = tier

        -- Remove from all loot pools that the item is in
        local pools = Array.wrap(gm.variable_global_get("treasure_loot_pools"))
        for i = 1, #pools do
            local struct = pools[i]
            local drop_pool = List.wrap(struct.drop_pool)
            local pos = drop_pool:find(self.object_id)
            if pos then drop_pool:delete(pos) end
        end

        -- Add to new loot pool
        -- List.wrap(pools:get(tier).drop_pool):add(self.object_id)
        local pool_id = ItemTier.wrap(tier).item_pool_for_reroll
        if pool_id ~= -1 then
            List.wrap(pools:get(pool_id).drop_pool):add(self.object_id)
        end
    end,


    set_loot_tags = function(self, ...)
        local args = {...}
        if type(args[1]) == "table" then args = args[1] end

        local tags = 0
        for _, tag in ipairs(args) do tags = tags + tag end

        self.loot_tags = tags
    end,


    add_to_loot_pool = function(self, pool)
        pool = LootPool.wrap(pool)
        gm.ds_list_add(pool.drop_pool, self.object_id)
    end

}