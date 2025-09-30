-- Elite

local name_rapi = class_name_g2r["class_elite"]
Elite = __class[name_rapi]



-- ========== Enums ==========

--@section Enums

--@enum
--@name Property
--[[
NAMESPACE           0
IDENTIFIER          1
TOKEN_NAME          2
PALETTE             3
BLEND_COL           4
HEALTHBAR_ICON      5
EFFECT_DISPLAY      6
ON_APPLY            7
]]



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The elite ID being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.

<br>

Property | Type | Description
| - | - | -
`namespace`         | string    | The namespace the elite is in.
`identifier`        | string    | The identifier for the elite within the namespace.
`token_name`        | string    | 
`palette`           |           | 
`blend_col`         | color     | 
`healthbar_icon`    |           | 
`effect_display`    | EffectDisplay | 
`on_apply`          | number    | 
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@name         find
--@return       Elite or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified elite and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]


--@static
--@name         find_all
--@return       table
--@param        filter      |           | The filter to search by.
--@optional     property    | number    | The property to check. <br>@link {`Elite.Property.NAMESPACE` | Elite#Property} by default.
--[[
Returns a table of elites matching the specified filter and property.

**NOTE:** Filtering by a non-namespace property is *very slow*!
Try not to do that too much.
]]


--@static
--@name         wrap
--@return       Elite
--@param        id          | number    | The elite ID to wrap.
--[[
Returns an Elite wrapper containing the provided elite ID.
]]



-- ========== Instance Methods ==========

--@section Instance Methods

Util.table_append(methods_class_array[name_rapi], {

    --@instance
    --@name         print_properties
    --[[
    Prints the elite's properties.
    ]]

})
