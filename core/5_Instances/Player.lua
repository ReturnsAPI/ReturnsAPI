-- Player

Player = new_class()



-- ========== Static Methods ==========

Player.get_local = function()
    if Net.online() then return Global.my_player end
    return Instance.find(gm.constants.oP)
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