-- Player

-- "Child" class of Instance and Actor

Player = new_class()



-- ========== Static Methods ==========

--$static
--$return       Player or Instance
--[[
Returns the Player instance of this game client,
or an invalid Instance if they do not exist.
]]
Player.get_local = function()
    if Net.is_online() then return Global.my_player end

    -- Return first oP to exist
    -- (which I think is always the local player)
    local holder = RValue.new_holder(2)
    holder[0] = RValue.new(gm.constants.oP)
    holder[1] = RValue.new(0)
    local out = RValue.new(0)
    gmf.instance_find(out, nil, nil, 2, holder)
    local inst = RValue.to_wrapper(out)
    
    if inst ~= -4 then return inst end
    return __invalid_instance
end



-- ========== Instance Methods ==========

make_table_once("methods_player", {



})



-- ========== Metatables ==========

make_table_once("metatable_player", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" or k == "id" then return Proxy.get(proxy) end
        if k == "RAPI" then return getmetatable(proxy):sub(14, -1) end

        -- Methods
        if methods_player[k] then
            return methods_player[k]
        end

        -- Pass to metatable_actor
        return metatable_actor.__index(proxy, k)
    end,


    __newindex = function(proxy, k, v)
        -- Pass to metatable_instance
        metatable_instance.__newindex(proxy, k, v)
    end,

    
    __metatable = "RAPI.Wrapper.Player"
})



-- Public export
__class.Player = Player