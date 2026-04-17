-- List

--[[
Allows for easier manipulation of GameMaker DS Lists.

DS resources should always be destroyed once <br>
they are no longer in use to free up memory.
]]
---@class List
List = {}
C.List = List


-- ========== Static Methods ==========

--[[
Returns a newly created GameMaker list.
]]
---@param t? table A numerically-indexed Lua table to convert into a list.
---@return List
List.new = function(t)
    -- Create list from table
    if type(t) == "table" then
        local list = List.wrap(gm.ds_list_create())
        list:add(table.unpack(t))
        return list
    end

    -- Create empty list
    return List.wrap(gm.ds_list_create())
end

--[[
Returns a List wrapper containing the provided list ID.
]]
---@param list List | number The ID of the list.
---@return List
List.wrap = function(list)
    return Proxy.new(Wrap.unwrap(list), W.List)
end


-- ========== Wrapper Methods ==========

---@class List
local methods = {}

--[[
Returns `true` if the DS List exists.
]]
---@return boolean
methods.exists = function(self)
    local ret = Util.bool(gm.ds_exists(self.value, 2))
    if not ret then Proxy.set(self, -4) end
    return ret
end

--[[
Destroys the DS List.
]]
methods.destroy = function(self)
    gm.ds_list_destroy(self.value)
    Proxy.set(self, -4)
end

--[[
Returns the value at the specified index (starting at `0`), <br>
or `nil` if out-of-bounds.

You can also use Lua syntax (e.g., `list[4]`), which starts at `1`.
]]
---@param index integer The index to get from.
---@param size? integer The size of the list, if already known.
---@return any
methods.get = function(self, index, size)
    if self.value == -4 then log.error("get: List does not exist", 2) end
    index = Wrap.unwrap(index)
    size = size or self:size()
    if (index < 0) or (index >= size) then return nil end
    return Wrap.wrap(gm.ds_list_find_value(self.value, index))
end

--[[
Sets the value at the specified index, starting at `0`.

You can also use Lua syntax (e.g., `list[4] = 56`), which starts at `1`.
]]
---@param index integer The index to set to.
---@param value any The value to set.
methods.set = function(self, index, value)
    if self.value == -4 then log.error("set: List does not exist", 2) end
    gm.ds_list_set(self.value, Wrap.unwrap(index), Wrap.unwrap(value))
end

--[[
Returns the size (length) of the list.

You can also use Lua syntax (i.e., `#list`).
]]
---@return integer size
methods.size = function(self)
    return gm.ds_list_size(self.value)
end

--[[
Appends values to the end of the list.
]]
---@param ... any A variable amount of values to add.
methods.add = function(self, ...)
    local values = table.pack(...)

    for i = 1, values.n do
        values[i] = Wrap.unwrap(values[i], true)
    end

    gm.ds_list_add(self.value, table.unpack(values))
end

--[[
Inserts a value at the specified index, starting at `0`.
]]
---@param index integer The index to insert at.
---@param value any The value to insert.
methods.insert = function(self, index, value)
    gm.ds_list_insert(self.value, Wrap.unwrap(index), Wrap.unwrap(value))
end

--[[
Deletes the value from the specified index, starting at `0`.
]]
---@param index integer The index to delete at.
methods.delete = function(self, index)
    gm.ds_list_delete(self.value, Wrap.unwrap(index))
end

--[[
Deletes the first occurence of the specified value.
]]
---@param value any The value to delete.
methods.delete_value = function(self, value)
    local index = self:find(value)
    if not index then return end
    gm.ds_list_delete(self.value, index)
end

--[[
Deletes all elements in the list.
]]
methods.clear = function(self)
    gm.ds_list_clear(self.value)
end

--[[
Returns `true` if the list contains the specified value.
]]
---@param value any The value to check.
---@return boolean
methods.contains = function(self, value)
    return (gm.ds_list_find_index(self.value, Wrap.unwrap(value)) >= 0)
end

--[[
Returns the index (starting at `0`) of the first occurence <br>
of the specified value, or `nil` if not found.
]]
---@param value any The value to search for.
---@return integer | nil
methods.find = function(self, value)
    local ret = gm.ds_list_find_index(self.value, Wrap.unwrap(value))
    if ret < 0 then return nil end
    return ret
end

--[[
Sorts the list in ascending or descending order.
]]
---@param descending? boolean If `true`, will sort in descending order. <br>`false` by default.
methods.sort = function(self, descending)
    gm.ds_list_sort(self.value, not descending)
end

--[[
Prints the list.
]]
methods.print = function(self)
    -- TODO
end


-- ========== Metatables ==========

---@class List
---@field value integer
---@field RAPI string

local mt_name = "List"

W.List = {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(proxy) end
        if k == "RAPI" then return mt_name end
        
        -- Methods
        if methods[k] then return methods[k] end

        -- Getter
        k = Wrap.unwrap(k)
        return proxy:get(k - 1)
    end,

    __newindex = function(proxy, k, v)
        -- Throw read-only error
        if k == "value"
        or k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        k = Wrap.unwrap(k)
        proxy:set(k - 1, v)
    end,
    
    __len = function(proxy)
        return proxy:size()
    end,

    __pairs = function(proxy)
        local n = #proxy
        return function(proxy, k)
            k = k + 1
            if k <= n then return k, proxy:get(k - 1, n) end
        end, proxy, 0
    end,

    __ipairs = function(proxy)
        local n = #proxy
        return function(proxy, k)
            k = k + 1
            if k <= n then return k, proxy:get(k - 1, n) end
        end, proxy, 0
    end,

    __metatable = mt_wrapper_name(mt_name),
}