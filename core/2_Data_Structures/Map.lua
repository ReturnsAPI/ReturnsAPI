-- Map

--[[
This class allows for easier manipulation of GameMaker DS Maps.

DS resources should always be destroyed once
they are no longer in use to free up memory.
]]

Map = new_class()



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       Map
--@optional     table       | table     | A key-value pair table to convert into a map.
--[[
Returns a newly created GameMaker map.
]]
Map.new = function(table)
    -- Create map from table
    if type(table) == "table" then
        local map = Map.wrap(gm.ds_map_create())

        -- Add key-value pairs from table to map
        for k, v in pairs(table) do
            map:set(k, v)
        end

        return map
    end

    -- Create empty map
    return Map.wrap(gm.ds_map_create())
end


--@static
--@return       Map
--@param        map         | number    | The ID of the map.
--[[
Returns a Map wrapper containing the provided map ID.
]]
Map.wrap = function(map)
    -- Input:   number or Map wrapper
    -- Wraps:   number
    return make_proxy(Wrap.unwrap(map), metatable_map)
end


-- Debug
-- Don't really need to remove this
Map.get_refmap_count = function()
    return #__ref_map
end



-- ========== Instance Methods ==========

--@section Instance Methods

methods_map = {

    --@instance
    --@return       bool
    --[[
    Returns `true` if the DS Map exists.
    ]]
    exists = function(self)
        local ret = (gm.ds_exists(self.value, 1) == 1)
        if not ret then __proxy[self] = -4 end
        return ret
    end,


    --@instance
    --[[
    Destroys the DS Map.
    ]]
    destroy = function(self)
        gm.ds_map_destroy(self.value)
        __proxy[self] = -4
    end,


    --@instance
    --@return       any
    --@param        key         |           | The key to get from.
    --[[
    Returns the value of the specified key.
    You can also use Lua syntax (e.g., `map.my_key`).
    ]]
    get = function(self, key)
        if __proxy[proxy] == -4 then log.error("Map does not exist", 2) end
        return Wrap.wrap(gm.ds_map_find_value(self.value, Wrap.unwrap(key)))
    end,


    --@instance
    --@param        key         |           | The key to set to.
    --@param        value       |           | The value to set.
    --[[
    Sets the value of the specified key.
    You can also use Lua syntax (e.g., `map.my_key = 123`).
    ]]
    set = function(self, key, value)
        if __proxy[proxy] == -4 then log.error("Map does not exist", 2) end
        gm.ds_map_set(self.value, Wrap.unwrap(key), Wrap.unwrap(value, true))
    end,


    --@instance
    --@param        key         | RValue    | The key to set to.
    --@param        value       | RValue    | The value to set.
    --[[
    Variant of `set` that accepts RValues.
    ]]
    set_rvalue = function(self, key, value)
        local holder = RValue.new_holder(3)
        holder[0] = RValue.new(self.value)
        holder[1] = key
        holder[2] = value
        gmf.ds_map_set(RValue.new(0), nil, nil, 3, holder)
    end,


    --@instance
    --@return       number
    --[[
    Returns the size (length) of the map.
    You can also use Lua syntax (i.e., `#map`).
    ]]
    size = function(self)
        return gm.ds_map_size(self.value)
    end,


    --@instance
    --@param        key         |           | The key to delete.
    --[[
    Deletes the key-value pair of the specified key.
    ]]
    delete = function(self, key)
        gm.ds_map_delete(self.value, Wrap.unwrap(key, true))
    end,


    --@instance
    --@param        key         | RValue    | The key to delete.
    --[[
    Variant of `delete` that accepts an RValue.
    ]]
    delete_rvalue = function(self, key)
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(self.value)
        holder[1] = key
        gmf.ds_map_delete(RValue.new(0), nil, nil, 2, holder)
    end,


    --@instance
    --[[
    Deletes all key-value pairs in the map.
    ]]
    clear = function(self)
        gm.ds_map_clear(self.value)
    end

}



-- ========== Metatables ==========

local wrapper_name = "Map"

make_table_once("metatable_map_class", {
    __metatable = "RAPI.Class."..wrapper_name
})
setmetatable(Map, metatable_map_class)


make_table_once("metatable_map", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return __proxy[proxy] end
        if k == "RAPI" then return wrapper_name end
        
        -- Methods
        if methods_map[k] then
            return methods_map[k]
        end

        -- Getter
        return proxy:get(k)
    end,
    

    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        proxy:set(k, v)
    end,
    
    
    __len = function(proxy)
        return proxy:size()
    end,


    __pairs = function(proxy)
        -- Find first key
        local key = gm.ds_map_find_first(__proxy[proxy])

        return function(proxy)
            if not key then return nil, nil end
            local ret1, ret2 = key, proxy:get(key)

            -- Find next key
            key = gm.ds_map_find_next(__proxy[proxy], key)

            return ret1, ret2
        end, proxy, nil
    end,

    
    __metatable = "RAPI.Wrapper."..wrapper_name
})



-- Create __ref_map
run_once(function() __ref_map = Map.new() end)

-- Public export
__class.Map = Map
__class_mt.Map = metatable_map_class