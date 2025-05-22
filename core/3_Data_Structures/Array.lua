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
        local arr = Array.wrap(memory.resolve_pointer_to_type(tonumber(out.i64), "RefDynamicArrayOfRValue*"))

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
    return Array.wrap(memory.resolve_pointer_to_type(tonumber(out.i64), "RefDynamicArrayOfRValue*"))
end


--@static
--@return       Array
--@param        array       | `sol.RefDynamicArrayOfRValue*` or Array wrapper   | The array to wrap.
--[[
Returns an Array wrapper containing the provided array.
]]
Array.wrap = function(array)
    -- Input:   `sol.RefDynamicArrayOfRValue*` or Array wrapper
    -- Wraps:   `sol.RefDynamicArrayOfRValue*`
    array = Wrap.unwrap(array)
    __ref_map:set(array, true)  -- Prevent garbage collection
    return make_proxy(array, metatable_array)
end



-- ========== Instance Methods ==========

--@section Instance Methods

methods_array = {

    --@instance
    --@return       any
    --@param        index       | number    | The index to get from.
    --@optional     size        | number    | The size of the array, if it already known (this skips a `:size` call).
    --[[
    Returns the value at the specified index (starting at `0`),
    or `nil` if out-of-bounds.
    You can also use Lua syntax (e.g., `array[4]`), which starts at `1`.
    ]]
    get = function(self, index, size)
        index = Wrap.unwrap(index)
        size = size or self:size()
        if index >= size then return nil end
        return Wrap.wrap(gm.array_get(self.value, index))
    end,


    --@instance
    --@param        index       | number    | The index to set to.
    --@param        value       |           | The value to set.
    --[[
    Sets the value at the specified index, starting at `0`.
    You can also use Lua syntax (e.g., `array[4] = 56`), which starts at `1`.
    ]]
    set = function(self, index, value)
        gm.array_set(self.value, Wrap.unwrap(index), Wrap.unwrap(value))
    end,


    --@instance
    --@return       number
    --[[
    Returns the size (length) of the array.
    You can also use Lua syntax (i.e., `#array`).
    ]]
    size = function(self)
        return gm.array_length(self.value)
    end,


    --@instance
    --@param        size        | number    | The new size.
    --[[
    Resizes the array.
    ]]
    resize = function(self, size)
        gm.array_resize(self.value, Wrap.unwrap(size))
    end,


    --@instance
    --@param        ...         |           | A variable amount of values to push.
    --[[
    Appends values to the end of the array.
    ]]
    push = function(self, ...)
        local values = {...}

        -- TODO figure out better
        for i, v in ipairs(values) do
            -- if instance_wrappers[Util.type(v)] then
            --     values[i] = v.CInstance
            -- else values[i] = Wrap.unwrap(v)
            -- end
            values[i] = Wrap.unwrap(v)
        end

        gm.array_push(self.value, table.unpack(values))
    end,


    --@instance
    --@return       any
    --[[
    Removes and returns the last element of the array.
    ]]
    pop = function(self)
        return Wrap.wrap(gm.array_pop(self.value))
    end,


    --@instance
    --@param        index       | number    | The index to insert at.
    --@param        value       |           | The value to insert.
    --[[
    Inserts a value at the specified index, starting at `0`.
    ]]
    insert = function(self, index, value)
        gm.array_insert(self.value, Wrap.unwrap(index), Wrap.unwrap(value))
    end,


    --@instance
    --@param        index       | number    | The index to delete at.
    --@optional     number      | number    | The number of values to delete. <br>`1` by default.
    --[[
    Deletes value(s) from the specified index, starting at `0`.
    ]]
    delete = function(self, index, number)
        gm.array_delete(self.value, Wrap.unwrap(index), Wrap.unwrap(number or 1))
    end,


    --@instance
    --@param        value       |           | The value to delete.
    --[[
    Deletes the first occurence of the specified value.
    ]]
    delete_value = function(self, value)
        local index = self:find(Wrap.unwrap(value))
        if not index then return end
        gm.array_delete(self.value, Wrap.unwrap(index), 1)
    end,


    --@instance
    --[[
    Deletes all elements in the array and resizes it to 0.
    ]]
    clear = function(self)
        gm.array_delete(self.value, 0, self:size())
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
        return gm.array_contains(self.value, Wrap.unwrap(value), Wrap.unwrap(offset) or 0, Wrap.unwrap(length) or self:size())
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
        gm.array_sort(self.value, not descending)
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

local wrapper_name = "Array"

make_table_once("metatable_array_class", {
    __metatable = "RAPI.Class."..wrapper_name
})
setmetatable(Array, metatable_array_class)


make_table_once("metatable_array", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return __proxy[proxy] end
        if k == "RAPI" then return wrapper_name end
        
        -- Methods
        if methods_array[k] then
            return methods_array[k]
        end

        -- Getter
        k = Wrap.unwrap(k)
        return proxy:get(k - 1)
    end,
    

    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
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


    __gc = function(proxy)
        __ref_map:delete(__proxy[proxy])
    end,


    __metatable = "RAPI.Wrapper."..wrapper_name
})



-- Public export
__class.Array = Array
__class_mt.Array = metatable_array_class