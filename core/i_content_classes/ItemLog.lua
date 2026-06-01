-- ItemLog

---@class ItemLogClass
ItemLog = C["ItemLog"]

local proxy              = P.proxy
local metatable          = W["ItemLog"]
local find_table_wrapper = P.class_find_tables_wrapper["ItemLog"]
local find_table_array   = P.class_find_tables_array["ItemLog"]

local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class ItemLog
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field properties Array The array storing this item log's properties.
---@field array Array Alias for .properties.

---@class ItemLog
---@field namespace         string The namespace the log is in.
---@field identifier        string The identifier for the log within the namespace.
---@field token_name        string The localization token for the log's name.
---@field token_description string The localization token for the log's description.
---@field token_story       string The localization token for the log's story.
---@field token_date        string The localization token for the log's date.
---@field token_destination string The localization token for the log's destination.
---@field token_priority    string The localization token for the log's priority.
---@field pickup_object_id  number The ID of the item's pickup object.
---@field sprite_id         number The sprite ID of the log.
---@field group             number The ordering "group" the log is placed in.
---@field achievement_id    number The achievement ID of the log. <br>If *not* nil or -1, the log will be locked until the achievement is unlocked.


-- ========== Enums ==========

ItemLog.Property = {
    NAMESPACE         = 0,
    IDENTIFIER        = 1,
    TOKEN_NAME        = 2,
    TOKEN_DESCRIPTION = 3,
    TOKEN_STORY       = 4,
    TOKEN_DATE        = 5,
    TOKEN_DESTINATION = 6,
    TOKEN_PRIORITY    = 7,
    PICKUP_OBJECT_ID  = 8,
    SPRITE_ID         = 9,
    GROUP             = 10,
    ACHIEVEMENT_ID    = 11,
}
local t = {}
for name, num in pairs(ItemLog.Property) do t[num] = name end
for i = 0, #t do ItemLog.Property[i] = t[i] end

ItemLog.Group = {
    COMMON           = 0,
    COMMON_LOCKED    = 1,
    UNCOMMON         = 2,
    UNCOMMON_LOCKED  = 3,
    RARE             = 4,
    RARE_LOCKED      = 5,
    EQUIPMENT        = 6,
    EQUIPMENT_LOCKED = 7,
    BOSS             = 8,
    BOSS_LOCKED      = 9,
    LAST             = 10000,  -- Normally 10, but this is to allow for custom tiers
}


-- ========== Static Methods ==========

--[[
Creates a new item log with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the item log.
---@return ItemLog
ItemLog.new = function(NAMESPACE, identifier)
    check_init_started("new")
    if not identifier then throw("No identifier provided", "new") end

    -- Return existing log if found
    local log = ItemLog.find(identifier, NAMESPACE, true)
    if log then return log end

    -- Create new
    log = ItemLog.wrap(gm.item_log_create(
        NAMESPACE,
        identifier
    ))

    -- Set group to `LAST` by default
    log:set_group(ItemLog.Group.LAST)

    return log
end

--[[
Creates a new item log using an item as a base, <br>
automatically populating the log's properties and <br>
setting the item's `item_log_id` property.
]]
---@param item number | Item The item to use as a base.
---@return ItemLog
ItemLog.new_from_item = function(NAMESPACE, item)
    check_init_started("new_from_item")    
    if not item then throw("No item provided", "new_from_item") end
    
    item = Item.wrap(item)
    if type(item.value) ~= "number" then throw("Invalid item '"..tostring(item.value).."'", "new_from_item") end

    -- Use existing log or create a new one
    local log = ItemLog.find(item.identifier, NAMESPACE, true)
             or ItemLog.new(NAMESPACE, item.identifier)

    -- Set sprite and object IDs
    log.sprite_id           = item.sprite_id
    log.pickup_object_id    = item.object_id

    -- Set log group
    -- If item is achievement-locked, add +1
    local group = (item.tier * 2) + ((item.achievement_id and item.achievement_id ~= -1) and 1 or 0)
    log:set_group(group)

    -- Set the log ID of the item
    item.item_log_id = log

    return log
end

--[[
Creates a new item log using an equipment as a base, <br>
automatically populating the log's properties and <br>
setting the equipment's `item_log_id` property.
]]
---@param equip number | Equipment The equipment to use as a base.
---@return ItemLog
ItemLog.new_from_equipment = function(NAMESPACE, equip)
    check_init_started("new_from_equipment")
    if not equip then throw("No equipment provided", "new_from_equipment") end
    
    equip = Equipment.wrap(equip)
    if type(equip.value) ~= "number" then throw("Invalid equipment '"..tostring(equip.value).."'", "new_from_equipment") end

    -- Use existing log or create a new one
    local log = ItemLog.find(equip.identifier, NAMESPACE, true)
             or ItemLog.new(NAMESPACE, equip.identifier)

    -- Set sprite and object IDs
    log.sprite_id           = equip.sprite_id
    log.pickup_object_id    = equip.object_id

    -- Set log group
    -- If equipment is achievement-locked, add +1
    local group = (equip.tier * 2) + ((equip.achievement_id and equip.achievement_id ~= -1) and 1 or 0)
    log:set_group(group)

    -- Set the log ID of the equipment
    equip.item_log_id = log

    return log
end

--[[
Searches for the specified item log and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return ItemLog
ItemLog.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all item log in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>ItemLog.Property.NAMESPACE by default.
---@return table<number, ItemLog>
ItemLog.find_all = function(NAMESPACE, filter, property) end

--[[
Returns an item log wrapper containing the provided item log ID.
]]
---@param id number | ItemLog The item log to wrap.
---@return ItemLog
ItemLog.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class ItemLog
local methods = G.methods_content["ItemLog"]

--[[
Sets the group of the item log.
]]
---@param group number The group to set.
methods.set_group = function(self, group)
    if not group then throw("group is nil") end

    self.group = group

    -- Setting `.group` does *not* automatically
    -- move its position in the logbook

    -- Remove previous item log position (if found)
    local item_log_order = List.wrap(Global.item_log_display_list)
    item_log_order:delete_value(proxy[self])

    -- Set new item log position
    -- Sequentually loop through `item_log_order`
    -- until a log with a higher group is reached
    local pos = 0
    while pos < #item_log_order do
        local log = item_log_order:get(pos)
        local group_ = Class.ItemLog:get(log):get(ItemLog.Property.GROUP)
        if group < group_ then break end
        pos = pos + 1
    end
    
    item_log_order:insert(pos, proxy[self])
end

--[[
Prints the item log's properties.
]]
methods.print = function(self) end