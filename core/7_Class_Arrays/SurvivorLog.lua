-- SurvivorLog

local name_rapi = class_name_g2r["class_survivor_log"]
SurvivorLog = __class[name_rapi]



-- ========== Enums ==========

--@section Enums

--@enum
--@name Property
--[[
NAMESPACE           0
IDENTIFIER          1
TOKEN_NAME          2
TOKEN_STORY         3
TOKEN_ID            4
TOKEN_DEPARTED      5
TOKEN_ARRIVAL       6
SPRITE_ICON_ID      7
SPRITE_ID           8
PORTRAIT_ID         9
PORTRAIT_INDEX      10
STAT_HP_BASE        11
STAT_HP_LEVEL       12
STAT_DAMAGE_BASE    13
STAT_DAMAGE_LEVEL   14
STAT_REGEN_BASE     15
STAT_REGEN_LEVEL    16
STAT_ARMOR_BASE     17
STAT_ARMOR_LEVEL    18
SURVIVOR_ID         19
]]



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The survivor log ID being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.

<br>

Property | Type | Description
| - | - | -
`namespace`                     | string    | The namespace the survivor log is in.
`identifier`                    | string    | The identifier for the survivor log within the namespace.
`token_name`                    | string    | 
`token_story`                   | string    | 
`token_id`                      | string    | 
`token_departed`                | string    | 
`token_arrival`                 | string    | 
`sprite_icon_id`                | sprite    | 
`sprite_id`                     | sprite    | 
`portrait_id`                   |           | 
`portrait_index`                |           | 
`stat_hp_base`                  | number    | 
`stat_hp_level`                 | number    | 
`stat_damage_base`              | number    | 
`stat_damage_level`             | number    | 
`stat_regen_base`               | number    | 
`stat_regen_level`              | number    | 
`stat_armor_base`               | number    | 
`stat_armor_level`              | number    | 
`survivor_id`                   | number    | 
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@name         find
--@return       SurvivorLog or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified survivor log and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]


--@static
--@name         find_all
--@return       table
--@param        filter      |           | The filter to search by.
--@optional     property    | number    | The property to check. <br>@link {`SurvivorLog.Property.NAMESPACE` | SurvivorLog#Property} by default.
--[[
Returns a table of monster logs matching the specified filter and property.

**NOTE:** Filtering by a non-namespace property is *very slow*!
Try not to do that too much.
]]


--@static
--@name         wrap
--@return       SurvivorLog
--@param        id          | number    | The survivor log ID to wrap.
--[[
Returns an SurvivorLog wrapper containing the provided survivor log ID.
]]



-- ========== Instance Methods ==========

--@section Instance Methods

Util.table_append(methods_class_array[name_rapi], {

    --@instance
    --@name         print_properties
    --[[
    Prints the survivor log's properties.
    ]]

})
