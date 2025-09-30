-- GameMode

local name_rapi = class_name_g2r["class_game_mode"]
GameMode = __class[name_rapi]



-- ========== Enums ==========

--@section Enums

--@enum
--@name Property
--[[
NAMESPACE                       0
IDENTIFIER                      1
COUNT_NORMAL_UNLOCKS            2
COUNT_TOWARDS_GAMES_PLAYED      3
]]



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The game mode ID being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.

<br>

Property | Type | Description
| - | - | -
`namespace`                     | string    | The namespace the game mode is in.
`identifier`                    | string    | The identifier for the game mode within the namespace.
`count_normal_unlocks`          |           | 
`count_towards_games_played`    |           | 
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@name         find
--@return       GameMode or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified game mode and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]


--@static
--@name         find_all
--@return       table
--@param        filter      |           | The filter to search by.
--@optional     property    | number    | The property to check. <br>@link {`GameMode.Property.NAMESPACE` | GameMode#Property} by default.
--[[
Returns a table of game modes matching the specified filter and property.

**NOTE:** Filtering by a non-namespace property is *very slow*!
Try not to do that too much.
]]


--@static
--@name         wrap
--@return       GameMode
--@param        id          | number    | The game mode ID to wrap.
--[[
Returns an GameMode wrapper containing the provided game mode ID.
]]



-- ========== Instance Methods ==========

--@section Instance Methods

Util.table_append(methods_class_array[name_rapi], {

    --@instance
    --@name         print_properties
    --[[
    Prints the game mode's properties.
    ]]

})
