-- Difficulty

local name_rapi = class_name_g2r["class_difficulty"]
Difficulty = __class[name_rapi]



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
`token_name`            | string    | 
`token_description`     | string    | 
`sprite_id`             | sprite    | 
`sprite_loadout_id`     | sprite    | 
`primary_color`         | color     | 
`sound_id`              | sound     | 
`diff_scale`            | number    | 
`general_scale`         | number    | 
`point_scale`           | number    | 
`is_monsoon_or_higher`  | bool      | 
`allow_blight_spawns`   | bool      | 
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@name         find
--@return       Difficulty or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified difficulty and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]


--@static
--@name         find_all
--@return       table
--@param        filter      |           | The filter to search by.
--@optional     property    | number    | The property to check. <br>@link {`Difficulty.Property.NAMESPACE` | Difficulty#Property} by default.
--[[
Returns a table of difficultys matching the specified filter and property.

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

Util.table_append(methods_class_array[name_rapi], {

    --@instance
    --@name         print_properties
    --[[
    Prints the difficulty's properties.
    ]]

})
