-- Actor

Actor = {}



-- ========== Instance Methods ==========

methods_actor = {

    kill = function(self)
        if self.value == -4 then return end
        self.value:actor_kill()
    end,


    item_give = function(self, item, count, kind)
        item = Wrap.unwrap(item)
        gm.item_give(self.value, item, count or 1, kind or Item.STACK_KIND.normal)
    end,


    item_take = function(self, item, count, kind)
        item = Wrap.unwrap(item)
        gm.item_take(self.value, item, count or 1, kind or Item.STACK_KIND.normal)
    end,


    item_count = function(self, item, kind)
        item = Wrap.unwrap(item)
        return gm.item_count(self.value, item, kind or Item.STACK_KIND.any)
    end

}



-- ========== Metatables ==========

metatable_actor = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(t) end
        if k == "RAPI" then return getmetatable(t):sub(14, -1) end

        -- Methods
        if methods_actor[k] then
            return methods_actor[k]
        end

        -- Pass to metatable_instance
        return metatable_instance.__index(t, k)
    end,


    __newindex = function(t, k, v)
        -- Pass to metatable_instance
        metatable_instance.__newindex(t, k, v)
    end,

    
    __metatable = "RAPI.Wrapper.Actor"
}



_CLASS["Actor"] = Actor