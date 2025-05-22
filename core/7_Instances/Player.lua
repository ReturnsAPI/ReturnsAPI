-- Player

--[[
Player wrappers are "children" of both @link {`Instance` | Instance} and @link {`Actor` | Actor}, and can use their properties and instance methods.
]]

Player = new_class()



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       Player or Instance
--[[
Returns the Player instance of this game client,
or an invalid Instance if they do not exist.
]]
Player.get_local = function()
    -- TODO
    -- if Net.is_online() then return Global.my_player end

    -- Return first oP to exist
    -- (which I think is always the local player)
    local inst = gm.instance_find(gm.constants.oP, 0)
    if inst ~= -4 then return Instance.wrap(inst.id) end
    return __invalid_instance
end



-- Public export
__class.Player = Player