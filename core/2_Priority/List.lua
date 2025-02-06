-- List

List = {}



-- ========== Static Methods ==========

List.new = function(table)
    if table then
        local list = gm.ds_list_create()
        for _, v in ipairs(table) do
            gm.ds_list_add(list, Wrap.unwrap(v))
        end
        return List.wrap(list)
    end

    return List.wrap(gm.ds_list_create())
end


List.wrap = function(list)
    return Proxy.new(list, metatable_list)
end



-- ========== Instance Methods ==========

methods_list = {

    exists = function(self)
        return gm.ds_exists(self.value, 2) == 1
    end,


    destroy = function(self)
        gm.ds_list_destroy(self.value)
    end,


    get = function(self, index)
        return Wrap.wrap(gm.ds_list_find_value(self.value, Wrap.unwrap(index)))
    end,


    set = function(self, index, value)
        gm.ds_list_set(self.value, Wrap.unwrap(index), Wrap.unwrap(value))
    end,


    size = function(self)
        return gm.ds_list_size(self.value)
    end,


    add = function(self, ...)
        local values = {...}
        for _, v in ipairs(values) do
            gm.ds_list_add(self.value, Wrap.unwrap(v))
        end
    end,


    insert = function(self, index, value)
        gm.ds_list_insert(self.value, index, Wrap.unwrap(value))
    end,
    

    delete = function(self, index)
        gm.ds_list_delete(self.value, index)
    end,

    
    clear = function(self)
        gm.ds_list_clear(self.value)
    end,


    contains = function(self, value)
        return gm.ds_list_find_index(self.value, Wrap.unwrap(value)) >= 0
    end,


    find = function(self, value)
        local pos = gm.ds_list_find_index(self.value, Wrap.unwrap(value))
        if pos < 0 then return nil end
        return pos
    end,


    sort = function(self, descending)
        gm.ds_list_sort(self.value, not descending)
    end

}



-- ========== Metatables ==========

metatable_list_class = {
    __call = function(t, value, arg2)
        -- Create list from table
        if type(value) == "table" then
            local list = gm.ds_list_create()
            for _, v in ipairs(value) do
                gm.ds_list_add(list, Wrap.unwrap(v))
            end
            return List.wrap(list)
        end

        -- Wrap
        if value then
            return Proxy.new(value, metatable_list)
        end

        -- Create list
        return List.wrap(gm.ds_list_create())
    end,


    __metatable = "List class"
}
setmetatable(List, metatable_list_class)


metatable_list = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(t) end

        -- Methods
        if methods_list[k] then
            return methods_list[k]
        end

        -- Getter
        k = tonumber(Wrap.unwrap(k))
        if k and k >= 1 and k <= #table then
            return Wrap.wrap(gm.ds_list_find_value(Proxy.get(t), k - 1))
        end
        return nil
    end,
    

    __newindex = function(t, k, v)
        -- Setter
        k = tonumber(Wrap.unwrap(k))
        if k then
            gm.ds_list_set(Proxy.get(t), k - 1, Wrap.unwrap(v))
        end
    end,
    
    
    __len = function(t)
        return gm.ds_list_size(Proxy.get(t))
    end,

    
    __metatable = "List"
}



_CLASS["List"] = List
_CLASS_MT["List"] = metatable_list_class