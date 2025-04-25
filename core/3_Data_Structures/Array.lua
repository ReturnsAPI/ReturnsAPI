-- Array

--[[
This class allows for manipulation of GameMaker arrays.
]]

Array = new_class()



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       Array
--@optional     size        | number    | The size of the array. <br>`0` by default.
--@optional     value       |           | The value to populate the array with. <br>`0` by default.
--@overload
--@return       Array
--@param        table       | table     | A numerically-indexed Lua table to convert into an array.
--[[
Returns a newly created GameMaker array.
]]
Array.new = function(arg1, arg2)
    -- Overload 1
    -- Create array from table
    if type(arg1) == "table" then
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(0)
        holder[1] = RValue.new(0)
        local out = RValue.new(0)
        gmf.array_create(out, nil, nil, 2, holder)
        local arr = Array.wrap(out)

        -- Add elements from table to array
        for _, v in ipairs(arg1) do
            arr:push(Wrap.unwrap(v))
        end
        return arr
    end

    -- Overload 2
    -- Create array with optional size and default value
    local holder = RValue.new_holder(2)
    holder[0] = RValue.new(arg1 or 0)
    holder[1] = RValue.new(arg2 or 0)
    local out = RValue.new(0)
    gmf.array_create(out, nil, nil, 2, holder)
    return Array.wrap(out)
end


--@static
--@return       Array
--@param        array       | RValue or Array wrapper   | The array to wrap.
--[[
Returns an Array wrapper containing the provided array.
]]
Array.wrap = function(array)
    -- Input:   `array RValue` or Array wrapper
    -- Wraps:   `array RValue.i64`
    if not Array.is(array) then log.error("Value is not an array", 2) end
    local proxy = Proxy.new(array.i64, metatable_array)
    __ref_map:set_rvalue(
        RValue.new(array.i64, RValue.Type.ARRAY),
        RValue.new(true)
    )
    return proxy
end


--@static
--@return       Array
--@param        array_i64   | number    | `i64` reference to an array.
--[[
Returns an Array wrapper containing the provided array.
]]
Array.wrap_i64 = function(array_i64)
    -- Input:   number (i64 reference)
    -- Wraps:   `array RValue.i64`
    local proxy = Proxy.new(array_i64, metatable_array)
    __ref_map:set_rvalue(
        RValue.new(array_i64, RValue.Type.ARRAY),
        RValue.new(true)
    )
    return proxy
end


--@static
--@return       bool
--@param        value       | RValue or Array wrapper   | The value to check.
--[[
Returns `true` if `value` is an array, and `false` otherwise.
]]
Array.is = function(value)
    -- `value` is either an `array RValue` or an Array wrapper
    local _type = Util.type(value)
    if (_type == "cdata" and value.type == RValue.Type.ARRAY)
    or _type == "Array" then return true end
    return false
end



-- ========== Instance Methods ==========

--@section Instance Methods

methods_array = {

    --@instance
    --@return       any
    --@param        index       | number    | The index to get from.
    --[[
    Returns the value at the specified index, starting at `0`.
    You can also use Lua syntax (e.g., `array[4]`), which starts at `1`.
    ]]
    get = function(self, index, size)
        size = size or self:size()
        if index >= size then log.error("Array index out of bounds", 2) end
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(self.value, RValue.Type.ARRAY)
        holder[1] = RValue.from_wrapper(index)
        local out = RValue.new(0)
        gmf.array_get(out, nil, nil, 2, holder)
        return RValue.to_wrapper(out)
    end,


    --@instance
    --@param        index       | number    | The index to set to.
    --@param        value       |           | The value to set.
    --[[
    Sets the value at the specified index, starting at `0`.
    You can also use Lua syntax (e.g., `array[4] = 56`), which starts at `1`.
    ]]
    set = function(self, index, value)
        local holder = RValue.new_holder(3)
        holder[0] = RValue.new(self.value, RValue.Type.ARRAY)
        holder[1] = RValue.from_wrapper(index)
        holder[2] = RValue.from_wrapper(value)
        gmf.array_set(RValue.new(0), nil, nil, 3, holder)
    end,


    --@instance
    --@return       number
    --[[
    Returns the size (length) of the array.
    You can also use Lua syntax (i.e., `#array`).
    ]]
    size = function(self)
        local holder = RValue.new_holder(1)
        holder[0] = RValue.new(self.value, RValue.Type.ARRAY)
        local out = RValue.new(0)
        gmf.array_length(out, nil, nil, 1, holder)
        return out.value
    end,


    --@instance
    --@param        size        | number    | The new size.
    --[[
    Resizes the array.
    ]]
    resize = function(self, size)
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(self.value, RValue.Type.ARRAY)
        holder[1] = RValue.new(Wrap.unwrap(size))
        gmf.array_resize(RValue.new(0), nil, nil, 2, holder)
    end,


    --@instance
    --@param        ...         |           | A variable amount of values to push.
    --[[
    Appends values to the end of the array.
    ]]
    push = function(self, ...)
        local values = {...}
        local count = #values + 1

        local holder = RValue.new_holder(count)
        holder[0] = RValue.new(self.value, RValue.Type.ARRAY)

        for i, v in ipairs(values) do
            holder[i] = RValue.from_wrapper(v)
        end

        gmf.array_push(RValue.new(0), nil, nil, count, holder)
    end,


    --@instance
    --@return       any
    --[[
    Removes and returns the last element of the array.
    ]]
    pop = function(self)
        local holder = RValue.new_holder(1)
        holder[0] = RValue.new(self.value, RValue.Type.ARRAY)
        local out = RValue.new(0)
        gmf.array_pop(out, nil, nil, 1, holder)
        return RValue.to_wrapper(out)
    end,


    --@instance
    --@param        index       | number    | The index to insert at.
    --@param        value       |           | The value to insert.
    --[[
    Inserts a value at the specified index, starting at `0`.
    ]]
    insert = function(self, index, value)
        local holder = RValue.new_holder(3)
        holder[0] = RValue.new(self.value, RValue.Type.ARRAY)
        holder[1] = RValue.from_wrapper(index)
        holder[2] = RValue.from_wrapper(value)
        gmf.array_insert(RValue.new(0), nil, nil, 3, holder)
    end,


    --@instance
    --@param        index       | number    | The index to delete at.
    --@optional     number      | number    | The number of values to delete. <br>`1` by default.
    --[[
    Deletes value(s) from the specified index, starting at `0`.
    ]]
    delete = function(self, index, number)
        local holder = RValue.new_holder(3)
        holder[0] = RValue.new(self.value, RValue.Type.ARRAY)
        holder[1] = RValue.from_wrapper(index)
        holder[2] = RValue.from_wrapper(number or 1)
        gmf.array_delete(RValue.new(0), nil, nil, 3, holder)
    end,


    --@instance
    --@param        value       |           | The value to delete.
    --[[
    Deletes the first occurence of the specified value.
    ]]
    delete_value = function(self, value)
        local index = self:find(value)
        if not index then return end
        local holder = RValue.new_holder(3)
        holder[0] = RValue.new(self.value, RValue.Type.ARRAY)
        holder[1] = RValue.new(index)
        holder[2] = RValue.new(1)
        gmf.array_delete(RValue.new(0), nil, nil, 3, holder)
    end,


    --@instance
    --[[
    Deletes all elements in the array and resizes it to 0.
    ]]
    clear = function(self)
        local holder = RValue.new_holder(3)
        holder[0] = RValue.new(self.value, RValue.Type.ARRAY)
        holder[1] = RValue.new(0)
        holder[2] = RValue.new(self:size())
        gmf.array_delete(RValue.new(0), nil, nil, 3, holder)
    end,


    --@instance
    --@return       bool
    --@param        value       |           | The value to check.
    --@optional     offset      | number    | The starting index of a subset to search in (`0`-based). <br>`0` by default.
    --@optional     length      | number    | The length of the subset. <br>`#array` by default.
    --[[
    Returns `true` if the array contains the specified value.
    ]]
    contains = function(self, value, offset, length)
        local holder = RValue.new_holder(4)
        holder[0] = RValue.new(self.value, RValue.Type.ARRAY)
        holder[1] = RValue.from_wrapper(value)
        holder[2] = RValue.from_wrapper(offset or 0)
        holder[3] = RValue.from_wrapper(length or self:size())
        local out = RValue.new(0)
        gmf.array_contains(out, nil, nil, 4, holder)
        return RValue.to_wrapper(out)
    end,


    --@instance
    --@return       number
    --@param        value       |           | The value to search for.
    --[[
    Returns the index of the first occurence of the specified value.
    ]]
    find = function(self, value)
        value = Wrap.unwrap(value)
        for i, v in ipairs(self) do
            if v == value then return i - 1 end
        end
        return nil
    end,


    --@instance
    --@optional     descending  | bool      | If `true`, will sort in descending order. <br>`false` by default.
    --[[
    Returns the index of the first occurence of the specified value.
    ]]
    sort = function(self, descending)
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(self.value, RValue.Type.ARRAY)
        holder[1] = RValue.from_wrapper(not descending, RValue.Type.BOOL)
        gmf.array_sort(RValue.new(0), nil, nil, 2, holder)
    end,


    --@instance
    --[[
    Prints the array.
    ]]
    print = function(self)
        local str = ""
        local padding = #tostring(#self) + 2
        for i, v in ipairs(self) do
            str = str.."\n"..Util.pad_string_right("["..(i - 1).."]", padding).."  "..Util.tostring(v)
        end
        print(str)
    end
    
}



-- ========== Metatables ==========

make_table_once("metatable_array_class", {
    __call = function(t, arg1, arg2)
        arg1 = Wrap.unwrap(arg1)
        arg2 = Wrap.unwrap(arg2)

        -- Wrap
        if Array.is(arg1) then return Array.wrap(arg1) end

        -- New
        return Array.new(arg1, arg2)
    end,


    __metatable = "RAPI.Class.Array"
})
setmetatable(Array, metatable_array_class)


make_table_once("metatable_array", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" or k == "i64" then return Proxy.get(proxy) end
        if k == "RAPI" then return getmetatable(proxy):sub(14, -1) end
        
        -- Methods
        if methods_array[k] then
            return methods_array[k]
        end

        -- Getter
        k = tonumber(Wrap.unwrap(k))
        if k and k >= 1 and k <= #proxy then
            return proxy:get(k - 1)
        end
        return nil
    end,
    

    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "i64"
        or k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end
        
        -- Setter
        k = tonumber(Wrap.unwrap(k))
        if k then proxy:set(k - 1, v) end
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


    __gc = function(proxy)
        __ref_map:delete_rvalue(
            RValue.new(Proxy.get(proxy), RValue.Type.ARRAY)
        )
    end,


    __metatable = "RAPI.Wrapper.Array"
})



-- Public export
__class.Array = Array
__class_mt.Array = metatable_array_class