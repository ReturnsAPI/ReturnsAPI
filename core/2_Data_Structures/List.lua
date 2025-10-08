-- List

--[[
This class allows for easier manipulation of GameMaker DS Lists.

DS resources should always be destroyed once
they are no longer in use to free up memory.
]]

List = new_class()



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The ID of the List.
`RAPI`          | string    | *Read-only.* The wrapper name.
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       List
--@optional     table       | table     | A numerically-indexed Lua table to convert into a list.
--[[
Returns a newly created GameMaker list.
]]
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


--@static
--@return       List
--@param        list        | number    | The ID of the list.
--[[
Returns a List wrapper containing the provided list ID.
]]
List.wrap = function(list)
    -- Input:   number or List wrapper
    -- Wraps:   number
    return make_proxy(Wrap.unwrap(list), metatable_list)
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
        local ret = (gm.ds_exists(self.value, 2) == 1)
        if not ret then __proxy[self] = -4 end
        return ret
    end,


    --@instance
    --[[
    Destroys the DS List.
    ]]
    destroy = function(self)
        gm.ds_list_destroy(self.value)
        __proxy[self] = -4
    end,


    --@instance
    --@return       any
    --@param        index       | number    | The index to get from.
    --[[
    Returns the value at the specified index (starting at `0`),
    or `nil` if out-of-bounds.
    You can also use Lua syntax (e.g., `list[4]`), which starts at `1`.
    ]]
    get = function(self, index, size)
        if self.value == -4 then log.error("List does not exist", 2) end
        index = Wrap.unwrap(index)
        size = size or self:size()
        if index >= size then return nil end
        return Wrap.wrap(gm.ds_list_find_value(self.value, index))
    end,


    --@instance
    --@param        index       | number    | The index to set to.
    --@param        value       |           | The value to set.
    --[[
    Sets the value at the specified index, starting at `0`.
    You can also use Lua syntax (e.g., `list[4] = 56`), which starts at `1`.
    ]]
    set = function(self, index, value)
        if self.value == -4 then log.error("List does not exist", 2) end
        gm.ds_list_set(self.value, Wrap.unwrap(index), Wrap.unwrap(value, true))
    end,


    --@instance
    --@return       number
    --[[
    Returns the size (length) of the list.
    You can also use Lua syntax (i.e., `#list`).
    ]]
    size = function(self)
        return gm.ds_list_size(self.value)
    end,


    --@instance
    --@param        ...         |           | A variable amount of values to add.
    --[[
    Appends values to the end of the array.
    ]]
    add = function(self, ...)
        local values = {...}

        for i, v in ipairs(values) do
            values[i] = Wrap.unwrap(v, true)
        end

        gm.ds_list_add(self.value, table.unpack(values))
    end,


    --@instance
    --@param        index       | number    | The index to insert at.
    --@param        value       |           | The value to insert.
    --[[
    Inserts a value at the specified index, starting at `0`.
    ]]
    insert = function(self, index, value)
        gm.ds_list_insert(self.value, Wrap.unwrap(index), Wrap.unwrap(value, true))
    end,


    --@instance
    --@param        index       | number    | The index to delete at.
    --[[
    Deletes the value from the specified index, starting at `0`.
    ]]
    delete = function(self, index)
        gm.ds_list_delete(self.value, Wrap.unwrap(index))
    end,


    --@instance
    --@param        value       |           | The value to delete.
    --[[
    Deletes the first occurence of the specified value.
    ]]
    delete_value = function(self, value)
        local index = self:find(value)
        if not index then return end
        gm.ds_list_delete(self.value, index)
    end,


    --@instance
    --[[
    Deletes all elements in the list.
    ]]
    clear = function(self)
        gm.ds_list_clear(self.value)
    end,


    --@instance
    --@return       bool
    --@param        value       |           | The value to check.
    --[[
    Returns `true` if the list contains the specified value.
    ]]
    contains = function(self, value)
        return (gm.ds_list_find_index(self.value, Wrap.unwrap(value, true)) >= 0)
    end,


    --@instance
    --@return       number
    --@param        value       |           | The value to search for.
    --[[
    Returns the index of the first occurence of the specified value.
    ]]
    find = function(self, value)
        local ret = gm.ds_list_find_index(self.value, Wrap.unwrap(value, true))
        if ret < 0 then return nil end
        return ret
    end,


    --@instance
    --@optional     descending  | bool      | If `true`, will sort in descending order. <br>`false` by default.
    --[[
    Returns the index of the first occurence of the specified value.
    ]]
    sort = function(self, descending)
        gm.ds_list_sort(self.value, not descending)
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

local wrapper_name = "List"

make_table_once("metatable_list", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return __proxy[proxy] end
        if k == "RAPI" then return wrapper_name end
        
        -- Methods
        if methods_list[k] then
            return methods_list[k]
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

    
    __metatable = "RAPI.Wrapper."..wrapper_name
})



-- Public export
__class.List = List