-- Item

local rapi_name = class_gm_to_rapi["class_item"]
Item = _CLASS[rapi_name]



-- ========== Enums ==========

-- Moved to ItemTier
-- Item.Tier = ReadOnly.new({
--     COMMON      = 0,
--     UNCOMMON    = 1,
--     RARE        = 2,
--     EQUIPMENT   = 3,
--     BOSS        = 4,
--     SPECIAL     = 5,
--     FOOD        = 6,
--     NOTIER      = 7
-- })


-- $enum
Item.LootTag = ReadOnly.new({
    CATEGORY_DAMAGE                 = 1,
    CATEGORY_HEALING                = 2,
    CATEGORY_UTILITY                = 4,
    EQUIPMENT_BLACKLIST_ENIGMA      = 8,
    EQUIPMENT_BLACKLIST_CHAOS       = 16,
    EQUIPMENT_BLACKLIST_ACTIVATOR   = 32,
    ITEM_BLACKLIST_ENGI_TURRETS     = 64,
    ITEM_BLACKLIST_VENDOR           = 128,
    ITEM_BLACKLIST_INFUSER          = 256
})


-- $enum
Item.StackKind = ReadOnly.new({
    NORMAL          = 0,
    TEMPORARY_BLUE  = 1,
    TEMPORARY_RED   = 2,
    ANY             = 3,
    TEMPORARY_ANY   = 4
})



-- ========== Static Methods ==========

-- $static
-- $return  Item
-- $param   identifier  | string    | The identifier for the item.
--[[
Creates a new item with the given identifier if it does not already exist,
or returns the existing one if it does.
]]
Item.new = function(namespace, identifier)
    Initialize.internal.check_if_done()
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


-- $static
-- $name        find
-- $return      Item
-- $param       identifier  | string    | The identifier to search for.
-- $optional    namespace   | string    | The namespace to search in.
--[[
Searches for the specified item and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]


-- $static
-- $name        find_all
-- $return      table, bool
-- $param       filter      |           | description $Item.new, Item#new$
-- $optional    property    | number    | description
--[[
description $Item.new, Item#new$
]]


-- $static
-- $name        wrap
-- $return      Item
-- $param       item_id     | number    | The item ID to wrap.
--[[
description
]]



-- ========== Instance Methods ==========

methods_class[rapi_name] = {

    -- $instance
    -- $return      Instance
    -- $param       x       | number    | The x spawn coordinate.
    -- $param       y       | number    | The y spawn coordinate.
    -- $optional    target  | Instance  | If provided, the drop will move towards the target instance's position. <br>The position is determined on spawn, and does not follow the instance if they move. <br>If `nil`, will drop in a random direction around the spawn location.
    --[[
    Spawns and returns an item drop.
    ]]
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
        local pools = Global.treasure_loot_pools
        for i = 1, #pools do
            local struct = pools[i]
            local drop_pool = List.wrap(struct.drop_pool)
            local pos = drop_pool:find(self.object_id)
            if pos then drop_pool:delete(pos) end
        end

        -- Add to new loot pool (if it exists)
        local pool = ItemTier.wrap(tier).item_pool_for_reroll
        if pool ~= -1 then LootPool.wrap(pool):add(self) end
    end,


    set_loot_tags = function(self, ...)
        local args = {...}
        if type(args[1]) == "table" then args = args[1] end

        local tags = 0
        for _, tag in ipairs(args) do tags = tags + tag end

        self.loot_tags = tags
    end

}