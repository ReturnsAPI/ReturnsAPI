-- Array

--[[
Allows for easier manipulation of GameMaker arrays.
]]
---@class Array
Array = new_class()
C.Array = Array

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
Returns a newly created GameMaker array.
]]
---@param t? table A numerically-indexed Lua table to convert into an array.
---@return Array
Array.new = function(t) end

--[[
Returns a newly created GameMaker array.
]]
---@param size? integer The size of the array. <br>`0` by default.
---@param default? any The value to populate the array with. <br>`0` by default.
---@return Array
Array.new = function(size, default)
    -- Create array from table
    if type(size) == "table" then
        local arr = Array.wrap(gm.array_create(0, 0))
        arr:push(table_unpack(size))
        return arr
    end

    -- Create array with optional size and default value
    return Array.wrap(gm.array_create(size or 0, default or 0))
end

--[[
Returns an Array wrapper containing the provided array.
]]
---@param array Array | sol.RefDynamicArrayOfRValue* The array to wrap.
---@return Array
Array.wrap = function(array)
    return new_proxy(unwrap(array), metatable)
end


-- ========== Wrapper Methods ==========

---@class Array
local methods = {}

--[[
Returns the value at the specified index (starting at `0`), <br>
or `nil` if out-of-bounds.

You can also use Lua syntax (e.g., `array[4]`), which starts at `1`.
]]
---@param index integer The index to get from.
---@param size? integer The size of the array, if it already known (this skips a `:size()` call).
---@return any
methods.get = function(self, index, size)
    size = size or self:size()
    if (index < 0) or (index >= size) then return nil end
    return wrap(gm.array_get(proxy[self], index))
end

--[[
Sets the value at the specified index, starting at `0`.

You can also use Lua syntax (e.g., `array[4] = 56`), which starts at `1`.
]]
---@param index integer The index to set to.
---@param value any The value to set.
methods.set = function(self, index, value)
    gm.array_set(proxy[self], index, unwrap(value))
end

--[[
Returns the size (length) of the array.

You can also use Lua syntax (i.e., `#array`).
]]
---@return integer size
methods.size = function(self)
    return gm.array_length(proxy[self])
end

--[[
Resizes the array.
]]
---@param size integer The new size.
methods.resize = function(self, size)
    gm.array_resize(proxy[self], size)
end

--[[
Appends values to the end of the array.
]]
---@param ... any A variable amount of values to push
methods.push = function(self, ...)
    local values = table_pack(...)
    for i = 1, values.n do
        values[i] = unwrap(values[i])
    end
    gm.array_push(proxy[self], table_unpack(values))
end

--[[
Removes and returns the last element of the array.
]]
---@return any
methods.pop = function(self)
    return wrap(gm.array_pop(proxy[self]))
end

--[[
Inserts a value at the specified index, starting at `0`.
]]
---@param index integer The index to insert at.
---@param value any The value to insert.
methods.insert = function(self, index, value)
    gm.array_insert(proxy[self], index, unwrap(value))
end

--[[
Deletes value(s) from the specified index, starting at `0`.
]]
---@param index integer The index to delete at.
---@param count? integer The number of values to delete. <br>`1` by default.
methods.delete = function(self, index, count)
    gm.array_delete(proxy[self], index, unwrap(count) or 1)
end

--[[
Deletes the first occurence of the specified value.
]]
---@param value any The value to delete.
methods.delete_value = function(self, value)
    local index = self:find(unwrap(value))
    if not index then return end
    gm.array_delete(proxy[self], index, 1)
end

--[[
Deletes all elements in the array, resizing it to 0.
]]
methods.clear = function(self)
    gm.array_delete(proxy[self], 0, self:size())
end

--[[
Returns `true` if the array contains the specified value.
]]
---@param value any The value to check.
---@param offset integer The starting index of a subset to search in (`0`-based). <br>`0` by default.
---@param length integer The length of the subset. <br>`array:size()` by default.
---@return boolean
methods.contains = function(self, value, offset, length)
    return gm.array_contains(proxy[self], unwrap(value), offset or 0, length or self:size())
end

--[[
Returns the index (starting at `0`) of the first occurence <br>
of the specified value, or `nil` if not found.
]]
---@param value any The value to search for.
---@return integer | nil
methods.find = function(self, value)
    value = unwrap(value)
    for i, v in ipairs(self) do
        if v == value then return i - 1 end
    end
    return nil
end

--[[
Sorts the array in ascending or descending order.
]]
---@param descending? boolean If `true`, will sort in descending order. <br>`false` by default.
methods.sort = function(self, descending)
    gm.array_sort(proxy[self], not descending)
end

--[[
Prints the array.
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

---@class Array
---@field value sol.RefDynamicArrayOfRValue*
---@field RAPI string

local mt_name = "Array"

W.Array = {
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
metatable = W.Array