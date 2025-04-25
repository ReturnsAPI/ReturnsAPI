-- List

--[[
This class allows for easier manipulation of GameMaker DS Lists.
DS structures should always be destroyed once
they are no longer in use to free up memory.
]]

List = new_class()



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       List
--@optional     table       | table     | A numerically-indexed Lua table to convert into a list.
--[[
Returns a newly created GameMaker list.
]]
List.new = function(table)
    if type(table) == "table" then
        local out = RValue.new(0)
        gmf.ds_list_create(out, nil, nil, 0, nil)
        local list = List.wrap(out.value)

        -- Add elements from table to list
        for _, v in ipairs(table) do
            list:add(Wrap.unwrap(v))
        end
        return list
    end

    local out = RValue.new(0)
    gmf.ds_list_create(out, nil, nil, 0, nil)
    return List.wrap(out.value)
end


--@static
--@return       List
--@param        list        | number    | The ID of the list.
--[[
Returns a List wrapper containing the provided list ID.
]]
List.wrap = function(list)
    -- Input:   number or List wrapper
    -- Wraps:   number
    return Proxy.new(Wrap.unwrap(list), metatable_list)
end



-- ========== Instance Methods ==========

--@section Instance Methods

methods_list = {

    --@instance
    --@return       bool
    --[[
    Returns `true` if the DS List exists.
    ]]
    exists = function(self)
        if self.value == -4 then return false end
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(self.value)
        holder[1] = RValue.new(2)
        local out = RValue.new(0)
        gmf.ds_exists(out, nil, nil, 2, holder)
        local ret = (out.value == 1)
        if not ret then Proxy.set(self, -4) end
        return ret
    end,


    --@instance
    --[[
    Destroys the DS List.
    ]]
    destroy = function(self)
        local holder = RValue.new_holder(1)
        holder[0] = RValue.new(self.value)
        gmf.ds_list_destroy(RValue.new(0), nil, nil, 1, holder)
        Proxy.set(self, -4)
    end,


    --@instance
    --@return       any
    --@param        index       | number    | The index to get from.
    --[[
    Returns the value at the specified index, starting at `0`.
    You can also use Lua syntax (e.g., `list[4]`), which starts at `1`.
    ]]
    get = function(self, index, size)
        size = size or self:size()
        if index >= size then log.error("List index out of bounds", 2) end
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(self.value)
        holder[1] = RValue.from_wrapper(index)
        local out = RValue.new(0)
        gmf.ds_list_find_value(out, nil, nil, 2, holder)
        return RValue.to_wrapper(out)
    end,


    --@instance
    --@param        index       | number    | The index to set to.
    --@param        value       |           | The value to set.
    --[[
    Sets the value at the specified index, starting at `0`.
    You can also use Lua syntax (e.g., `list[4] = 56`), which starts at `1`.
    ]]
    set = function(self, index, value)
        local holder = RValue.new_holder(3)
        holder[0] = RValue.new(self.value)
        holder[1] = RValue.from_wrapper(index)
        holder[2] = RValue.from_wrapper(value)
        gmf.ds_list_set(RValue.new(0), nil, nil, 3, holder)
    end,


    --@instance
    --@return       number
    --[[
    Returns the size (length) of the list.
    You can also use Lua syntax (i.e., `#list`).
    ]]
    size = function(self)
        local holder = RValue.new_holder(1)
        holder[0] = RValue.new(self.value)
        local out = RValue.new(0)
        gmf.ds_list_size(out, nil, nil, 1, holder)
        return out.value
    end,


    --@instance
    --@param        ...         |           | A variable amount of values to add.
    --[[
    Appends values to the end of the array.
    ]]
    add = function(self, ...)
        local values = {...}
        local count = #values + 1

        local holder = RValue.new_holder(count)
        holder[0] = RValue.new(self.value)

        for i, v in ipairs(values) do
            holder[i] = RValue.from_wrapper(v)
        end

        gmf.ds_list_add(RValue.new(0), nil, nil, count, holder)
    end,


    --@instance
    --@param        index       | number    | The index to insert at.
    --@param        value       |           | The value to insert.
    --[[
    Inserts a value at the specified index, starting at `0`.
    ]]
    insert = function(self, index, value)
        local holder = RValue.new_holder(3)
        holder[0] = RValue.new(self.value)
        holder[1] = RValue.from_wrapper(index)
        holder[2] = RValue.from_wrapper(value)
        gmf.ds_list_insert(RValue.new(0), nil, nil, 3, holder)
    end,


    --@instance
    --@param        index       | number    | The index to delete at.
    --[[
    Deletes the value from the specified index, starting at `0`.
    ]]
    delete = function(self, index)
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(self.value)
        holder[1] = RValue.from_wrapper(index)
        gmf.ds_list_delete(RValue.new(0), nil, nil, 2, holder)
    end,


    --@instance
    --@param        value       |           | The value to delete.
    --[[
    Deletes the first occurence of the specified value.
    ]]
    delete_value = function(self, value)
        local index = self:find(value)
        if not index then return end
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(self.value)
        holder[1] = RValue.from_wrapper(index)
        gmf.ds_list_delete(RValue.new(0), nil, nil, 2, holder)
    end,


    --@instance
    --[[
    Deletes all elements in the list.
    ]]
    clear = function(self)
        local holder = RValue.new_holder(1)
        holder[0] = RValue.new(self.value)
        gmf.ds_list_clear(RValue.new(0), nil, nil, 1, holder)
    end,


    --@instance
    --@return       bool
    --@param        value       |           | The value to check.
    --[[
    Returns `true` if the list contains the specified value.
    ]]
    contains = function(self, value)
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(self.value)
        holder[1] = RValue.from_wrapper(value)
        local out = RValue.new(0)
        gmf.ds_list_find_index(out, nil, nil, 2, holder)
        local ret = RValue.to_wrapper(out)
        return ret >= 0
    end,


    --@instance
    --@return       number
    --@param        value       |           | The value to search for.
    --[[
    Returns the index of the first occurence of the specified value.
    ]]
    find = function(self, value)
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(self.value)
        holder[1] = RValue.from_wrapper(value)
        local out = RValue.new(0)
        gmf.ds_list_find_index(out, nil, nil, 2, holder)
        local ret = RValue.to_wrapper(out)
        if ret < 0 then return nil end
        return ret
    end,


    --@instance
    --@optional     descending  | bool      | If `true`, will sort in descending order. <br>`false` by default.
    --[[
    Returns the index of the first occurence of the specified value.
    ]]
    sort = function(self, descending)
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(self.value)
        holder[1] = RValue.from_wrapper(not descending, RValue.Type.BOOL)
        gmf.ds_list_sort(RValue.new(0), nil, nil, 2, holder)
    end,

    
    --@instance
    --[[
    Prints the list.
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

make_table_once("metatable_list_class", {
    __call = function(t, value)
        value = Wrap.unwrap(value)

        -- New (from table)
        if type(value) == "table" then return List.new(value) end

        -- Wrap
        if value then return List.wrap(value) end

        -- New
        return List.new()
    end,


    __metatable = "RAPI.Class.List"
})
setmetatable(List, metatable_list_class)


make_table_once("metatable_list", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(proxy) end
        if k == "RAPI" then return getmetatable(proxy):sub(14, -1) end
        
        -- Methods
        if methods_list[k] then
            return methods_list[k]
        end

        -- Getter
        if Proxy.get(proxy) == -4 then log.error("List does not exist", 2) end
        k = tonumber(Wrap.unwrap(k))
        if k and k >= 1 and k <= #proxy then
            return proxy:get(k - 1)
        end
        return nil
    end,
    

    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        if Proxy.get(proxy) == -4 then log.error("List does not exist", 2) end
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

    
    __metatable = "RAPI.Wrapper.List"
})



-- Public export
__class.List = List
__class_mt.List = metatable_list_class