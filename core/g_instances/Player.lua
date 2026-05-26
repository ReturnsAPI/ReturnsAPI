-- Player

---@class PlayerClass
Player = new_class()
C.Player = Player


-- ========== Static Methods ==========

--[[
Returns the Player instance of this game client, <br>
or `nil` if they do not exist.

On the character select screen in online multiplayer, <br>
this will return the local `oPrePlayer`.
]]
---@return Player | Instance | nil
Player.get_local = function()
    -- TODO
    -- if Net.online then return Global.my_player end

    -- Return first oP to exist
    local inst = gm.instance_find(gm.constants.oP, 0)
    if inst ~= -4 then return inst end
    return nil
end


-- ========== Wrapper Methods ==========

---@class Player: Actor
local methods = {}
G.methods_player = methods

--@instance
--@return       bool
--@param        verb        | string    | The verb to check.
--@optional     type        | number    | <br>`0` - Returns `true` if the verb input is being held. <br>`1` - Returns `true` if the verb input was just pressed. <br>`-1` - Returns `true` if the verb input was just released. <br><br>`0` by default.
--[[
Returns the input status for a @link {verb | ModOptionsKeybind}.
Only returns `true` for the local player, and if the game is not paused.

For more general uses, use @link {`gm.input_check_*` | ModOptionsKeybind} functions instead.
]]
---@param verb string The verb to check.
---@param type? number `0` - Returns `true` if the verb input is being held. <br>`1` - Returns `true` if the verb input was just pressed. <br>`-1` - Returns `true` if the verb input was just released. <br>`0` by default.
---@return boolean
methods.control = function(self, verb, _type)
    -- TODO
    print("control called")
    -- if (not _vanilla_player_verbs[verb]) and (not __custom_verbs_all[verb]) then log.error("control: verb is invalid", 2) end
    -- return GM.SO.control(self, nil, verb, _type or 0)
end