-- Item

-- local rapi_name = class_gm_to_rapi["class_item"]
-- Item = _CLASS[rapi_name]

Item = new_class()
_CLASS["Item"] = Item



-- ========== Enums ==========

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


Item.StackKind = ReadOnly.new({
    NORMAL          = 0,
    TEMPORARY_BLUE  = 1,
    TEMPORARY_RED   = 2,
    ANY             = 3,
    TEMPORARY_ANY   = 4
})



-- ========== Static Methods ==========





-- ========== Instance Methods ==========
