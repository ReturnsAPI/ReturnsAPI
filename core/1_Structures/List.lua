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

    destroy = function(self)
        local holder = RValue.new_holder(1)
        holder[0] = RValue.new(self.value)
        gmf.ds_list_destroy(RValue.new(0), nil, nil, 1, holder)
    end,


    get = function(self, index, size)
        size = size or self:size()
        if index >= size then log.error("List index out of bounds", 2) end
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(self.value)
        holder[1] = RValue.new(index)
        local out = RValue.new(0)
        gmf.ds_list_find_value(out, nil, nil, 2, holder)
        return RValue.to_wrapper(out)
    end,


    set = function(self, index, value)
        local holder = RValue.new_holder(3)
        holder[0] = RValue.new(self.value)
        holder[1] = RValue.new(index)
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
        holder[1] = RValue.new(index)
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
        holder[1] = RValue.new(not descending, RValue.Type.BOOL)
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
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(t) end
        if k == "RAPI" then return getmetatable(t):sub(14, -1) end
        
        -- Methods
        if methods_list[k] then
            return methods_list[k]
        end

        -- Getter
        k = tonumber(Wrap.unwrap(k))
        if k and k >= 1 and k <= #t then
            return t:get(k - 1)
        end
        return nil
    end,
    

    __newindex = function(t, k, v)
        -- Setter
        k = tonumber(Wrap.unwrap(k))
        if k then t:set(k - 1, v) end
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

    
    __metatable = "RAPI.Wrapper.List"
}



-- Create __ref_list
__ref_list = List.new()

_CLASS["List"] = List
_CLASS_MT["List"] = metatable_list_class