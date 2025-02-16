-- ItemLog

local rapi_name = class_gm_to_rapi["class_item_log"]
ItemLog = _CLASS[rapi_name]



-- ========== Static Methods ==========

ItemLog.new = function(namespace, identifier)
    -- Return existing item log if found
    local item_log = ItemLog.find(identifier, namespace)
    if item_log then return item_log end

    -- Create new
    -- TODO: Pass proper args for this
    item_log = gm.item_create(
        namespace,
        identifier,
        nil,
        nil,
        nil
    )

    return ItemLog.wrap(item_log)
end


ItemLog.new_from_item = function(item)
    -- Automatically populates log properties
    -- and sets the item's `item_log_id` to this

    item = Wrap.unwrap(item)

    
end



-- ========== Instance Methods ==========

methods_class[rapi_name] = {

    

}



_CLASS[rapi_name] = ItemLog