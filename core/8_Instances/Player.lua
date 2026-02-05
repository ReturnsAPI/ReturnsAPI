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
`value`/`cinstance` | CInstance     | *Read-only.* The `sol.CInstance*` of the Actor.
`RAPI`              | string        | *Read-only.* The wrapper name.
`id`                | number        | *Read-only.* The instance ID of the Actor.
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       Player or Instance
--[[
Returns the Player instance of this game client,
or an invalid Instance if they do not exist.

On the character select screen in online multiplayer,
this will return the local `oPrePlayer`.
]]
Player.get_local = function()
    if Net.online then return Global.my_player end

    -- Return first oP to exist
    local inst = gm.instance_find(gm.constants.oP, 0)
    if inst ~= -4 then return Instance.wrap(inst) end
    return Instance.INVALID
end



-- ========== Instance Methods ==========

--@section Instance Methods

methods_player = {

    --@instance
    --@return       bool
    --@param        verb        | string    | The verb to check.
    --@optional     type        | number    | <br>`0` - Returns `true` if the verb input is being held. <br>`1` - Returns `true` if the verb input was just pressed. <br>`-1` - Returns `true` if the verb input was just released. <br><br>`0` by default.
    --[[
    Returns the input status for a verb.
    Only returns `true` for the local player, and if the game is not paused.

    For more general uses, use @link {`gm.input_check_*` | ModOptionsKeybind} functions instead.
    ]]
    control = function(self, verb, _type)
        if (not vanilla_player_verbs[verb]) and (not __custom_verbs[verb]) then log.error("control: verb is invalid", 2) end
        return GM.SO.control(self, nil, verb, _type or 0)
    end,

}



-- ========== Metatables ==========

local wrapper_name = "Player"

make_table_once("metatable_player", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" or k == "cinstance" then return __proxy[proxy] end
        if k == "RAPI" then return wrapper_name end
        if k == "id" then return metatable_instance.__index(proxy, k) end

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


    __eq = function(proxy, other)
        return metatable_instance.__eq(proxy, other)
    end,

    
    __metatable = "RAPI.Wrapper."..wrapper_name
})



-- Public export
__class.Player = Player