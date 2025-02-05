-- Player

Player = {}



-- ========== Static Methods ==========

Player.get_local = function()
    if gm._mod_net_isOnline() then
        return Instance.wrap(gm.variable_global_get("my_player"))
    end
    return gm.instance_find(gm.constants.oP, 0)
end



-- ========== Instance Methods ==========

methods_player = {



}



-- ========== Metatables ==========

metatable_player = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(t) end

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

    
    __metatable = "Player"
}



return Player