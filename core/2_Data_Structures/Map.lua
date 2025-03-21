-- Map

Map = new_class()



-- ========== Static Methods ==========

Map.new = function(table)
    if type(table) == "table" then
        local out = RValue.new(0)
        gmf.ds_map_create(out, nil, nil, 0, nil)
        local map = Map.wrap(out.value)

        -- Add key-value pairs from table to map
        for k, v in pairs(table) do
            map:set(k, v)
        end
        return map
    end

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


    clear = function(self)
        local holder = RValue.new_holder(1)
        holder[0] = RValue.new(self.value)
        gmf.ds_map_clear(RValue.new(0), nil, nil, 1, holder)
    end

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
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(proxy) end
        if k == "RAPI" then return getmetatable(proxy):sub(14, -1) end
        
        -- Methods
        if methods_map[k] then
            return methods_map[k]
        end

        -- Getter
        if Proxy.get(proxy) == -4 then log.error("Map does not exist", 2) end
        return proxy:get(k)
    end,
    

    __newindex = function(proxy, k, v)
        -- Setter
        if Proxy.get(proxy) == -4 then log.error("Map does not exist", 2) end
        proxy:set(k, v)
    end,
    
    
    __len = function(proxy)
        return proxy:size()
    end,


    __pairs = function(proxy)
        -- Find first key
        local holder = RValue.new_holder(1)
        holder[0] = RValue.new(Proxy.get(proxy))
        local out = RValue.new(0)
        gmf.ds_map_find_first(out, nil, nil, 1, holder)
        local key = RValue.to_wrapper(out)

        return function(proxy)
            if not key then return nil, nil end
            local ret1, ret2 = key, proxy:get(key)

            -- Find next key
            local holder = RValue.new_holder(2)
            holder[0] = RValue.new(Proxy.get(proxy))
            holder[1] = RValue.from_wrapper(key)
            local out = RValue.new(0)
            gmf.ds_map_find_next(out, nil, nil, 2, holder)
            key = RValue.to_wrapper(out)

            return ret1, ret2
        end, proxy, nil
    end,

    
    __metatable = "RAPI.Wrapper.Map"
}



-- Create __ref_map
if __ref_map then __ref_map:destroy() end
__ref_map = Map.new()

__class.Map = Map
__class_mt.Map = metatable_map_class