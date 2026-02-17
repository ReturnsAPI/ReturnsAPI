-- EndingType



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

--@findinfo
]]


--@static
--@name         find_all
--@return       table
--@param        filter      |           | The filter to search by.
--@optional     property    | number    | The property to check. <br>@link {`EndingType.Property.NAMESPACE` | EndingType#Property} by default.
--[[
Returns a table of ending types matching the specified filter and property.

**Note on namespace filter:**
--@findinfo

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

Util.table_append(methods_content_class["EndingType"], {

    --@instance
    --@name         print
    --[[
    Prints the ending type's properties.
    ]]

})
