-- Array

Array = new_class()



-- ========== Static Methods ==========

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


Array.wrap = function(array)    -- Stores `array RValue.i64`
    -- `array` is either an `array RValue` or an Array wrapper
    if not Array.is(array) then log.error("Value is not an array", 2) end
    local proxy = Proxy.new(array.i64, metatable_array)
    __ref_map:set(proxy, true)
    return proxy
end


Array.wrap_i64 = function(array)    -- Stores `array RValue.i64`
    -- `array` is a number
    local proxy = Proxy.new(array, metatable_array)
    __ref_map:set(proxy, true)
    return proxy
end


Array.is = function(value)
    -- `value` is either an `array RValue` or an Array wrapper
    local _type = Util.type(value)
    if (_type == "cdata" and value.type == RValue.Type.ARRAY)
    or _type == "Array" then return true end
    return false
end



-- ========== Instance Methods ==========

methods_array = {

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


    set = function(self, index, value)
        local holder = RValue.new_holder(3)
        holder[0] = RValue.new(self.value, RValue.Type.ARRAY)
        holder[1] = RValue.from_wrapper(index)
        holder[2] = RValue.from_wrapper(value)
        gmf.array_set(RValue.new(0), nil, nil, 3, holder)
    end,


    size = function(self)
        local holder = RValue.new_holder(1)
        holder[0] = RValue.new(self.value, RValue.Type.ARRAY)
        local out = RValue.new(0)
        gmf.array_length(out, nil, nil, 1, holder)
        return out.value
    end,


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


    pop = function(self)
        local holder = RValue.new_holder(1)
        holder[0] = RValue.new(self.value, RValue.Type.ARRAY)
        local out = RValue.new(0)
        gmf.array_pop(out, nil, nil, 1, holder)
        return RValue.to_wrapper(out)
    end,


    insert = function(self, index, value)
        local holder = RValue.new_holder(3)
        holder[0] = RValue.new(self.value, RValue.Type.ARRAY)
        holder[1] = RValue.from_wrapper(index)
        holder[2] = RValue.from_wrapper(value)
        gmf.array_insert(RValue.new(0), nil, nil, 3, holder)
    end,


    delete = function(self, index, number)
        local holder = RValue.new_holder(3)
        holder[0] = RValue.new(self.value, RValue.Type.ARRAY)
        holder[1] = RValue.from_wrapper(index)
        holder[2] = RValue.from_wrapper(number or 1)
        gmf.array_delete(RValue.new(0), nil, nil, 3, holder)
    end,


    delete_value = function(self, value)
        local index = self:find(value)
        if not index then return end
        local holder = RValue.new_holder(3)
        holder[0] = RValue.new(self.value, RValue.Type.ARRAY)
        holder[1] = RValue.from_wrapper(index)
        holder[2] = RValue.new(1)
        gmf.array_delete(RValue.new(0), nil, nil, 3, holder)
    end,


    clear = function(self)
        local holder = RValue.new_holder(3)
        holder[0] = RValue.new(self.value, RValue.Type.ARRAY)
        holder[1] = RValue.new(0)
        holder[2] = RValue.new(self:size())
        gmf.array_delete(RValue.new(0), nil, nil, 3, holder)
    end,


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


    find = function(self, value)
        value = Wrap.unwrap(value)
        for i, v in ipairs(self) do
            if v == value then return i - 1 end
        end
        return nil
    end,


    sort = function(self, descending)
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(self.value, RValue.Type.ARRAY)
        holder[1] = RValue.from_wrapper(not descending, RValue.Type.BOOL)
        gmf.array_sort(RValue.new(0), nil, nil, 2, holder)
    end
    
}



-- ========== Metatables ==========

metatable_array_class = {
    __call = function(t, arg1, arg2)
        arg1 = Wrap.unwrap(arg1)
        arg2 = Wrap.unwrap(arg2)

        -- Wrap
        if Array.is(arg1) then return Array.wrap(arg1) end

        -- New
        return Array.new(arg1, arg2)
    end,


    __metatable = "RAPI.Class.Array"
}
setmetatable(Array, metatable_array_class)


metatable_array = {
    __index = function(proxy, k)
        -- Return value or RAPI type
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
        __ref_map:delete(proxy)
    end,


    __metatable = "RAPI.Wrapper.Array"
}



__class.Array = Array
__class_mt.Array = metatable_array_class