-- List

List = new_class()



-- ========== Static Methods ==========

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


List.wrap = function(list)  -- Stores 'real RValue.value'
    return Proxy.new(Wrap.unwrap(list), metatable_list)
end



-- ========== Instance Methods ==========

methods_list = {

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


    destroy = function(self)
        local holder = RValue.new_holder(1)
        holder[0] = RValue.new(self.value)
        gmf.ds_list_destroy(RValue.new(0), nil, nil, 1, holder)
        Proxy.set(self, -4)
    end,


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


    set = function(self, index, value)
        local holder = RValue.new_holder(3)
        holder[0] = RValue.new(self.value)
        holder[1] = RValue.from_wrapper(index)
        holder[2] = RValue.from_wrapper(value)
        gmf.ds_list_set(RValue.new(0), nil, nil, 3, holder)
    end,


    size = function(self)
        local holder = RValue.new_holder(1)
        holder[0] = RValue.new(self.value)
        local out = RValue.new(0)
        gmf.ds_list_size(out, nil, nil, 1, holder)
        return out.value
    end,


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


    insert = function(self, index, value)
        local holder = RValue.new_holder(3)
        holder[0] = RValue.new(self.value)
        holder[1] = RValue.from_wrapper(index)
        holder[2] = RValue.from_wrapper(value)
        gmf.ds_list_insert(RValue.new(0), nil, nil, 3, holder)
    end,


    delete = function(self, index)
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(self.value)
        holder[1] = RValue.from_wrapper(index)
        gmf.ds_list_delete(RValue.new(0), nil, nil, 2, holder)
    end,


    delete_value = function(self, value)
        local index = self:find(value)
        if not index then return end
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(self.value)
        holder[1] = RValue.from_wrapper(index)
        gmf.ds_list_delete(RValue.new(0), nil, nil, 2, holder)
    end,


    clear = function(self)
        local holder = RValue.new_holder(1)
        holder[0] = RValue.new(self.value)
        gmf.ds_list_clear(RValue.new(0), nil, nil, 1, holder)
    end,


    contains = function(self, value)
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(self.value)
        holder[1] = RValue.from_wrapper(value)
        local out = RValue.new(0)
        gmf.ds_list_find_index(out, nil, nil, 2, holder)
        local ret = RValue.to_wrapper(out)
        return ret >= 0
    end,


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


    sort = function(self, descending)
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(self.value)
        holder[1] = RValue.from_wrapper(not descending, RValue.Type.BOOL)
        gmf.ds_list_sort(RValue.new(0), nil, nil, 2, holder)
    end

}



-- ========== Metatables ==========

metatable_list_class = {
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
}
setmetatable(List, metatable_list_class)


metatable_list = {
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
}



__class.List = List
__class_mt.List = metatable_list_class