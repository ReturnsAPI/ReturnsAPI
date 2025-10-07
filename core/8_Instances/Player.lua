-- Player

--[[
Player wrappers are "children" of both @link {`Instance` | Instance} and @link {`Actor` | Actor}, and can use their properties and instance methods.
]]

Player = new_class()



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`/`id`    | number    | *Read-only.* The instance ID of the Player.
`RAPI`          | string    | *Read-only.* The wrapper name.
`cinstance`     | CInstance | *Read-only.* The `sol.CInstance*` of the Player.
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       Player or Instance
--[[
Returns the Player instance of this game client,
or an invalid Instance if they do not exist.
]]
Player.get_local = function()
    if Net.online then return Global.my_player end

    -- Return first oP to exist
    local inst = gm.instance_find(gm.constants.oP, 0)
    if inst ~= -4 then return Instance.wrap(inst.id) end
    return __invalid_instance
end



-- ========== Instance Methods ==========

--@section Instance Methods

methods_player = {

    

}



-- ========== Metatables ==========

local wrapper_name = "Player"

make_table_once("metatable_player", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" or k == "id" then return __proxy[proxy] end
        if k == "RAPI" then return wrapper_name end

        -- Check if this player is valid
        local id = __proxy[proxy]
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


    __eq = function(proxy, other)
        return metatable_instance.__eq(proxy, other)
    end,

    
    __metatable = "RAPI.Wrapper."..wrapper_name
})



-- Public export
__class.Player = Player