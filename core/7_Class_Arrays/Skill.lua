-- Skill

local name_rapi = class_name_g2r["class_skill"]
Skill = __class[name_rapi]



-- ========== Enums ==========

--@section Enums

--@enum
--@name Property
--[[
NAMESPACE                       0
IDENTIFIER                      1
TOKEN_NAME                      2
TOKEN_DESCRIPTION               3
SPRITE                          4
SUBIMAGE                        5
COOLDOWN                        6
DAMAGE                          7
MAX_STOCK                       8
START_WITH_STOCK                9
AUTO_RESTOCK                    10
REQUIRED_STOCK                  11
REQUIRE_KEY_PRESS               12
ALLOW_BUFFERED_INPUT            13
USE_DELAY                       14
ANIMATION                       15
IS_UTILITY                      16
IS_PRIMARY                      17
REQUIRED_INTERRUPT_PRIORITY     18
HOLD_FACING_DIRECTION           19
OVERRIDE_STRAFE_DIRECTION       20
IGNORE_AIM_DIRECTION            21
DISABLE_AIM_STALL               22
DOES_CHANGE_ACTIVITY_STATE      23
ON_CAN_ACTIVATE                 24
ON_ACTIVATE                     25
ON_STEP                         26
ON_EQUIPPED                     27
ON_UNEQUIPPED                   28
UPGRADE_SKILL                   29
]]



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The skill ID being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.

<br>

Property | Type | Description
| - | - | -
`namespace`                     | string    | The namespace the skill is in.
`identifier`                    | string    | The identifier for the skill within the namespace.
`token_name`                    | string    | 
`token_description`             | string    | 
`sprite`                        | sprite    |
`subimage`                      | number    | 
`cooldown`                      | number    | 
`damage`                        | number    | 
`max_stock`                     | number    | 
`start_with_stock`              | bool      | 
`auto_restock`                  |           | 
`required_stock`                |           | 
`require_key_press`             | bool      | 
`allow_buffered_input`          |           | 
`use_delay`                     |           | 
`animation`                     |           | 
`is_utility`                    | bool      | 
`is_primary`                    | bool      | 
`required_interrupt_priority`   |           | 
`hold_facing_direction`         |           | 
`override_strafe_direction`     |           | 
`ignore_aim_direction`          | bool      | 
`disable_aim_stall`             | bool      | 
`does_change_activity_state`    |           | 
`on_can_activate`               | number    | 
`on_activate`                   | number    | 
`on_step`                       | number    | 
`on_equipped`                   | number    | 
`on_unequipped`                 | number    | 
`upgrade_skill`                 |           | 
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@name         find
--@return       Skill or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified skill and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]


--@static
--@name         find_all
--@return       table
--@param        filter      |           | The filter to search by.
--@optional     property    | number    | The property to check. <br>@link {`Skill.Property.NAMESPACE` | Skill#Property} by default.
--[[
Returns a table of skills matching the specified filter and property.

**NOTE:** Filtering by a non-namespace property is *very slow*!
Try not to do that too much.
]]


--@static
--@name         wrap
--@return       Skill
--@param        id          | number    | The skill ID to wrap.
--[[
Returns an Skill wrapper containing the provided skill ID.
]]



-- ========== Instance Methods ==========

--@section Instance Methods

Util.table_append(methods_class_array[name_rapi], {

    --@instance
    --@name         print_properties
    --[[
    Prints the skill's properties.
    ]]

})
