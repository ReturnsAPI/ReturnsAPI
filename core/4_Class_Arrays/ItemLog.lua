-- ItemLog

local rapi_name = class_gm_to_rapi["class_item_log"]
ItemLog = _CLASS[rapi_name]



-- ========== Enums ==========

ItemLog.Group = ReadOnly.new({
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
    LAST                = 1000  -- Normally 10, but this is to allow for custom tiers
})



-- ========== Static Methods ==========

ItemLog.new = function(namespace, identifier)
    if not identifier then log.error("No identifier provided", 2) end

    -- Return existing item log if found
    local item_log = ItemLog.find(identifier, namespace)
    if item_log then return item_log end

    -- Create new
    -- TODO: Pass proper args for this
    item_log = ItemLog.wrap(gm.item_log_create(
        namespace,
        identifier,
        0,  -- group
        0,  -- sprite_id
        0   -- object_id
    ))

    -- Set group to `LAST`
    item_log:set_group(ItemLog.Group.LAST)

    return item_log
end


ItemLog.new_from_item = function(namespace, item)
    -- Automatically populates log properties
    -- and sets the item's `item_log_id` to this
    if not item then log.error("No item provided", 2) end
    item = Item.wrap(item)

    -- Create new
    item_log = ItemLog.wrap(gm.item_log_create(
        namespace,
        item.identifier,
        0,
        item.sprite_id,
        item.object_id
    ))

    -- Set group
    local group = item.tier * 2     -- TODO: Add +1 if item is achievement-locked
    item_log:set_group(group)

    -- Set the log ID of the item
    item.item_log_id = item_log

    return item_log
end



-- ========== Instance Methods ==========

methods_class[rapi_name] = {

    set_group = function(self, group)
        self.group = group

        -- Setting `.group` does *not* automatically
        -- move its position in the logbook

        -- Remove previous item log position (if found)
        local item_log_order = List.wrap(gm.variable_global_get("item_log_display_list"))
        local pos = item_log_order:find(self.value)
        if pos then item_log_order:delete(pos) end

        -- Set new item log position
        local pos = 0
        while pos < #item_log_order do
            local log = item_log_order:get(pos)
            local group_ = Class.ItemLog:get(log):get(10)
            if group < group_ then break end
            pos = pos + 1
        end
        item_log_order:insert(pos, self.value)
    end

}