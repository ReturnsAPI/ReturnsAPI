-- Item

---@class ItemClass
Item = C["Item"]

run_on_initial_load(function()
    P.actors_holding_item = {} ---@type table<>
    P.toggle_loot_off     = {} ---@type table<id, object> Items that are toggled off from dropping.
end)

local actors_holding_item = P.actors_holding_item
local toggle_loot_off     = P.toggle_loot_off

local actors

local proxy              = P.proxy
local metatable          = W["Item"]
local find_table_wrapper = P.class_find_tables_wrapper["Item"]
local find_table_array   = P.class_find_tables_array["Item"]

local type               = type
local math               = math
local gm                 = gm  ---@type table<string, function>
local Instance           = Instance
local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap

local queue_run_update_available_loot = false


-- ========== Annotations ==========

---@class Item
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field properties Array The array storing this item's properties.
---@field array Array Alias for `.properties`.

---@class Item
---@field namespace       string        The namespace the item is in.
---@field identifier      string        The identifier for the item within the namespace.
---@field token_name      string        The localization token for the item's name.
---@field token_text      string        The localization token for the item's pickup text.
---@field on_acquired     number        The ID of the callback that runs when the item is acquired. <br>The callback function should have the arguments `actor, stack`. <br>`stack` is the value *after* pickup.
---@field on_removed      number        The ID of the callback that runs when the item is removed. <br>The callback function should have the arguments `actor, stack`. <br>`stack` is the value *before* removal.
---@field tier            number        The tier of the item.
---@field sprite_id       number        The sprite ID of the item.
---@field object_id       number        The object ID of the item.
---@field item_log_id     number        The item log ID of the item.
---@field achievement_id  number        The achievement ID of the item. <br>If *not* `-1`, the item will be locked until the achievement is unlocked.
---@field is_hidden       boolean
---@field effect_display  EffectDisplay
---@field actor_component unknown
---@field loot_tags       number        The *sum* of all loot tags applied to the item. <br>(E.g., `Item.LootTag.CATEGORY_DAMAGE + Item.LootTag.CATEGORY_HEALING` will add the damage and healing tags.)
---@field is_new_item     boolean       `true` for new vanilla items added in *Returns*.


-- ========== Enums ==========

Item.Property = {
    NAMESPACE       = 0,
    IDENTIFIER      = 1,
    TOKEN_NAME      = 2,
    TOKEN_TEXT      = 3,
    ON_ACQUIRED     = 4,
    ON_REMOVED      = 5,
    TIER            = 6,
    SPRITE_ID       = 7,
    OBJECT_ID       = 8,
    ITEM_LOG_ID     = 9,
    ACHIEVEMENT_ID  = 10,
    IS_HIDDEN       = 11,
    EFFECT_DISPLAY  = 12,
    ACTOR_COMPONENT = 13,
    LOOT_TAGS       = 14,
    IS_NEW_ITEM     = 15,
}
local t = {}
for name, num in pairs(Item.Property) do t[num] = name end
for i = 0, #t do Item.Property[i] = t[i] end

Item.LootTag = {
    CATEGORY_DAMAGE               = 1,
    CATEGORY_HEALING              = 2,
    CATEGORY_UTILITY              = 4,
    EQUIPMENT_BLACKLIST_ENIGMA    = 8,
    EQUIPMENT_BLACKLIST_CHAOS     = 16,
    EQUIPMENT_BLACKLIST_ACTIVATOR = 32,
    ITEM_BLACKLIST_ENGI_TURRETS   = 64,
    ITEM_BLACKLIST_VENDOR         = 128,
    ITEM_BLACKLIST_INFUSER        = 256,
}

Item.StackKind = {
    NORMAL         = 0,
    TEMPORARY_BLUE = 1,
    TEMPORARY_RED  = 2,
    ANY            = 3,
    TEMPORARY_ANY  = 4,
}


-- ========== Static Methods ==========

--[[
Creates a new item with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the item.
---@return Item
Item.new = function(NAMESPACE, identifier)
    throw("Method has not been created for this class yet", "new")
end

--[[
Searches for the specified item and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return Item
Item.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all item in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>`Item.Property.NAMESPACE` by default.
---@return table<number, Item>
Item.find_all = function(NAMESPACE, filter, property) end

--[[
Returns an item wrapper containing the provided item ID.
]]
---@param id number | Item The item to wrap.
---@return Item
Item.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class Item
local methods = G.methods_content["Item"]

--[[
Spawns and returns an item drop.
]]
---@param x number The x spawn coordinate.
---@param y number The y spawn coordinate.
---@param target? Instance If provided, the drop will move towards the target instance's position. <br>The position is determined on spawn, and does not follow the instance if they move. <br>If `nil`, will drop in a random direction around the spawn location. <br>`nil` by default.
---@param hack_double? boolean If `true`, spawns 2 drops. <br>`false` by default.
---@return Instance
methods.create = function(self, x, y, target, hack_double)
    if not x then throw("x is nil") end
    if not y then throw("y is nil") end

    local object_id = self.object_id
    if object_id == nil or object_id == -1 then return nil end

    -- This function spawns the item 40 px above,
    -- so add 40 to y in the call        
    gm.item_drop_object(object_id, x, y + 40, unwrap(target), hack_double or false)

    -- Look for drop (because gm.item_drop_object does not
    -- actually return the instance for some reason)
    local drop = nil
    local objs = {
        gm.constants.pPickupItem,
        gm.constants.oCustomObject_pPickupItem,
    }
    for i = 1, 2 do
        local obj = objs[i]
        local drops = Instance.find_all(obj)
        for j = 1, #drops do
            local d = drops[j]
            local drop_data = Instance.get_data(d)
            if math.abs(d.x - x) <= 1 and math.abs(d.y - y) <= 1
            and not drop_data.returned_drop then
                drop = d
                drop_data.returned_drop = true
                break
            end
        end
        if drop then break end
    end

    return drop
end

--[[
Sets the sprite of the item.
]]
---@param sprite number | Sprite The sprite to set.
methods.set_sprite = function(self, sprite)
    if not sprite then throw("sprite is nil") end

    sprite = unwrap(sprite)
    self.sprite_id = sprite

    -- Set item object sprite
    gm.object_set_sprite_w(self.object_id, sprite)
end

--[[
Sets the tier of the item, and assigns it to the appropriate <br>
loot pool (will remove from all previous loot pools).
]]
---@param tier number | ItemTier The @link {tier | ItemTier#constants} to set.
methods.set_tier = function(self, tier)
    if not tier then throw("tier is nil") end
    
    tier = unwrap(tier)
    self.tier = tier

    -- Remove from all loot pools that the item is in
    local pools = Global.treasure_loot_pools  ---@type Array
    for _, struct in ipairs(pools) do
        local drop_pool = List.wrap(struct.drop_pool)
        drop_pool:delete_value(self.object_id)
    end

    -- Add to new loot pool (if it exists)
    local pool = ItemTier.wrap(tier).item_pool_for_reroll
    if pool ~= -1 then LootPool.wrap(pool):add_item(self) end
end

--[[
Returns a table of all actors that currently hold at least 1 stack of the item.
]]
---@return table<number, Actor>
methods.get_holding_actors = function(self)
    if Global.pause and not Net.online then return {} end

    local t, i = {}, 1
    for actor_id, _ in pairs(actors_holding_item[proxy[self]]) do
        t[i] = Instance.wrap(actor_id)
        i = i + 1
    end
    return t
end

--[[
Returns `true` if the item is available as a drop in at least one loot pool.
]]
---@return boolean
methods.is_loot = function(self)
    if toggle_loot_off[proxy[self]] then return false end

    --[[
    Out of run: Check if this item's object is in `drop_pool`
    In a run:   Check if this item's object is in `available_drop_pool` instead
                while in a run just in case that got modified
    ]]
    local which = "drop_pool"
    if Global.__run_exists then which = "available_drop_pool" end

    -- Loop through all pools
    local count = #Global.treasure_loot_pools
    for i = 0, count - 1 do
        local pool = LootPool.wrap(i)
        if List.wrap(pool[which]):contains(self.object_id) then
            return true
        end
    end
    return false
end

--[[
Toggles whether or not the item is available to drop from the loot pools it's in.

*Technical:* When `gm.run_update_available_loot` is called, the item is removed <br>
from all `available_drop_pool`s if toggled off; `drop_pool` is *not* modified.
]]
---@param bool boolean `true` - The item can drop as loot. <br>`false` - The item cannot drop as loot.
methods.toggle_loot = function(self, bool)
    if type(bool) ~= "boolean" then throw("bool is invalid") end

    toggle_loot_off[proxy[self]] = nil
    if not bool then toggle_loot_off[proxy[self]] = self.object_id end

    -- Force-update `available_drop_pool`s while in a run
    if Global.__run_exists then queue_run_update_available_loot = true end
end

--[[
Returns a table of all @link {LootPools | LootPools} the item is in, ignoring @link {`toggle_loot` | Item#toggle_loot}.
]]
---@return table<number, LootPool>
methods.get_loot_pools = function(self)
    -- Loop through all pools
    local pools, i = {}, 1
    for i = 0, #Global.treasure_loot_pools - 1 do
        local pool = LootPool.wrap(i)
        if List.wrap(pool.drop_pool):contains(self.object_id) then
            pools[i] = pool
            i = i + 1
        end
    end
    return pools
end

--[[
Returns a table of all @link {LootPools | LootPools} the item is available to drop from.
]]
---@return table<number, LootPool>
methods.get_available_loot_pools = function(self)
    if toggle_loot_off[proxy[self]] then return {} end

    --[[
    Out of run: Check if this item's object is in `drop_pool`
    In a run:   Check if this item's object is in `available_drop_pool` instead
                while in a run just in case that got modified
    ]]
    local which = "drop_pool"
    if Global.__run_exists then which = "available_drop_pool" end

    -- Loop through all pools
    local pools, j = {}, 1
    for i = 0, #Global.treasure_loot_pools - 1 do
        local pool = LootPool.wrap(i)
        if List.wrap(pool[which]):contains(self.object_id) then
            pools[j] = pool
            j = j + 1
        end
    end
    return pools
end

--[[
Returns the associated @link {Achievement | Achievement} if it exists,
or an invalid Achievement if it does not.
]]
---@return Achievement
methods.get_achievement = function(self)
    return Achievement.wrap(self.achievement_id)
end

--[[
Prints the item's properties.
]]
methods.print = function(self) end


-- ========== Hooks ==========

-- Create item subtable in `actors_holding_item`
gm.post_script_hook(gm.constants.item_create, function(self, other, result, args)
    local item_id = result.value
    actors_holding_item[item_id] = {}
end)

-- Add to/remove from `actors_holding_item`
gm.post_script_hook(gm.constants.item_give_internal, function(self, other, result, args)
    local actor_id = args[1].value.id
    local item_id  = args[2].value

    actors_holding_item[item_id][actor_id] = true
    local t_actor = actors_holding_item[actor_id]
    if not t_actor then
        t_actor = {}
        actors_holding_item[actor_id] = t_actor
    end
    t_actor[item_id] = true

    if gm.event_hook_pre_has(args[1].value, gm.constants.ev_destroy, 0, "actors_holding_item_destroy") then return end
    gm.event_hook_pre_add(args[1].value, gm.constants.ev_destroy, 0, "actors_holding_item_destroy", function(inst)
        local t_actor = actors_holding_item[actor_id]
        if not t_actor then return end
        for item_id, _ in pairs(t_actor) do
            actors_holding_item[item_id][actor_id] = nil
        end
        actors_holding_item[actor_id] = nil
    end)
end)

gm.post_script_hook(gm.constants.item_take_internal, function(self, other, result, args)
    local actor    = args[1].value
    local actor_id = actor.id
    local item_id  = args[2].value

    if actor:item_count(item_id) > 0 then return end

    actors_holding_item[item_id][actor_id] = nil
    local t_actor = actors_holding_item[actor_id]
    if t_actor then
        t_actor[item_id] = nil
    end
end)

-- On room change, remove non-existent instances from `actors_holding_item`
gm.post_script_hook(gm.constants.room_goto, function(self, other, result, args)
    for actor_id, _ in pairs(actors_holding_item) do
        if actor_id >= 100000  -- Make sure this is an actor and not an item
        and not Instance.exists(actor_id) then
            for item_id, _ in pairs(actors_holding_item[actor_id]) do
                actors_holding_item[item_id][actor_id] = nil
            end
            actors_holding_item[actor_id] = nil
        end
    end
end)

-- Remove from `actors_holding_item` on non-player kill
gm.post_script_hook(gm.constants.actor_set_dead, function(self, other, result, args)
    local actor    = args[1].value
    local actor_id = actor.id
    local t_actor  = actors_holding_item[actor_id]
    if not t_actor then return end

    -- Do not clear for player deaths
    local obj_ind = actor:get_object_index()
    if obj_ind ~= gm.constants.oP then
        for item_id, _ in pairs(t_actor) do
            actors_holding_item[item_id][actor_id] = nil
        end
        actors_holding_item[actor_id] = nil
    end
end)

-- Add new instance to `actors_holding_item` and remove old
gm.post_script_hook(gm.constants.actor_transform, function(self, other, result, args)
    local actor_id = args[1].value.id
    local t_actor  = actors_holding_item[actor_id]
    if not t_actor then return end

    local new_id = args[2].value.id
    local t_new = actors_holding_item[new_id]
    if not t_new then
        t_new = {}
        actors_holding_item[new_id] = t_new
    end

    -- For all of prev actor's items, remove prev actor and add new actor
    for item_id, _ in pairs(t_actor) do
        actors_holding_item[item_id][actor_id] = nil
        actors_holding_item[item_id][new_id] = true
        t_new[item_id] = true
    end
    actors_holding_item[actor_id] = nil
end)

-- Remove instance from `actors_holding_item` on client disconnect
gm.post_script_hook(gm.constants.disconnect_player, function(self, other, result, args)
    if not Global.__run_exists then return end

    local player_id = args[1].value.id
    local t_actor   = actors_holding_item[player_id]
    if not t_actor then return end

    for item_id, _ in pairs(t_actor) do
        actors_holding_item[item_id][player_id] = nil
    end
    actors_holding_item[player_id] = nil
end)

-- Remove items in `toggle_loot_off` from all `available_drop_pool`s
Callback.add(RAPI_NAMESPACE, Callback.ON_STEP, Callback.internal.FIRST, function()
    if queue_run_update_available_loot then
        queue_run_update_available_loot = false
        gm.run_update_available_loot()
    end
end)

gm.post_script_hook(gm.constants.run_update_available_loot, function(self, other, result, args)
    -- Loop through all toggled off
    for _, object_id in pairs(toggle_loot_off) do

        -- Loop through all pools and delete `object_id`
        for i = 0, #Global.treasure_loot_pools - 1 do
            local pool = LootPool.wrap(i)
            List.wrap(pool.available_drop_pool):delete_value(object_id)
        end
    end
end)