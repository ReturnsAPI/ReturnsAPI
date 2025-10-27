-- Item

local name_rapi = class_name_g2r["class_item"]
Item = __class[name_rapi]

run_once(function()
    __actors_holding_item   = {}
    __toggle_loot_off       = {}    -- Items that are toggled off from dropping
end)

queue_run_update_available_loot = false



-- ========== Enums ==========

--@section Enums

--@enum
--@name Property
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


--@enum
Item.LootTag = {
    CATEGORY_DAMAGE                 = 1,
    CATEGORY_HEALING                = 2,
    CATEGORY_UTILITY                = 4,
    EQUIPMENT_BLACKLIST_ENIGMA      = 8,
    EQUIPMENT_BLACKLIST_CHAOS       = 16,
    EQUIPMENT_BLACKLIST_ACTIVATOR   = 32,
    ITEM_BLACKLIST_ENGI_TURRETS     = 64,
    ITEM_BLACKLIST_VENDOR           = 128,
    ITEM_BLACKLIST_INFUSER          = 256
}


--@enum
Item.StackKind = {
    NORMAL          = 0,
    TEMPORARY_BLUE  = 1,
    TEMPORARY_RED   = 2,
    ANY             = 3,
    TEMPORARY_ANY   = 4
}



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The item ID being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.

<br>

Property | Type | Description
| - | - | -
`namespace`         | string    | The namespace the item is in.
`identifier`        | string    | The identifier for the item within the namespace.
`token_name`        | string    | The localization token for the item's name.
`token_text`        | string    | The localization token for the item's pickup text.
`on_acquired`       | number    | The ID of the callback that runs when the item is acquired. <br>The callback function should have the arguments `actor, stack`.
`on_removed`        | number    | The ID of the callback that runs when the item is removed. <br>The callback function should have the arguments `actor, stack`.
`tier`              | number    | The tier of the item.
`sprite_id`         | sprite    | The sprite ID of the item.
`object_id`         | object    | The object ID of the item.
`item_log_id`       | number    | The item log ID of the item.
`achievement_id`    | number    | The achievement ID of the item. <br>If *not* `-1`, the item will be locked until the achievement is unlocked.
`is_hidden`         | bool      | 
`effect_display`    | EffectDisplay | 
`actor_component`   |           | 
`loot_tags`         | number    | The *sum* of all loot tags applied to the item. <br>(E.g., `Item.LootTag.CATEGORY_DAMAGE + Item.LootTag.CATEGORY_HEALING` will add the damage and healing tags.)
`is_new_item`       | bool      | `true` for new vanilla items added in *Returns*.
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return   Item
--@param    identifier  | string    | The identifier for the item.
--[[
Creates a new item with the given identifier if it does not already exist,
or returns the existing one if it does.
]]
Item.new = function(NAMESPACE, identifier)
    Initialize.internal.check_if_started("Item.new")
    if not identifier then log.error("Item.new: No identifier provided", 2) end

    -- Return existing item if found
    local item = Item.find(identifier, NAMESPACE, true)
    if item then return item end

    -- Create new
    item = Item.wrap(gm.item_create(
        NAMESPACE,
        identifier,
        nil,    -- item ID; if nil, it is auto-set
        ItemTier.NOTIER,
        gm.object_add_w(NAMESPACE, identifier, gm.constants.pPickupItem),
        0       -- loot_tags (?)
    ))

    -- Remove `is_new_item` flag
    item.is_new_item = false

    return item
end


--@static
--@name         find
--@return       Item or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified item and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]


--@static
--@name         find_all
--@return       table
--@param        filter      |           | The filter to search by.
--@optional     property    | number    | The property to check. <br>@link {`Item.Property.NAMESPACE` | Item#Property} by default.
--[[
Returns a table of items matching the specified filter and property.

**NOTE:** Filtering by a non-namespace property is *very slow*!
Try not to do that too much.
]]


--@static
--@name         wrap
--@return       Item
--@param        id          | number    | The item ID to wrap.
--[[
Returns an Item wrapper containing the provided item ID.
]]



-- ========== Instance Methods ==========

--@section Instance Methods

Util.table_append(methods_class_array[name_rapi], {

    --@instance
    --@name         print_properties
    --[[
    Prints the item's properties.
    ]]


    --@instance
    --@return       Instance
    --@param        x           | number    | The x spawn coordinate.
    --@param        y           | number    | The y spawn coordinate.
    --@optional     target      | Instance  | If provided, the drop will move towards the target instance's position. <br>The position is determined on spawn, and does not follow the instance if they move. <br>If `nil`, will drop in a random direction around the spawn location.
    --[[
    Spawns and returns an item drop.
    ]]
    create = function(self, x, y, target)
        local object_id = self.object_id
        if object_id == nil or object_id == -1 then return nil end

        -- This function spawns the item 40 px above, so add 40 to y in the call        
        gm.item_drop_object(object_id, x, y + 40, Wrap.unwrap(target), false)

        -- Look for drop (because gm.item_drop_object does not actually return the instance for some reason)
        local drop = nil
        local objs = {gm.constants.pPickupItem, gm.constants.oCustomObject_pPickupItem}
        for _, obj in ipairs(objs) do
            local drops = Instance.find_all(obj)
            for _, d in ipairs(drops) do
                local dData = Instance.get_data(d)
                if math.abs(d.x - x) <= 1 and math.abs(d.y - y) <= 1
                and (not dData.returned_drop) then
                    drop = d
                    dData.returned_drop = true
                    break
                end
            end
            if drop then break end
        end

        return drop
    end,


    --@instance
    --@param        sprite      | Sprite    | The sprite to set.
    --[[
    Sets the sprite of the item.
    ]]
    set_sprite = function(self, sprite)
        sprite = Wrap.unwrap(sprite)
        self.sprite_id = sprite
    
        -- Set item object sprite
        gm.object_set_sprite_w(self.object_id, sprite)
    end,


    --@instance
    --@param        tier        | number   | The @link {tier | ItemTier#constants} to set.
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
        if pool ~= -1 then LootPool.wrap(pool):add_item(self) end
    end,


    --@instance
    --@return       table
    --[[
    Returns a table of all actors that currently hold at least 1 stack of the item.
    ]]
    get_holding_actors = function(self)
        local t = {}

        for actor_id, _ in pairs(__actors_holding_item[self.value]) do
            table.insert(t, Instance.wrap(actor_id))
        end

        return t
    end,


    --@instance
    --@return       bool
    --[[
    Returns `true` if the item is available as a drop in at least one loot pool.
    ]]
    is_loot = function(self)
        if __toggle_loot_off[self.value] then return false end

        -- Loop through all pools
        local count = #Global.treasure_loot_pools
        for i = 0, count - 1 do
            local pool = LootPool.wrap(i)

            -- Check if this item's object is in `drop_pool` outside of a run
            -- Check if this item's object is in `available_drop_pool` instead
            -- while in a run just in case that got modified
            local which = "drop_pool"
            if Global.__run_exists then which = "available_drop_pool" end
            if List.wrap(pool[which]):contains(self.object_id) then
                return true
            end
        end

        return false
    end,


    --@instance
    --@param        bool        | bool      | `true` - The item can drop as loot. <br>`false` - The item cannot drop as loot.
    --[[
    Toggles whether or not the item is available to drop from the loot pools it's in.

    *Technical:* When `gm.run_update_available_loot` is called, the item is removed
    from all `available_drop_pool`s if toggled off; `drop_pool` is *not* modified.
    ]]
    toggle_loot = function(self, bool)
        if type(bool) ~= "boolean" then log.error("toggle_loot: bool is invalid", 2) end

        __toggle_loot_off[self.value] = nil
        if not bool then __toggle_loot_off[self.value] = self.object_id end

        -- Force-update `available_drop_pool`s while in a run
        if Global.__run_exists then queue_run_update_available_loot = true end
    end,


    --@instance
    --@return       table
    --[[
    Returns a table of all @link {LootPools | LootPools} the item is in, ignoring @link {`toggle_loot` | Item#toggle_loot}.
    ]]
    get_loot_pools = function(self)
        local pools = {}

        -- Loop through all pools
        for i = 0, #Global.treasure_loot_pools - 1 do
            local pool = LootPool.wrap(i)

            -- Check if this item's object is in the pool
            if List.wrap(pool.drop_pool):contains(self.object_id) then
                table.insert(pools, pool)
            end
        end

        return pools
    end,


    --@instance
    --@return       table
    --[[
    Returns a table of all @link {LootPools | LootPools} the item is available to drop from.
    ]]
    get_available_loot_pools = function(self)
        if __toggle_loot_off[self.value] then return {} end

        local pools = {}

        -- Loop through all pools
        for i = 0, #Global.treasure_loot_pools - 1 do
            local pool = LootPool.wrap(i)

            -- Check if this item's object is in `drop_pool` outside of a run
            -- Check if this item's object is in `available_drop_pool` instead
            -- while in a run just in case that got modified
            local which = "drop_pool"
            if Global.__run_exists then which = "available_drop_pool" end
            if List.wrap(pool[which]):contains(self.object_id) then
                table.insert(pools, pool)
            end
        end

        return pools
    end,


    --@instance
    --@return       Achievement
    --[[
    Returns the associated @link {Achievement | Achievement} if it exists,
    or an invalid Achievement if it does not.
    ]]
    get_achievement = function(self)
        return Achievement.wrap(self.achievement_id)
    end

})



-- ========== Hooks ==========

-- Create item subtable in `__actors_holding_item`

gm.post_script_hook(gm.constants.item_create, function(self, other, result, args)
    __actors_holding_item[result.value] = {}
end)


-- Add to/remove from `__actors_holding_item`

gm.post_script_hook(gm.constants.item_give_internal, function(self, other, result, args)
    local actor_id  = Instance.wrap(args[1].value).id
    local item_id   = args[2].value

    __actors_holding_item[item_id][actor_id] = true
    __actors_holding_item[actor_id] = __actors_holding_item[actor_id] or {}
    __actors_holding_item[actor_id][item_id] = true
end)

gm.post_script_hook(gm.constants.item_take_internal, function(self, other, result, args)
    local actor     = Instance.wrap(args[1].value)
    local actor_id  = actor.id
    local item_id   = args[2].value

    if actor:item_count(item_id) > 0 then return end

    __actors_holding_item[item_id][actor_id] = nil
    if __actors_holding_item[actor_id] then
        __actors_holding_item[actor_id][item_id] = nil
    end
end)


-- On room change, remove non-existent instances from `__actors_holding_item`

gm.post_script_hook(gm.constants.room_goto, function(self, other, result, args)
    for actor_id, _ in pairs(__actors_holding_item) do
        if actor_id >= 100000
        and (not Instance.exists(actor_id)) then
            for item_id, _ in pairs(__actors_holding_item[actor_id]) do
                __actors_holding_item[item_id][actor_id] = nil
            end
            __actors_holding_item[actor_id] = nil
        end
    end
end)


-- Remove from `__actors_holding_item` on non-player kill

gm.post_script_hook(gm.constants.actor_set_dead, function(self, other, result, args)
    local actor = Instance.wrap(args[1].value)
    local actor_id = actor.id
    if not __actors_holding_item[actor_id] then return end

    -- Do not clear for player deaths
    local obj_ind = actor:get_object_index()
    if obj_ind ~= gm.constants.oP then
        for item_id, _ in pairs(__actors_holding_item[actor_id]) do
            __actors_holding_item[item_id][actor_id] = nil
        end
        __actors_holding_item[actor_id] = nil
    end
end)


-- Add new instance to `__actors_holding_item` and remove old

gm.post_script_hook(gm.constants.actor_transform, function(self, other, result, args)
    local actor_id  = Instance.wrap(args[1].value).id
    if not __actors_holding_item[actor_id] then return end

    local new_id    = Instance.wrap(args[2].value).id
    __actors_holding_item[new_id] = __actors_holding_item[new_id] or {}

    -- For all of prev actor's items, remove prev actor and add new actor
    for item_id, _ in pairs(__actors_holding_item[actor_id]) do
        __actors_holding_item[item_id][actor_id] = nil
        __actors_holding_item[item_id][new_id] = true
        __actors_holding_item[new_id][item_id] = true
    end
    __actors_holding_item[actor_id] = nil
end)


-- Remove items in `__toggle_loot_off` from all `available_drop_pool`s

gm.post_script_hook(gm.constants.run_update_available_loot, function(self, other, result, args)
    -- Loop through all toggled off
    for item, object_id in pairs(__toggle_loot_off) do

        -- Loop through all pools and delete `object_id`
        for i = 0, #Global.treasure_loot_pools - 1 do
            local pool = LootPool.wrap(i)
            List.wrap(pool.available_drop_pool):delete_value(object_id)
        end
    end
end)


Callback.add(RAPI_NAMESPACE, Callback.ON_STEP, function()
    if queue_run_update_available_loot then
        queue_run_update_available_loot = false
        gm.run_update_available_loot()
    end
end)