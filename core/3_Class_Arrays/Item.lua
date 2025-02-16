-- Item

local rapi_name = class_gm_to_rapi["class_item"]
Item = _CLASS[rapi_name]



-- ========== Static Methods ==========

Item.new = function(namespace, identifier)
    -- Return existing item if found
    local item = Item.find(identifier, namespace)
    if item then return item end

    -- Create new
    -- TODO: Pass proper args for this
    item = gm.item_create(
        namespace,
        identifier,
        nil,
        7,
        gm.object_add_w(namespace, identifier, gm.constants.pPickupItem),
        0
    )

    return Item.wrap(item)
end



-- ========== Instance Methods ==========

methods_class[rapi_name] = {

    create = function(self, x, y, target)
        local object_id = self.object_id
        if object_id == nil
        or object_id == -1 then return nil end

        -- This function spawns the item 40 px above, so add 40 to y in the call
        gm.item_drop_object(object_id, x, y + 40, Wrap.unwrap(target), false)

        -- Look for drop (because gm.item_drop_object does not actually return the instance for some reason)
        local drop = nil
        local drops = Instance.find_all(gm.constants.pPickupItem) --, gm.constants.oCustomObject_pPickupItem)   -- TODO
        for _, d in ipairs(drops) do
            local dData = Instance.get_data(d)
            if math.abs(d.x - x) <= 1 and math.abs(d.y - y) <= 1
            and (not dData.returned_drop) then
                drop = d
                dData.returned_drop = true
                break
            end
        end

        return drop
    end

}



_CLASS[rapi_name] = Item