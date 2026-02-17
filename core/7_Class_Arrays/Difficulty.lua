-- Difficulty



-- ========== Enums ==========

--@section Enums

--@enum
--@name Property
--[[
NAMESPACE               0
IDENTIFIER              1
TOKEN_NAME              2
TOKEN_DESCRIPTION       3
SPRITE_ID               4
SPRITE_LOADOUT_ID       5
PRIMARY_COLOR           6
SOUND_ID                7
DIFF_SCALE              8
GENERAL_SCALE           9
POINT_SCALE             10
IS_MONSOON_OR_HIGHER    11
ALLOW_BLIGHT_SPAWNS     12
]]



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The difficulty ID being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.

<br>

Property | Type | Description
| - | - | -
`namespace`             | string    | The namespace the difficulty is in.
`identifier`            | string    | The identifier for the difficulty within the namespace.
`token_name`            | string    | The localization token for the difficulty's name.
`token_description`     | string    | The localization token for the difficulty's description.
`sprite_id`             | sprite    | The sprite ID for the small difficulty icon while in a run.
`sprite_loadout_id`     | sprite    | The sprite ID for the difficulty icon in the character select screen.
`primary_color`         | color     | The text color for the difficulty.
`sound_id`              | sound     | The sound ID for when the difficulty is selected.
`diff_scale`            | number    | Affects enemy stat scaling. <br>Drizzle - `0.06` <br>Rainstorm - `0.12` <br>Monsoon - `0.16`
`general_scale`         | number    | Affects multiple values (timer, costs, stats, etc.) <br>Drizzle - `1` <br>Rainstorm - `2` <br>Monsoon - `3`
`point_scale`           | number    | Affects director credit scaling. <br>Drizzle - `1` <br>Rainstorm - `1` <br>Monsoon - `1.7`
`is_monsoon_or_higher`  | bool      | If `true`, the difficulty will be classified as being at least as hard as Monsoon.
`allow_blight_spawns`   | bool      | If `true`, blighted elites are allowed to spawn.
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return   Difficulty
--@param    identifier  | string    | The identifier for the difficulty.
--[[
Creates a new difficulty with the given identifier if it does not already exist,
or returns the existing one if it does.
]]
Difficulty.new = function(NAMESPACE, identifier)
    Initialize.internal.check_if_started("Difficulty.new")
    if not identifier then log.error("Difficulty.new: No identifier provided", 2) end

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


--@static
--@name         find
--@return       Difficulty or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified difficulty and returns it.

--@findinfo
]]


--@static
--@name         find_all
--@return       table
--@param        filter      |           | The filter to search by.
--@optional     property    | number    | The property to check. <br>@link {`Difficulty.Property.NAMESPACE` | Difficulty#Property} by default.
--[[
Returns a table of difficultys matching the specified filter and property.

**Note on namespace filter:**
--@findinfo

**NOTE:** Filtering by a non-namespace property is *very slow*!
Try not to do that too much.
]]


--@static
--@name         wrap
--@return       Difficulty
--@param        id          | number    | The difficulty ID to wrap.
--[[
Returns an Difficulty wrapper containing the provided difficulty ID.
]]



-- ========== Instance Methods ==========

--@section Instance Methods

Util.table_append(methods_content_class["Difficulty"], {

    --@instance
    --@name         print
    --[[
    Prints the difficulty's properties.
    ]]


    --@instance
    --@return       bool
    --[[
    Returns `true` if the difficulty is currently active.
    Can only be `true` while in a run.
    ]]
    is_active = function(self)
        return gm._mod_game_getDifficulty() == self.value
    end

})
