-- Item

---@class ItemClass
Item = C["Item"]

local proxy              = P.proxy
local metatable          = W["Item"]
local find_table_wrapper = P.class_find_tables_wrapper["Item"]
local find_table_array   = P.class_find_tables_array["Item"]

local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class Item
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.

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
-- Item.new = function(NAMESPACE, identifier)

-- end

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

-- Insert other methods before `print`

--[[
Prints the item's properties.
]]
methods.print = function(self) end