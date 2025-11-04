-- Map

--[[
This class allows for easier manipulation of GameMaker DS Maps.

DS resources should always be destroyed once
they are no longer in use to free up memory.
]]

Map = new_class()



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The ID of the Map.
`RAPI`          | string    | *Read-only.* The wrapper name.
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       Map
--@optional     table       | table     | A key-value pair table to convert into a map.
--[[
Returns a newly created GameMaker map.
]]
Map.new = function(t)
    -- Create map from table
    if type(t) == "table" then
        local map = Map.wrap(gm.ds_map_create())

        -- Add key-value pairs from table to map
        for k, v in pairs(t) do
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
        if self.value == -4 then log.error("get: Map does not exist", 2) end
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
        if self.value == -4 then log.error("set: Map does not exist", 2) end
        gm.ds_map_set(self.value, Wrap.unwrap(key), Wrap.unwrap(value, true))
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
    --[[
    Deletes all key-value pairs in the map.
    ]]
    clear = function(self)
        gm.ds_map_clear(self.value)
    end,


    --@instance
    --[[
    Prints the map.
    ]]
    print = function(self)
        local str = ""
        local keys = GM.ds_map_keys_to_array(self.value)
        for _, key in ipairs(keys) do
            str = str.."\n"..Util.pad_string_right(key, 32).." = "..Util.tostring(self[key])
        end
        print(str)
    end

}



-- ========== Metatables ==========

local wrapper_name = "Map"

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



-- Public export
__class.Map = Map