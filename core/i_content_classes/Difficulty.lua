-- Difficulty

---@class DifficultyClass
Difficulty = C["Difficulty"]

local proxy              = P.proxy
local metatable          = W["Difficulty"]
local find_table_wrapper = P.class_find_tables_wrapper["Difficulty"]
local find_table_array   = P.class_find_tables_array["Difficulty"]

local gm_get_diff        = gm._mod_game_getDifficulty  ---@type function
local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class Difficulty
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field properties Array The array storing this difficulty's properties.
---@field array Array Alias for `.properties`.

---@class Difficulty
---@field namespace            string  The namespace the difficulty is in.
---@field identifier           string  The identifier for the difficulty within the namespace.
---@field token_name           string  The localization token for the difficulty's name.
---@field token_description    string  The localization token for the difficulty's description.
---@field sprite_id            number  The sprite ID for the small difficulty icon while in a run.
---@field sprite_loadout_id    number  The sprite ID for the difficulty icon in the character select screen.
---@field primary_color        number  The text color for the difficulty.
---@field sound_id             number  The sound ID for when the difficulty is selected.
---@field diff_scale           number  Affects enemy stat scaling. <br>Drizzle - `0.06` <br>Rainstorm - `0.12` <br>Monsoon - `0.16`
---@field general_scale        number  Affects multiple values (timer, costs, stats, etc.) <br>Drizzle - `1` <br>Rainstorm - `2` <br>Monsoon - `3`
---@field point_scale          number  Affects director credit scaling. <br>Drizzle - `1` <br>Rainstorm - `1` <br>Monsoon - `1.7`
---@field is_monsoon_or_higher boolean If `true`, the difficulty will be classified as being at least as hard as Monsoon.
---@field allow_blight_spawns  boolean If `true`, blighted elites are allowed to spawn.


-- ========== Enums ==========

Difficulty.Property = {
    NAMESPACE            = 0,
    IDENTIFIER           = 1,
    TOKEN_NAME           = 2,
    TOKEN_DESCRIPTION    = 3,
    SPRITE_ID            = 4,
    SPRITE_LOADOUT_ID    = 5,
    PRIMARY_COLOR        = 6,
    SOUND_ID             = 7,
    DIFF_SCALE           = 8,
    GENERAL_SCALE        = 9,
    POINT_SCALE          = 10,
    IS_MONSOON_OR_HIGHER = 11,
    ALLOW_BLIGHT_SPAWNS  = 12,
}
local t = {}
for name, num in pairs(Difficulty.Property) do t[num] = name end
for i = 0, #t do Difficulty.Property[i] = t[i] end


-- ========== Static Methods ==========

--[[
Creates a new difficulty with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the difficulty.
---@return Difficulty
Difficulty.new = function(NAMESPACE, identifier)
    check_init_started("new")
    if not identifier then throw("No identifier provided", "new") end

    -- Return existing difficulty if found
    local difficulty = Difficulty.find(identifier, NAMESPACE, true)
    if difficulty then return difficulty end

    -- Create new
    difficulty = Difficulty.wrap(gm.difficulty_create(
        NAMESPACE,
        identifier
    ))

    return difficulty
end

--[[
Searches for the specified difficulty and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return Difficulty
Difficulty.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all difficulty in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>`Difficulty.Property.NAMESPACE` by default.
---@return table<number, Difficulty>
Difficulty.find_all = function(NAMESPACE, filter, property) end

--[[
Returns a difficulty wrapper containing the provided difficulty ID.
]]
---@param id number | Difficulty The difficulty to wrap.
---@return Difficulty
Difficulty.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class Difficulty
local methods = G.methods_content["Difficulty"]

--[[
Returns `true` if the difficulty is currently active. <br>
Can only be `true` while in a run.
]]
---@return boolean
methods.is_active = function(self)
    return gm_get_diff() == proxy[self]
end

--[[
Prints the difficulty's properties.
]]
methods.print = function(self) end