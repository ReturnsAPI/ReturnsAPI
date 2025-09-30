-- EndingType

local name_rapi = class_name_g2r["class_ending_type"]
EndingType = __class[name_rapi]



-- ========== Enums ==========

--@section Enums

--@enum
--@name Property
--[[
NAMESPACE           0
IDENTIFIER          1
PRIMARY_COLOR       2
IS_VICTORY          3
]]



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The ending type ID being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.

<br>

Property | Type | Description
| - | - | -
`namespace`         | string    | The namespace the ending type is in.
`identifier`        | string    | The identifier for the ending type within the namespace.
`primary_color`     | color     | 
`is_victory`        | bool      | 
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@name         find
--@return       EndingType or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified ending type and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]


--@static
--@name         find_all
--@return       table
--@param        filter      |           | The filter to search by.
--@optional     property    | number    | The property to check. <br>@link {`EndingType.Property.NAMESPACE` | EndingType#Property} by default.
--[[
Returns a table of ending types matching the specified filter and property.

**NOTE:** Filtering by a non-namespace property is *very slow*!
Try not to do that too much.
]]


--@static
--@name         wrap
--@return       EndingType
--@param        id          | number    | The ending type ID to wrap.
--[[
Returns an EndingType wrapper containing the provided ending type ID.
]]



-- ========== Instance Methods ==========

--@section Instance Methods

Util.table_append(methods_class_array[name_rapi], {

    --@instance
    --@name         print_properties
    --[[
    Prints the ending type's properties.
    ]]

})
