-- Player

Player = new_class()



-- ========== Static Methods ==========

Player.get_local = function()
    if gm._mod_net_isOnline() then
        return Instance.internal.wrap(gm.variable_global_get("my_player"), metatable_player)
    end
    local instance = gm.instance_find(gm.constants.oP, 0)
    if instance ~= -4 then return Instance.internal.wrap(instance, metatable_player) end
    return Instance.wrap_invalid()
end



-- ========== Instance Methods ==========

methods_player = {



}



-- ========== Metatables ==========

metatable_player = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(t) end
        if k == "RAPI" then return getmetatable(t):sub(14, -1) end

        -- Methods
        if methods_player[k] then
            return methods_player[k]
        end

        -- Pass to metatable_actor
        return metatable_actor.__index(t, k)
    end,


    __newindex = function(t, k, v)
        -- Pass to metatable_instance
        metatable_instance.__newindex(t, k, v)
    end,

    
    __metatable = "RAPI.Wrapper.Player"
}



_CLASS["Player"] = Player