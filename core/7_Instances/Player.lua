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

--@section Instance Methods

methods_player = {

    --@instance
    --@return       Equipment or nil
    --[[
    Returns the player's current equipment.
    Always `nil` for non-player actors.
    ]]
    equipment_get = function(self)
        local holder = RValue.new_holder_scr(1)
        holder[0] = RValue.new(self.value, RValue.Type.REF)
        local out = RValue.new(0)
        gmf.equipment_get(nil, nil, out, 1, holder)
        local equip = out.value

        if equip >= 0 then return Equipment.wrap(equip) end
        return nil
    end,


    --@instance
    --@param        equip       | Equipment | The equipment to set. <br>If `-1`, removes equipment.
    --[[
    Sets the player's equipment.
    ]]
    equipment_set = function(self, equip)
        local holder = RValue.new_holder_scr(2)
        holder[0] = RValue.new(self.value, RValue.Type.REF)
        holder[1] = RValue.new(Wrap.unwrap(equip))
        gmf.equipment_set(nil, nil, RValue.new(0), 2, holder)
    end

}



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