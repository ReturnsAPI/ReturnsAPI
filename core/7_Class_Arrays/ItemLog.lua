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
`value`         |           | *Read-only.* The item log ID being wrapped.
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
`sprite_id`         | sprite    | The sprite ID of the log.
`group`             | number    | The ordering "group" the log is placed in.
`achievement_id`    | number    | The achievement ID of the log. <br>If *not* `-1`, the log will be locked until the achievement is unlocked.
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
    Initialize.internal.check_if_started()
    if not identifier then log.error("No identifier provided", 2) end

    -- Return existing item log if found
    local item_log = ItemLog.find(identifier, NAMESPACE)
    if item_log then return item_log end

    -- Create new
    item_log = ItemLog.wrap(gm.item_log_create(
        NAMESPACE,
        identifier,
        0,  -- group
        0,  -- sprite_id
        0   -- object_id
    ))

    -- Set group to `LAST` by default
    item_log:set_group(ItemLog.Group.LAST)

    return item_log
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
    Initialize.internal.check_if_started()
    
    if not item then log.error("No item provided", 2) end
    item = Item.wrap(item)

    -- Use existing item log if found
    local item_log = ItemLog.find(item.identifier, NAMESPACE)
    if not item_log then
        -- Create new
        item_log = ItemLog.wrap(gm.item_log_create(
            NAMESPACE,
            item.identifier,
            0,
            item.sprite_id,
            item.object_id
        ))
    end

    -- Set group
    local group = item.tier * 2     -- TODO: Add +1 if item is achievement-locked
    item_log:set_group(group)

    -- Set the log ID of the item
    item.item_log_id = item_log

    return item_log
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
    Initialize.internal.check_if_started()
    
    if not equip then log.error("No equipment provided", 2) end
    equip = Equipment.wrap(equip)

    -- Use existing equip log if found
    local item_log = ItemLog.find(equip.identifier, NAMESPACE)
    if not item_log then
        -- Create new
        item_log = ItemLog.wrap(gm.item_log_create(
            NAMESPACE,
            equip.identifier,
            0,
            equip.sprite_id,
            equip.object_id
        ))
    end

    -- Set group
    local group = equip.tier * 2    -- TODO: Add +1 if equip is achievement-locked
    item_log:set_group(group)

    -- Set the log ID of the equip
    equip.item_log_id = item_log

    return item_log
end



-- ========== Instance Methods ==========

--@section Instance Methods

Util.table_append(methods_class_array[name_rapi], {

    --@instance
    --@name         print_properties
    --[[
    Prints the item log's properties.
    ]]


    --@instance
    --@param        group       | number    | The group to set.
    --[[
    Sets the group of the item log.
    ]]
    set_group = function(self, group)
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