-- CLASS_CAPITAL

if true then return end

local name_rapi = class_name_g2r["class_CLASS_LOWER"]
CLASS_CAPITAL = __class[name_rapi]



-- ========== Enums ==========

--@section Enums

--@enum
--@name Property
--[[
NAMESPACE           0
IDENTIFIER          1

]]



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The CLASS_LOWER ID being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.

<br>

Property | Type | Description
| - | - | -
`namespace`         | string    | The namespace the CLASS_LOWER is in.
`identifier`        | string    | The identifier for the CLASS_LOWER within the namespace.
``        |     | 
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@name         find
--@return       CLASS_CAPITAL or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified CLASS_LOWER and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]


--@static
--@name         find_all
--@return       table
--@param        filter      |           | The filter to search by.
--@optional     property    | number    | The property to check. <br>@link {`CLASS_CAPITAL.Property.NAMESPACE` | CLASS_CAPITAL#Property} by default.
--[[
Returns a table of CLASS_LOWERs matching the specified filter and property.

**NOTE:** Filtering by a non-namespace property is *very slow*!
Try not to do that too much.
]]


--@static
--@name         wrap
--@return       CLASS_CAPITAL
--@param        id          | number    | The CLASS_LOWER ID to wrap.
--[[
Returns an CLASS_CAPITAL wrapper containing the provided CLASS_LOWER ID.
]]



-- ========== Instance Methods ==========

--@section Instance Methods

Util.table_append(methods_class_array[name_rapi], {

    --@instance
    --@name         print_properties
    --[[
    Prints the CLASS_LOWER's properties.
    ]]

})
