-- Array

Array = new_class()



-- ========== Static Methods ==========

Array.new = function(arg1, arg2)
    arg1 = Wrap.unwrap(arg1)

    -- Overload 1
    -- Create array from table
    if type(arg1) == "table" then
        local array = gm.array_create(0)
        for _, v in ipairs(arg1) do
            gm.array_push(array, Wrap.unwrap(v))
        end
        return Proxy.new(array, metatable_array)
    end

    -- Overload 2
    -- Create array with optional size and default value
    return Proxy.new(gm.array_create(arg1 or 0, arg2 or 0), metatable_array)
end


Array.wrap = function(array)
    if userdata_type(array) ~= "sol.RefDynamicArrayOfRValue*" then
        log.error("Value is not an array", 2)
    end

    return Proxy.new(array, metatable_array)
end



-- ========== Instance Methods ==========

methods_array = {

    get = function(self, index)
        index = Wrap.unwrap(index)
        if index < 0 or index >= #self then return nil end
        return Wrap.wrap(gm.array_get(self.value, index))
    end,


    set = function(self, index, value)
        gm.array_set(self.value, Wrap.unwrap(index), Wrap.unwrap(value))
    end,


    size = function(self)
        return gm.array_length(self.value)
    end,


    resize = function(self, size)
        gm.array_resize(self.value, Wrap.unwrap(size))
    end,


    push = function(self, ...)
        local values = {...}
        for _, v in ipairs(values) do
            gm.array_push(self.value, Wrap.unwrap(v))
        end
    end,


    pop = function(self)
        return gm.array_pop(self.value)
    end,


    insert = function(self, index, value)
        gm.array_insert(self.value, Wrap.unwrap(index), Wrap.unwrap(value))
    end,
    

    delete = function(self, index, number)
        gm.array_delete(self.value, Wrap.unwrap(index), number or 1)
    end,


    clear = function(self)
        gm.array_delete(self.value, 0, #self)
    end,


    contains = function(self, value, offset, length)
        return gm.array_contains(self.value, Wrap.unwrap(value), offset or 0, length or (#self - 1))
    end,


    find = function(self, value)
        value = Wrap.unwrap(value)
        for i, v in ipairs(self) do
            if v == value then return i - 1 end
        end
        return nil
    end,


    sort = function(self, descending)
        gm.array_sort(self.value, not descending)
    end
    
}



-- ========== Metatables ==========

metatable_array_class = {
    __call = function(t, value, arg2)
        -- Wrap
        if userdata_type(value) == "sol.RefDynamicArrayOfRValue*" then
            return Proxy.new(value, metatable_array)
        end

        -- Create array from table
        if type(value) == "table" then
            local array = gm.array_create(0)
            for _, v in ipairs(value) do
                gm.array_push(array, Wrap.unwrap(v))
            end
            return Proxy.new(array, metatable_array)
        end

        -- Create array with optional size and default value
        return Proxy.new(gm.array_create(value or 0, arg2 or 0), metatable_array)
    end,


    __metatable = "RAPI.Class.Array"
}
setmetatable(Array, metatable_array_class)


metatable_array = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(t) end
        if k == "RAPI" then return getmetatable(t):sub(14, -1) end
        
        -- Methods
        if methods_array[k] then
            return methods_array[k]
        end

        -- Getter
        k = tonumber(Wrap.unwrap(k))
        if k and k >= 1 and k <= #t then
            return Wrap.wrap(gm.array_get(Proxy.get(t), k - 1))
        end
        return nil
    end,
    

    __newindex = function(t, k, v)
        -- Setter
        k = tonumber(Wrap.unwrap(k))
        if k then
            gm.array_set(Proxy.get(t), k - 1, Wrap.unwrap(v))
        end
    end,
    
    
    __len = function(t)
        return gm.array_length(Proxy.get(t))
    end,


    __metatable = "RAPI.Wrapper.Array"
}



_CLASS["Array"] = Array
_CLASS_MT["Array"] = metatable_array_class