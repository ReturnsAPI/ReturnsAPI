-- MonsterLog

local name_rapi = class_name_g2r["class_monster_log"]
MonsterLog = __class[name_rapi]



-- ========== Enums ==========

--@section Enums

--@enum
--@name Property
--[[
NAMESPACE                       0
IDENTIFIER                      1
TOKEN_NAME                      2
TOKEN_STORY                     3
SPRITE_ID                       4
PORTRAIT_ID                     5
PORTRAIT_INDEX                  6
SPRITE_OFFSET_X                 7
SPRITE_OFFSET_Y                 8
SPRITE_FORCE_HORIZONTAL_ALIGN   9
SPRITE_HEIGHT_OFFSET            10
STAT_HP                         11
STAT_DAMAGE                     12
STAT_SPEED                      13
LOG_BACKDROP_INDEX              14
OBJECT_ID                       15
ENEMY_OBJECT_IDS_KILLS          16
ENEMY_OBJECT_IDS_DEATHS         17
]]



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The monster log ID being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.

<br>

Property | Type | Description
| - | - | -
`namespace`                     | string    | The namespace the monster log is in.
`identifier`                    | string    | The identifier for the monster log within the namespace.
`token_name`                    | string    | 
`token_story`                   | string    | 
`sprite_id`                     | sprite    | 
`portrait_id`                   |           | 
`portrait_index`                |           | 
`sprite_offset_x`               | number    | 
`sprite_offset_y`               | number    | 
`sprite_force_horizontal_align` | bool      | 
`sprite_height_offset`          | number    | 
`stat_hp`                       | number    | 
`stat_damage`                   | number    | 
`stat_speed`                    | number    | 
`log_backdrop_index`            |           | 
`object_id`                     | number    | 
`enemy_object_ids_kills`        |           | 
`enemy_object_ids_deaths`       |           | 
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@name         find
--@return       MonsterLog or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified monster log and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]


--@static
--@name         find_all
--@return       table
--@param        filter      |           | The filter to search by.
--@optional     property    | number    | The property to check. <br>@link {`MonsterLog.Property.NAMESPACE` | MonsterLog#Property} by default.
--[[
Returns a table of monster logs matching the specified filter and property.

**NOTE:** Filtering by a non-namespace property is *very slow*!
Try not to do that too much.
]]


--@static
--@name         wrap
--@return       MonsterLog
--@param        id          | number    | The monster log ID to wrap.
--[[
Returns an MonsterLog wrapper containing the provided monster log ID.
]]



-- ========== Instance Methods ==========

--@section Instance Methods

Util.table_append(methods_class_array[name_rapi], {

    --@instance
    --@name         print_properties
    --[[
    Prints the monster log's properties.
    ]]

})
