-- Player

---@class PlayerClass
Player = new_class()
C.Player = Player

local inst_find = gm.instance_find  ---@type function

local vanilla_player_verbs  ---@type table
run_after_core(function()
    vanilla_player_verbs = G.vanilla_player_verbs
end)


-- ========== Static Methods ==========

--[[
Returns the Player instance of this game client, <br>
or `nil` if they do not exist.

On the character select screen in online multiplayer, <br>
this will return the local `oPrePlayer`.
]]
---@return Player | Instance | nil
Player.get_local = function()
    if Net.online then return Global.my_player end

    -- Return first oP to exist
    local inst = inst_find(gm.constants.oP, 0)
    if inst ~= -4 then return inst end
    return nil
end


-- ========== Wrapper Methods ==========

---@class Player: Actor
local methods = {}
G.methods_player = methods

--[[
Returns the input status for a @link {verb | ModOptionsKeybind}. <br>
Only returns `true` for the local player, and if the game is not paused.

For more general uses, use @link {`gm.input_check_*` | ModOptionsKeybind} functions instead.
]]
---@param verb string The verb to check.
---@param check_type? number `0` - Returns `true` if the verb input is being held. <br>`1` - Returns `true` if the verb input was just pressed. <br>`-1` - Returns `true` if the verb input was just released. <br>`0` by default.
---@return boolean
methods.control = function(self, verb, check_type)
    if (not vanilla_player_verbs[verb]) and (not P.custom_verbs_all[verb]) then throw("verb '"..tostring(verb).."' is invalid") end
    return GM.SO.control(self, nil, verb, check_type or 0)
end