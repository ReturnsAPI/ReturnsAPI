-- List

List = new_class()



-- ========== Static Methods ==========

List.new = function(table)
    if table then
        local out = gmf.rvalue_new(0)
        gmf.ds_list_create(out, nil, nil, 0, nil)
        local list = List.wrap(out)

        -- Add elements from table to list
        for _, v in ipairs(table) do
            list:add(Wrap.unwrap(v))
        end
        return list
    end

    local out = gmf.rvalue_new(0)
    gmf.ds_list_create(out, nil, nil, 0, nil)
    return List.wrap(out)
end


List.wrap = function(list)
    return Proxy.new(Wrap.unwrap(list), metatable_list)
end



-- ========== Instance Methods ==========

methods_list = {

    destroy = function(self)
        local holder = ffi.new("struct RValue[1]")
        holder[0] = self.value
        gmf.ds_list_destroy(nil, nil, nil, 1, holder)
    end,


    get = function(self, index)
        if index >= self:size() then log.error("List index out of bounds", 2) end
        local holder = ffi.new("struct RValue[2]")
        holder[0] = self.value
        holder[1] = gmf.rvalue_new(index)
        local out = gmf.rvalue_new(0)
        gmf.ds_list_find_value(out, nil, nil, 2, holder)
        return Wrap.wrap(out)
    end,


    set = function(self, index, value)
        local holder = ffi.new("struct RValue[3]")
        holder[0] = self.value
        holder[1] = gmf.rvalue_new(index)
        holder[2] = gmf.rvalue_new_auto(Wrap.unwrap(value))
        gmf.ds_list_set(nil, nil, nil, 3, holder)
    end,


    size = function(self)
        local holder = ffi.new("struct RValue[1]")
        holder[0] = self.value
        local out = gmf.rvalue_new(0)
        gmf.ds_list_size(out, nil, nil, 1, holder)
        return Wrap.wrap(out)
    end,


    add = function(self, ...)
        local values = {...}

        local holder = ffi.new("struct RValue[2]")
        holder[0] = self.value

        for _, v in ipairs(values) do
            holder[1] = gmf.rvalue_new_auto(Wrap.unwrap(v))
            gmf.ds_list_add(nil, nil, nil, 2, holder)
        end
    end

}



-- ========== Metatables ==========

metatable_list_class = {
    __call = function(t, value, arg2)
        
    end,


    __metatable = "RAPI.Class.List"
}
setmetatable(List, metatable_list_class)


metatable_list = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(t) end
        if k == "type" then return getmetatable(t):sub(14, -1) end
        
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
        return function(t, k)
            k = k + 1
            if k <= #t then return k, t[k] end
        end, t, 0
    end,


    __ipairs = function(t)
        return function(t, k)
            k = k + 1
            if k <= #t then return k, t[k] end
        end, t, 0
    end,

    
    __metatable = "RAPI.Wrapper.List"
}



_CLASS["List"] = List
_CLASS_MT["List"] = metatable_list_class