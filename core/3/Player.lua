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





-- ========== Metatables ==========





return Player