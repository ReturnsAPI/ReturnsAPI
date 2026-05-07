-- List

--[[
Allows for easier manipulation of GameMaker DS Lists.

DS resources should always be destroyed once <br>
they are no longer in use to free up memory.
]]
---@class List
List = new_class()
C.List = List

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
Returns a newly created GameMaker list.
]]
---@param t? table A numerically-indexed Lua table to convert into a list.
---@return List
List.new = function(t)
    -- Create list from table
    if type(t) == "table" then
        local list = List.wrap(gm.ds_list_create())
        list:add(table_unpack(t))
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
    return new_proxy(unwrap(list), metatable)
end


-- ========== Wrapper Methods ==========

---@class List
local methods = {}

--[[
Returns `true` if the DS List exists.
]]
---@return boolean
methods.exists = function(self)
    local ret = Util.bool(gm.ds_exists(proxy[self], 2))
    if not ret then proxy[self] = -4 end
    return ret
end

--[[
Destroys the DS List.
]]
methods.destroy = function(self)
    gm.ds_list_destroy(proxy[self])
    proxy[self] = -4
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
    local v = proxy[self]
    if v == -4 then throw("List does not exist") end
    size = size or self:size()
    if (index < 0) or (index >= size) then return nil end
    return wrap(gm.ds_list_find_value(v, index))
end

--[[
Sets the value at the specified index, starting at `0`.

You can also use Lua syntax (e.g., `list[4] = 56`), which starts at `1`.
]]
---@param index integer The index to set to.
---@param value any The value to set.
methods.set = function(self, index, value)
    local v = proxy[self]
    if v == -4 then throw("List does not exist") end
    gm.ds_list_set(v, index, unwrap(value))
end

--[[
Returns the size (length) of the list.

You can also use Lua syntax (i.e., `#list`).
]]
---@return integer size
methods.size = function(self)
    return gm.ds_list_size(proxy[self])
end

--[[
Appends values to the end of the list.
]]
---@param ... any A variable amount of values to add.
methods.add = function(self, ...)
    local values = table_pack(...)
    for i = 1, values.n do
        values[i] = unwrap(values[i])
    end
    gm.ds_list_add(proxy[self], table_unpack(values))
end

--[[
Inserts a value at the specified index, starting at `0`.
]]
---@param index integer The index to insert at.
---@param value any The value to insert.
methods.insert = function(self, index, value)
    gm.ds_list_insert(proxy[self], index, unwrap(value))
end

--[[
Deletes the value from the specified index, starting at `0`.
]]
---@param index integer The index to delete at.
methods.delete = function(self, index)
    gm.ds_list_delete(proxy[self], index)
end

--[[
Deletes the first occurence of the specified value.
]]
---@param value any The value to delete.
methods.delete_value = function(self, value)
    local index = self:find(value)
    if not index then return end
    gm.ds_list_delete(proxy[self], index)
end

--[[
Deletes all elements in the list.
]]
methods.clear = function(self)
    gm.ds_list_clear(proxy[self])
end

--[[
Returns `true` if the list contains the specified value.
]]
---@param value any The value to check.
---@return boolean
methods.contains = function(self, value)
    return (gm.ds_list_find_index(proxy[self], unwrap(value)) >= 0)
end

--[[
Returns the index (starting at `0`) of the first occurence <br>
of the specified value, or `nil` if not found.
]]
---@param value any The value to search for.
---@return integer | nil
methods.find = function(self, value)
    local ret = gm.ds_list_find_index(proxy[self], unwrap(value))
    if ret < 0 then return nil end
    return ret
end

--[[
Sorts the list in ascending or descending order.
]]
---@param descending? boolean If `true`, will sort in descending order. <br>`false` by default.
methods.sort = function(self, descending)
    gm.ds_list_sort(proxy[self], not descending)
end

--[[
Prints the list.
]]
methods.print = function(self)
    local str = ""
    local index_padding = #tostring(#self) + 2
    for i, v in ipairs(self) do
        str = string.format(
            "%s\n%s %s",
            str,
            String.pad_right(string.format("[%d]", i - 1), index_padding),
            Util.tostring(v)
        )
    end
    print(str)
end


-- ========== Metatables ==========

---@class List
---@field value integer
---@field RAPI string
---@field [integer] any

local mt_name = "List"

W.List = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return proxy[t] end
        if k == "RAPI" then return mt_name end
        
        -- Methods
        if methods[k] then return methods[k] end

        -- Getter
        k = unwrap(k)
        return t:get(k - 1)
    end,

    __newindex = function(t, k, v)
        -- Throw read-only error
        if k == "value"
        or k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        k = unwrap(k)
        t:set(k - 1, v)
    end,
    
    __len = function(t)
        return t:size()
    end,

    __pairs = function(t)
        local n = #t
        return function(t, k)
            k = k + 1
            if k <= n then return k, t:get(k - 1, n) end
        end, t, 0
    end,

    __ipairs = function(t)
        local n = #t
        return function(t, k)
            k = k + 1
            if k <= n then return k, t:get(k - 1, n) end
        end, t, 0
    end,

    __metatable = mt_wrapper_name(mt_name),
}
metatable = W.List