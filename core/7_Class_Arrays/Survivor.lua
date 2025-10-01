-- Survivor

local name_rapi = class_name_g2r["class_survivor"]
Survivor = __class[name_rapi]

run_once(function()
    __survivor_data = {}    -- Stores some data for survivors (e.g., `on_init` callback for setting base stats)
end)



-- ========== Enums ==========

--@section Enums

--@enum
--@name Property
--[[
NAMESPACE               0
IDENTIFIER              1
TOKEN_NAME              2
TOKEN_NAME_UPPER        3
TOKEN_DESCRIPTION       4
TOKEN_END_QUOTE         5
SKILL_FAMILY_Z          6
SKILL_FAMILY_X          7
SKILL_FAMILY_C          8
SKILL_FAMILY_V          9
SKIN_FAMILY             10
ALL_LOADOUT_FAMILIES    11
ALL_SKILL_FAMILIES      12
SPRITE_LOADOUT          13
SPRITE_TITLE            14
SPRITE_IDLE             15
SPRITE_PORTRAIT         16
SPRITE_PORTRAIT_SMALL   17
SPRITE_PALETTE          18
SPRITE_PORTRAIT_PALETTE 19
SPRITE_LOADOUT_PALETTE  20
SPRITE_CREDITS          21
PRIMARY_COLOR           22
SELECT_SOUND_ID         23
LOG_ID                  24
ACHIEVEMENT_ID          25
MILESTONE_KILLS_1       26
MILESTONE_ITEMS_1       27
MILESTONE_STAGES_1      28
ON_INIT                 29
ON_STEP                 30
ON_REMOVE               31
IS_SECRET               32
CAPE_OFFSET             33
]]



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The survivor ID being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.

<br>

Property | Type | Description
| - | - | -
`namespace`                 | string    | The namespace the survivor is in.
`identifier`                | string    | The identifier for the survivor within the namespace.
`token_name`                | string    | 
`token_name_upper`          | string    | 
`token_description`         | string    | 
`token_end_quote`           | string    | 
`skill_family_z`            |           | 
`skill_family_x`            |           | 
`skill_family_c`            |           | 
`skill_family_v`            |           | 
`skin_family`               |           | 
`all_loadout_families`      |           | 
`all_skill_families`        |           | 
`sprite_loadout`            | sprite    | 
`sprite_title`              | sprite    | 
`sprite_idle`               | sprite    | 
`sprite_portrait`           | sprite    | 
`sprite_portrait_small`     | sprite    | 
`sprite_palette`            |           | 
`sprite_portrait_palette`   |           | 
`sprite_loadout_palette`    |           | 
`sprite_credits`            | sprite    | 
`primary_color`             | color     | 
`select_sound_id`           | sound     | 
`log_id`                    | number    | 
`achievement_id`            | number    | 
`milestone_kills_1`         |           | 
`milestone_items_1`         |           | 
`milestone_stages_1`        |           | 
`on_init`                   | number    | The ID of the callback that runs when an instance of the survivor is created. <br>The callback function should have the argument `actor`.
`on_step`                   | number    | The ID of the callback that runs when . <br>The callback function should have the arguments ``.
`on_remove`                 | number    | The ID of the callback that runs when . <br>The callback function should have the arguments ``.
`is_secret`                 | bool      | 
`cape_offset`               | Array     | Stores the drawing offset for Prophet's Cape. <br>Array order: `x_offset, y_offset, x_offset_climbing, y_offset_climbing`
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@namefind
--@return       Survivor or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified survivor and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]


--@static
--@namefind_all
--@return       table
--@param        filter      |  | The filter to search by.
--@optional     property    | number    | The property to check. <br>@link {`Survivor.Property.NAMESPACE` | Survivor#Property} by default.
--[[
Returns a table of survivors matching the specified filter and property.

**NOTE:** Filtering by a non-namespace property is *very slow*!
Try not to do that too much.
]]


--@static
--@namewrap
--@return       Survivor
--@param        id | number    | The survivor ID to wrap.
--[[
Returns an Survivor wrapper containing the provided survivor ID.
]]



-- ========== Instance Methods ==========

--@section Instance Methods

Util.table_append(methods_class_array[name_rapi], {

    --@instance
    --@nameprint_properties
    --[[
    Prints the survivor's properties.
    ]]

})
