-- @section my section
--[[
this is text
line 2 @link {some text | Item#Property} yeyeye

line 4      (skipped one)
]]


-- @enum
-- @name Property
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


-- @enum
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


-- @constants
--[[
ON_LOAD 0
POST_LOAD 1
ON_STEP 2
PRE_STEP 3
POST_STEP 4
ON_DRAW 5
PRE_HUD_DRAW 6
ON_HUD_DRAW 7
POST_HUD_DRAW 8
CAMERA_ON_VIEW_CAMERA_UPDATE 9
ON_SCREEN_REFRESH 10
ON_GAME_START 11
ON_GAME_END 12
ON_DIRECTOR_POPULATE_SPAWN_ARRAYS 13
ON_STAGE_START 14
]]


-- @static
-- @name        new
-- @return      Item yeyeyey
-- @param       identifier      | string    | The identifier for the item.
-- @param       ...             |           | A variable amount of whatever.
-- @overload
-- @optional    ...             |           | description!!
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