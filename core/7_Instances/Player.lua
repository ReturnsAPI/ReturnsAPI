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
    if Net.is_online() then return Global.my_player end

    -- Return first oP to exist
    local inst = gm.instance_find(gm.constants.oP, 0)
    if inst ~= -4 then return Instance.wrap(inst.id) end
    return __invalid_instance
end



-- ========== Instance Methods ==========

--@section Instance Methods

methods_player = {

    --@instance
    --@return       Equipment or nil
    --[[
    Returns the player's current equipment.
    Always `nil` for non-player actors.
    ]]
    equipment_get = function(self)
        local equip = gm.equipment_get(self.value)
        if equip >= 0 then return Equipment.wrap(equip) end
        return nil
    end,


    --@instance
    --@param        equip       | Equipment | The equipment to set. <br>If `-1`, removes equipment.
    --[[
    Sets the player's equipment.
    ]]
    equipment_set = function(self, equip)
        gm.equipment_set(self.value, Wrap.unwrap(equip))
    end

}



-- ========== Metatables ==========

local wrapper_name = "Player"

make_table_once("metatable_player", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" or k == "id" then return __proxy[proxy] end
        if k == "RAPI" then return wrapper_name end

        -- Check if this player is valid
        id = __proxy[proxy]
        if id == -4 then log.error("Actor does not exist", 2) end

        -- Methods
        if methods_player[k] then
            return methods_player[k]
        end

        -- Pass to metatable_actor
        return metatable_actor.__index(proxy, k, id)
    end,


    __newindex = function(proxy, k, v)
        -- Pass to metatable_instance
        metatable_instance.__newindex(proxy, k, v)
    end,

    
    __metatable = "RAPI.Wrapper."..wrapper_name
})



-- Public export
__class.Player = Player