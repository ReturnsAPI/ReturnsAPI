-- ItemLog

local name_rapi = class_name_g2r["class_item_log"]
ItemLog = __class[name_rapi]



-- ========== Enums ==========

--@section Enums

--@enum
--@name Property
--[[
NAMESPACE           0
IDENTIFIER          1
TOKEN_NAME          2
TOKEN_DESCRIPTION   3
TOKEN_STORY         4
TOKEN_DATE          5
TOKEN_DESTINATION   6
TOKEN_PRIORITY      7
PICKUP_OBJECT_ID    8
SPRITE_ID           9
GROUP               10
ACHIEVEMENT_ID      11
]]


--@enum
ItemLog.Group = {
    COMMON              = 0,
    COMMON_LOCKED       = 1,
    UNCOMMON            = 2,
    UNCOMMON_LOCKED     = 3,
    RARE                = 4,
    RARE_LOCKED         = 5,
    EQUIPMENT           = 6,
    EQUIPMENT_LOCKED    = 7,
    BOSS                = 8,
    BOSS_LOCKED         = 9,
    LAST                = 10000 -- Normally 10, but this is to allow for custom tiers
}



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The item log ID being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.

<br>

Property | Type | Description
| - | - | -
`namespace`         | string    | The namespace the log is in.
`identifier`        | string    | The identifier for the log within the namespace.
`token_name`        | string    | The localization token for the log's name.
`token_description` | string    | The localization token for the log's description.
`token_story`       | string    | The localization token for the log's story.
`token_date`        | string    | The localization token for the log's date.
`token_destination` | string    | The localization token for the log's destination.
`token_priority`    | string    | The localization token for the log's priority.
`pickup_object_id`  | number    | The ID of the item's pickup object.
`sprite_id`         | sprite    | The sprite ID of the log.
`group`             | number    | The ordering "group" the log is placed in.
`achievement_id`    | number    | The achievement ID of the log. <br>If *not* `nil` or `-1`, the log will be locked until the achievement is unlocked.
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return   ItemLog
--@param    identifier  | string    | The identifier for the item log.
--[[
Creates a new item log with the given identifier if it does not already exist,
or returns the existing one if it does.
]]
ItemLog.new = function(NAMESPACE, identifier)
    Initialize.internal.check_if_started("ItemLog.new")
    if not identifier then log.error("ItemLog.new: No identifier provided", 2) end

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


--@static
--@return   ItemLog
--@param    item            | Item      | The item to use as a base.
--[[
Creates a new item log using an item as a base,
automatically populating the log's properties and
setting the item's `item_log_id` property.
]]
ItemLog.new_from_item = function(NAMESPACE, item)
    Initialize.internal.check_if_started("ItemLog.new_from_item")
    
    if not item then log.error("ItemLog.new_from_item: No item provided", 2) end
    item = Item.wrap(item)
    
    if type(item.value) ~= "number" then log.error("ItemLog.new_from_item: Invalid item", 2) end

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


--@static
--@return   ItemLog
--@param    equip           | Equipment | The equipment to use as a base.
--[[
Creates a new item log using an equipment as a base,
automatically populating the log's properties and
setting the equipment's `item_log_id` property.
]]
ItemLog.new_from_equipment = function(NAMESPACE, equip)
    Initialize.internal.check_if_started("ItemLog.new_from_equipment")
    
    if not equip then log.error("ItemLog.new_from_equipment: No equipment provided", 2) end
    equip = Equipment.wrap(equip)

    if type(equip.value) ~= "number" then log.error("ItemLog.new_from_equipment: Invalid equipment", 2) end

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


--@static
--@name         find
--@return       ItemLog or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified item log and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]


--@static
--@name         find_all
--@return       table
--@param        filter      |           | The filter to search by.
--@optional     property    | number    | The property to check. <br>@link {`ItemLog.Property.NAMESPACE` | ItemLog#Property} by default.
--[[
Returns a table of item logs matching the specified filter and property.

**NOTE:** Filtering by a non-namespace property is *very slow*!
Try not to do that too much.
]]


--@static
--@name         wrap
--@return       ItemLog
--@param        id          | number    | The item log ID to wrap.
--[[
Returns an ItemLog wrapper containing the provided item log ID.
]]



-- ========== Instance Methods ==========

--@section Instance Methods

Util.table_append(methods_class_array[name_rapi], {

    --@instance
    --@name         print
    --[[
    Prints the item log's properties.
    ]]


    --@instance
    --@param        group       | number    | The group to set.
    --[[
    Sets the group of the item log.
    ]]
    set_group = function(self, group)
        if not group then log.error("set_group: group is not provided", 2) end

        self.group = group

        -- Setting `.group` does *not* automatically
        -- move its position in the logbook

        -- Remove previous item log position (if found)
        local item_log_order = Global.item_log_display_list
        item_log_order:delete_value(self.value)

        -- Set new item log position
        -- Sequentually loop through `item_log_order`
        -- until a log with a higher group is reached
        local pos = 0
        while pos < #item_log_order do
            local log = item_log_order:get(pos)
            local group_ = Class.ItemLog:get(log):get(10)
            if group < group_ then break end
            pos = pos + 1
        end
        
        item_log_order:insert(pos, self.value)
    end

})