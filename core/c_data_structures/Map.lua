-- Map

--[[
Allows for easier manipulation of GameMaker DS Maps.

DS resources should always be destroyed once <br>
they are no longer in use to free up memory.
]]
---@class Map
Map = new_class()
C.Map = Map

local proxy = P.proxy
local metatable

local type         = type
local table_pack   = table.pack
local table_unpack = table.unpack
local new_proxy    = new_proxy
local wrap         = Wrap.wrap
local unwrap       = Wrap.unwrap


-- ========== Static Methods ==========

--[[
Returns a newly created GameMaker map.
]]
---@param t? table A key-value pair table to convert into a map.
---@return Map
Map.new = function(t)
    -- Create map from table
    if type(t) == "table" then
        local map = Map.wrap(gm.ds_map_create())

        for k, v in pairs(t) do
            map:set(k, v)
        end

        return map
    end

    -- Create empty map
    return Map.wrap(gm.ds_map_create())
end

--[[
Returns a Map wrapper containing the provided map ID.
]]
---@param map Map | number The ID of the map.
---@return Map
Map.wrap = function(map)
    return new_proxy(unwrap(map), metatable)
end


-- ========== Wrapper Methods ==========

---@class Map
local methods = {}

--[[
Returns `true` if the DS Map exists.
]]
---@return boolean
methods.exists = function(self)
    local ret = Util.bool(gm.ds_exists(proxy[self], 1))
    if not ret then proxy[self] = -4 end
    return ret
end

--[[
Destroys the DS Map.
]]
methods.destroy = function(self)
    gm.ds_map_destroy(proxy[self])
    proxy[self] = -4
end

--[[
Returns the value of the specified key.

You can also use Lua syntax (e.g., `map.my_key`).
]]
---@param key any The key to get from.
---@return any
methods.get = function(self, key)
    local v = proxy[self]
    if v == -4 then throw("Map does not exist") end
    return wrap(gm.ds_map_find_value(v, unwrap(key)))
end

--[[
Sets the value of the specified key.

You can also use Lua syntax (e.g., `map.my_key = 123`).
]]
---@param key any The key to set to.
---@param value any The value to set.
methods.set = function(self, key, value)
    local v = proxy[self]
    if v == -4 then throw("Map does not exist") end
    gm.ds_map_set(v, unwrap(key), unwrap(value))
end

--[[
Returns the size (length) of the map.

You can also use Lua syntax (i.e., `#map`).
]]
---@return integer size
methods.size = function(self)
    return gm.ds_map_size(proxy[self])
end

--[[
Deletes the key-value pair of the specified key.
]]
---@param key any The key to delete.
methods.delete = function(self, key)
    gm.ds_map_delete(proxy[self], unwrap(key))
end

--[[
Deletes all key-value pairs in the map.
]]
methods.clear = function(self)
    gm.ds_map_clear(proxy[self])
end

--[[
Prints the map.
]]
methods.print = function(self)
    local str = ""
    local keys = GM.ds_map_keys_to_array(self.value)
    for _, key in ipairs(keys) do
        str = string.format(
            "%s\n%s = %s",
            str,
            String.pad_right(key, 32),
            Util.tostring(self[key])
        )
    end
    print(str)
end


-- ========== Metatables ==========

---@class Map
---@field value integer
---@field RAPI string

local mt_name = "Map"

W.Map = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return proxy[t] end
        if k == "RAPI" then return mt_name end
        
        -- Methods
        if methods[k] then return methods[k] end

        -- Getter
        return t:get(k)
    end,

    __newindex = function(t, k, v)
        -- Throw read-only error
        if k == "value"
        or k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        t:set(k, v)
    end,
    
    __len = function(t)
        return t:size()
    end,

    __pairs = function(t)
        local key = gm.ds_map_find_first(proxy[t])

        return function()
            if not key then return nil, nil end

            local k, v = key, t:get(key)
            key = gm.ds_map_find_next(proxy[t], key)

            return k, v
        end
    end,

    __metatable = mt_wrapper_name(mt_name),
}
metatable = W.Map