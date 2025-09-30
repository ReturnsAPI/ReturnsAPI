-- Artifact

local name_rapi = class_name_g2r["class_artifact"]
Artifact = __class[name_rapi]



-- ========== Enums ==========

--@section Enums

--@enum
--@name Property
--[[
NAMESPACE           0
IDENTIFIER          1
TOKEN_NAME          2
TOKEN_PICKUP_NAME   3
TOKEN_DESCRIPTION   4
LOADOUT_SPRITE_ID   5
PICKUP_SPRITE_ID    6
ON_SET_ACTIVE       7
ACTIVE              8
ACHIEVEMENT_ID      9
]]



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The artifact ID being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.

<br>

Property | Type | Description
| - | - | -
`namespace`         | string    | The namespace the artifact is in.
`identifier`        | string    | The identifier for the artifact within the namespace.
`token_name`        | string    | 
`token_pickup_name` | string    | 
`token_description` | string    | 
`loadout_sprite_id` | sprite    | 
`pickup_sprite_id`  | sprite    | 
`on_set_active`     | number    | 
`active`            |           | 
`achievement_id`    | number    | 
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@name         find
--@return       Artifact or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified artifact and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]


--@static
--@name         find_all
--@return       table
--@param        filter      |           | The filter to search by.
--@optional     property    | number    | The property to check. <br>@link {`Artifact.Property.NAMESPACE` | Artifact#Property} by default.
--[[
Returns a table of artifacts matching the specified filter and property.

**NOTE:** Filtering by a non-namespace property is *very slow*!
Try not to do that too much.
]]


--@static
--@name         wrap
--@return       Artifact
--@param        id          | number    | The artifact ID to wrap.
--[[
Returns an Artifact wrapper containing the provided artifact ID.
]]



-- ========== Instance Methods ==========

--@section Instance Methods

Util.table_append(methods_class_array[name_rapi], {

    --@instance
    --@name         print_properties
    --[[
    Prints the artifact's properties.
    ]]

})
