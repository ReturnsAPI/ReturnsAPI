-- <class_capital>

if true then return end

local name_rapi = class_name_g2r["class_<class_lower>"]
<class_capital> = __class[name_rapi]



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
`value`         | number    | *Read-only.* The <class_lower> ID being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.

<br>

Property | Type | Description
| - | - | -
`namespace`         | string    | The namespace the <class_lower> is in.
`identifier`        | string    | The identifier for the <class_lower> within the namespace.
``        |     | 
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@name         find
--@return       <class_capital> or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified <class_lower> and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]


--@static
--@name         find_all
--@return       table
--@param        filter      |           | The filter to search by.
--@optional     property    | number    | The property to check. <br>@link {`<class_capital>.Property.NAMESPACE` | <class_capital>#Property} by default.
--[[
Returns a table of <class_lower>s matching the specified filter and property.

**NOTE:** Filtering by a non-namespace property is *very slow*!
Try not to do that too much.
]]


--@static
--@name         wrap
--@return       <class_capital>
--@param        id          | number    | The <class_lower> ID to wrap.
--[[
Returns an <class_capital> wrapper containing the provided <class_lower> ID.
]]



-- ========== Instance Methods ==========

--@section Instance Methods

Util.table_append(methods_class_array[name_rapi], {

    --@instance
    --@name         print_properties
    --[[
    Prints the <class_lower>'s properties.
    ]]

})
