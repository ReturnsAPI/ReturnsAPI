-- Actor

Actor = {}



-- ========== Instance Methods ==========

methods_actor = {

    kill = function(self)
        if self.value == -4 then return end
        self.value:actor_kill()
    end

}



-- ========== Metatables ==========

metatable_actor = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(t) end
        if k == "RAPI" then return getmetatable(t):sub(6, -1) end

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