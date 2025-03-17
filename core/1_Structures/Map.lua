-- Map

Map = new_class()



-- ========== Static Methods ==========

Map.new = function()
    local out = RValue.new(0)
    gmf.ds_map_create(out, nil, nil, 0, nil)
    return Map.wrap(out.value)
end


Map.wrap = function(map)    -- Stores 'real RValue.value'
    return Proxy.new(Wrap.unwrap(map), metatable_map)
end



-- ========== Instance Methods ==========

methods_map = {

    exists = function(self)
        if self.value == -4 then return false end
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(self.value)
        holder[1] = RValue.new(1)
        local out = RValue.new(0)
        gmf.ds_exists(out, nil, nil, 2, holder)
        local ret = (out.value == 1)
        if not ret then Proxy.set(self, -4) end
        return ret
    end,


    destroy = function(self)
        local holder = RValue.new_holder(1)
        holder[0] = RValue.new(self.value)
        gmf.ds_map_destroy(RValue.new(0), nil, nil, 1, holder)
        Proxy.set(self, -4)
    end,


    get = function(self, key)
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(self.value)
        holder[1] = RValue.from_wrapper(key)
        local out = RValue.new(0)
        gmf.ds_map_find_value(out, nil, nil, 2, holder)
        return RValue.to_wrapper(out)
    end,


    set = function(self, key, value)
        local holder = RValue.new_holder(3)
        holder[0] = RValue.new(self.value)
        holder[1] = RValue.from_wrapper(key)
        holder[2] = RValue.from_wrapper(value)
        gmf.ds_map_set(RValue.new(0), nil, nil, 3, holder)
    end,


    size = function(self)
        local holder = RValue.new_holder(1)
        holder[0] = RValue.new(self.value)
        local out = RValue.new(0)
        gmf.ds_map_size(out, nil, nil, 1, holder)
        return out.value
    end,


    delete = function(self, key)
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(self.value)
        holder[1] = RValue.from_wrapper(key)
        gmf.ds_map_delete(RValue.new(0), nil, nil, 2, holder)
    end,


    -- delete_value = function(self, value)
    --     print("Map delete_value", value)
    --     print("Wrap.unwrap", Wrap.unwrap(value))

    --     local index = self:find(value)
    --     if not index then return end
    --     local holder = RValue.new_holder(2)
    --     holder[0] = RValue.new(self.value)
    --     holder[1] = RValue.new(index)
    --     gmf.ds_list_delete(RValue.new(0), nil, nil, 2, holder)
    -- end,


    clear = function(self)
        local holder = RValue.new_holder(1)
        holder[0] = RValue.new(self.value)
        gmf.ds_map_clear(RValue.new(0), nil, nil, 1, holder)
    end,


    -- contains = function(self, value)
    --     local holder = RValue.new_holder(2)
    --     holder[0] = RValue.new(self.value)
    --     holder[1] = RValue.from_wrapper(value)
    --     local out = RValue.new(0)
    --     gmf.ds_list_find_index(out, nil, nil, 2, holder)
    --     local ret = RValue.to_wrapper(out)
    --     return ret >= 0
    -- end,


    -- find = function(self, value)
    --     local holder = RValue.new_holder(2)
    --     holder[0] = RValue.new(self.value)
    --     holder[1] = RValue.from_wrapper(value)
    --     local out = RValue.new(0)
    --     gmf.ds_list_find_index(out, nil, nil, 2, holder)
    --     local ret = RValue.to_wrapper(out)
    --     if ret < 0 then return nil end
    --     return ret
    -- end,


    -- sort = function(self, descending)
    --     local holder = RValue.new_holder(2)
    --     holder[0] = RValue.new(self.value)
    --     holder[1] = RValue.new(not descending, RValue.Type.BOOL)
    --     gmf.ds_list_sort(RValue.new(0), nil, nil, 2, holder)
    -- end

}



-- ========== Metatables ==========

metatable_map_class = {
    __call = function(t, value)
        return Map.new()
    end,


    __metatable = "RAPI.Class.Map"
}
setmetatable(Map, metatable_map_class)


metatable_map = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(t) end
        if k == "RAPI" then return getmetatable(t):sub(14, -1) end
        
        -- Methods
        if methods_map[k] then
            return methods_map[k]
        end

        -- Getter
        if Proxy.get(t) == -4 then log.error("Map does not exist", 2) end
        k = tonumber(Wrap.unwrap(k))
        if k and k >= 1 and k <= #t then
            return t:get(k - 1)
        end
        return nil
    end,
    

    __newindex = function(t, k, v)
        -- Setter
        if Proxy.get(t) == -4 then log.error("Map does not exist", 2) end
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

    
    __metatable = "RAPI.Wrapper.Map"
}



-- Create __ref_map
__ref_map = Map.new()

_CLASS["Map"] = Map
_CLASS_MT["Map"] = metatable_map_class