-- Item

local rapi_name = class_gm_to_rapi["class_item"]
Item = _CLASS[rapi_name]



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
token_name      | string    | 
token_text      | string    | 
on_acquired     | number    | The ID of the callback that runs when the item is acquired.
on_removed      | number    | The ID of the callback that runs when the item is removed.
tier            | number    | The tier of the item.
sprite_id       | number    | The sprite ID of the item.
object_id       | number    | The object ID of the item.
item_log_id     | number    | The item log ID of the item.
achievement_id  | number    | The achievement ID of the item. <br>If *not* `-1`, the item will be locked until the achievement is unlocked.
is_hidden       | bool      | 
effect_display  |           | 
actor_component |           | 
loot_tags       | number    | The sum of all loot tags applied to the item.
is_new_item     | bool      | `true` for new vanilla items added in *Returns*, and for new modded items.
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
    Initialize.internal.check_if_done()
    if not identifier then log.error("No identifier provided", 2) end

    -- Return existing item if found
    local item = Item.find(identifier, namespace)
    if item then return item end

    -- Create new pickup item object
    local holder = ffi.new("struct RValue*[3]")
    holder[0] = RValue.new(namespace)
    holder[1] = RValue.new(identifier)
    holder[2] = RValue.new(gm.constants.pPickupItem)
    local object = RValue.new(0)
    gmf.object_add_w(nil, nil, object, 3, holder)

    -- Create new item
    -- TODO: Pass proper args for this
    local holder = ffi.new("struct RValue*[6]")
    holder[0] = RValue.new(namespace)
    holder[1] = RValue.new(identifier)
    holder[2] = nil                 -- item ID; TODO leave as nil somehow to have it auto-set
    holder[3] = RValue.new(7)       -- tier; TODO use ItemTier.NOTIER
    holder[4] = object
    holder[5] = RValue.new(0)       -- loot_tags (?)
    local out = RValue.new(0)
    gmf.item_create(nil, nil, out, 6, holder)
    local item = Item.wrap(RValue.to_wrapper(out))

    -- Remove `is_new_item` flag
    item.is_new_item = false

    return item
end


--$static
--$name         find
--$return       Item
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
]]


--$static
--$name         wrap
--$return       Item
--$param        item_id     | number    | The item ID to wrap.
--[[
Returns an Item wrapper containing the provided item ID.
]]



-- ========== Instance Methods ==========

