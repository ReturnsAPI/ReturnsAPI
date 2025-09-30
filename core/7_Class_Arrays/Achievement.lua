-- Achievement

local name_rapi = class_name_g2r["class_achievement"]
Achievement = __class[name_rapi]



-- ========== Enums ==========

--@section Enums

--@enum
--@name Property
--[[
NAMESPACE               0
IDENTIFIER              1
TOKEN_NAME              2
TOKEN_DESC              3
TOKEN_DESC2             4
TOKEN_UNLOCK_NAME       5
UNLOCK_KIND             6
UNLOCK_ID               7
SPRITE_ID               8
SPRITE_SUBIMAGE         9
SPRITE_SCALE            10
SPRITE_SCALE_INGAME     11
IS_HIDDEN               12
IS_TRIAL                13
IS_SERVER_AUTHORATIVE   14
MILESTONE_ALT_UNLOCK    15
MILESTONE_SURVIVOR      16
PROGRESS                17
UNLOCKED                18
PARENT_ID               19
PROGRESS_NEEDED         20
DEATH_RESET             21
GROUP                   22
ON_COMPLETED            23
]]



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The achievement ID being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.

<br>

Property | Type | Description
| - | - | -
`namespace`             | string    | The namespace the achievement is in.
`identifier`            | string    | The identifier for the achievement within the namespace.
`token_name`            | string    | 
`token_desc`            | string    | 
`token_desc2`           | string    | 
`token_unlock_name`     | string    | 
`unlock_kind`           |           | 
`unlock_id`             | number    | 
`sprite_id`             | number    | 
`sprite_subimage`       | number    | 
`sprite_scale`          | number    | 
`sprite_scale_ingame`   | number    | 
`is_hidden`             | bool      | 
`is_trial`              | bool      | 
`is_server_authorative` | bool      | 
`milestone_alt_unlock`  |           | 
`milestone_survivor`    |           | 
`progress`              | number    | 
`unlocked`              |           | 
`parent_id`             | number    | 
`progress_needed`       |           | 
`death_reset`           |           | 
`group`                 | number    | 
`on_completed`          |           | 
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@name         find
--@return       Achievement or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified achievement and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]


--@static
--@name         find_all
--@return       table
--@param        filter      |           | The filter to search by.
--@optional     property    | number    | The property to check. <br>@link {`Achievement.Property.NAMESPACE` | Achievement#Property} by default.
--[[
Returns a table of achievements matching the specified filter and property.

**NOTE:** Filtering by a non-namespace property is *very slow*!
Try not to do that too much.
]]


--@static
--@name         wrap
--@return       Achievement
--@param        id          | number    | The achievement ID to wrap.
--[[
Returns an Achievement wrapper containing the provided achievement ID.
]]



-- ========== Instance Methods ==========

--@section Instance Methods

Util.table_append(methods_class_array[name_rapi], {

    --@instance
    --@name         print_properties
    --[[
    Prints the achievement's properties.
    ]]

})
