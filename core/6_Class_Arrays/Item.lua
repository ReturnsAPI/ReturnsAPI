-- Item

local name_rapi = class_name_g2r["class_item"]
Item = __class[name_rapi]



-- ========== Enums ==========

--$enum
--$name Property
--[[
NAMESPACE           0
IDENTIFIER          1
TOKEN_NAME          2
TOKEN_TEXT          3
ON_ACQUIRED         4
ON_REMOVED          5
TIER                6
SPRITE_ID           7
OBJECT_ID           8
ITEM_LOG_ID         9
ACHIEVEMENT_ID      10
IS_HIDDEN           11
EFFECT_DISPLAY      12
ACTOR_COMPONENT     13
LOOT_TAGS           14
IS_NEW_ITEM         15
]]


--$enum
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


--$enum
Item.StackKind = ReadOnly.new({
    NORMAL          = 0,
    TEMPORARY_BLUE  = 1,
    TEMPORARY_RED   = 2,
    ANY             = 3,
    TEMPORARY_ANY   = 4
})


--$properties
--[[
namespace       | string    | The namespace the item is in.
identifier      | string    | The identifier for the item within the namespace.
token_name      | string    | The localization token for the item's name.
token_text      | string    | The localization token for the item's pickup text.
on_acquired     | number    | The ID of the callback that runs when the item is acquired.
on_removed      | number    | The ID of the callback that runs when the item is removed.
tier            | number    | The tier of the item.
sprite_id       | sprite    | The sprite ID of the item.
object_id       | object    | The object ID of the item.
item_log_id     | number    | The item log ID of the item.
achievement_id  | number    | The achievement ID of the item. <br>If *not* `-1`, the item will be locked until the achievement is unlocked.
is_hidden       | bool      | 
effect_display  |           | 
actor_component |           | 
loot_tags       | number    | The sum of all loot tags applied to the item.
is_new_item     | bool      | `true` for new vanilla items added in *Returns*.
]]



-- ========== Static Methods ==========

--$static
--$return   Item
--$param    identifier  | string    | The identifier for the item.
--[[
Creates a new item with the given identifier if it does not already exist,
or returns the existing one if it does.
]]
Item.new = function(namespace, identifier)
    Initialize.internal.check_if_started()
    if not identifier then log.error("No identifier provided", 2) end

    -- Return existing item if found
    local item = Item.find(identifier, namespace)
    if item then return item end

    -- Create new
    item = Item.wrap(GM.item_create(
        namespace,
        identifier,
        nil,    -- item ID; if nil, it is auto-set
        ItemTier.NOTIER,
        GM.object_add_w(namespace, identifier, gm.constants.pPickupItem),
        0       -- loot_tags (?)
    ))

    -- Remove `is_new_item` flag
    item.is_new_item = false

    return item
end


--$static
--$name         find
--$return       Item or nil
--$param        identifier  | string    | The identifier to search for.
--$optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified item and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]


--$static
--$name         find_all
--$return       table, bool
--$param        filter      |           | The filter to search by.
--$optional     property    | number    | The property to check. <br>$`Item.Property.NAMESPACE`, Item#Property$ by default.
--[[
Returns a table of items matching the specified filter and property,
and a boolean that is `true` if the table is *not* empty.

**NOTE:** Filtering by a non-namespace property is *very slow*!
Try not to do that too much.
]]


--$static
--$name         wrap
--$return       Item
--$param        item_id     | number    | The item ID to wrap.
--[[
Returns an Item wrapper containing the provided item ID.
]]



-- ========== Instance Methods ==========

methods_class[name_rapi] = Util.table_merge(methods_class[name_rapi], {

    --$instance
    --$name         show_properties
    --[[
    Prints the item's properties.
    ]]


    --$instance
    --$return       Instance
    --$param        x           | number    | The x spawn coordinate.
    --$param        y           | number    | The y spawn coordinate.
    --$optional     target      | Instance  | If provided, the drop will move towards the target instance's position. <br>The position is determined on spawn, and does not follow the instance if they move. <br>If `nil`, will drop in a random direction around the spawn location.
    --[[
    Spawns and returns an item drop.
    ]]
    create = function(self, x, y, target)
        local object_id = self.object_id
        if object_id == nil or object_id == -1 then return nil end

        -- This function spawns the item 40 px above, so add 40 to y in the call
        local holder = RValue.new_holder_scr(5)
        holder[0] = RValue.new(object_id)
        holder[1] = RValue.new(x)
        holder[2] = RValue.new(y + 40)
        holder[3] = RValue.from_wrapper(target)
        holder[4] = RValue.new(false)
        gmf.item_drop_object(nil, nil, RValue.new(0), 5, holder)

        -- Look for drop (because gm.item_drop_object does not actually return the instance for some reason)
        local drop = nil
        local drops = Instance.find_all(gm.constants.pPickupItem) --, gm.constants.oCustomObject_pPickupItem)   -- TODO custom items
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


    --$instance
    --$param        sprite      | Sprite    | The sprite to set.
    --[[
    Sets the sprite of the item.
    ]]
    set_sprite = function(self, sprite)
        sprite = Wrap.unwrap(sprite)
        self.sprite_id = sprite
    
        -- Set item object sprite
        local holder = RValue.new_holder_scr(2)
        holder[0] = RValue.new(self.object_id)
        holder[1] = RValue.new(sprite)
        gmf.object_set_sprite_w(nil, nil, RValue.new(0), 2, holder)
    end,


    --$instance
    --$param        tier        | number   | The $tier, <insert link>$ to set.
    --[[
    Sets the tier of the item, and assigns it to the appropriate
    loot pool (will remove from all previous loot pools).
    ]]
    set_tier = function(self, tier)
        tier = Wrap.unwrap(tier)
        self.tier = tier

        -- Remove from all loot pools that the item is in
        local pools = Global.treasure_loot_pools    -- Array
        for _, struct in ipairs(pools) do
            local drop_pool = List.wrap(struct.drop_pool)
            drop_pool:delete_value(self.object_id)
        end

        -- Add to new loot pool (if it exists)
        local pool = ItemTier.wrap(tier).item_pool_for_reroll
        if pool ~= -1 then LootPool.wrap(pool):add(self) end
    end,


    --$instance
    --$param        ...         | number(s) | A variable number of $loot tags, Item#LootTag$ to add.
    --[[
    Sets the loot tags of the item.
    ]]
    set_loot_tags = function(self, ...)
        local args = {...}
        if type(args[1]) == "table" then args = args[1] end

        -- Sum variable number of tags
        local tags = 0
        for _, tag in ipairs(args) do tags = tags + tag end

        self.loot_tags = tags
    end

})