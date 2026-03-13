-- ActorSkin

--[[
This class is here for completeness.
Skin adding should be done through @link {`survivor:add_skin` | Survivor#add_skin }.
]]



-- ========== Enums ==========

--@section Enums

--@enum
--@name Property
--[[
NAMESPACE                   0
IDENTIFIER                  1
EFFECT_DISPLAY              2
DRAW_LOADOUT_PREVIEW        3
GET_SKIN_SPRITE             4
DRAW_SKINNABLE_INSTANCE     5
SKIN_TYPE_INDEX             6
]]



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The skin ID being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.

<br>

Property | Type | Description
| - | - | -
`namespace`                 | string    | The namespace the skin is in.
`identifier`                | string    | The identifier for the skin within the namespace.
`effect_display`            | EffectDisplay | 
`draw_loadout_preview`      |           | 
`get_skin_sprite`           |           | 
`draw_skinnable_instance`   |           | 
`skin_type_index`           | number    | 
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@name         find
--@return       ActorSkin or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified skin and returns it.

--@findinfo
]]


--@static
--@name         find_all
--@return       table
--@param        filter      |           | The filter to search by.
--@optional     property    | number    | The property to check. <br>@link {`ActorSkin.Property.NAMESPACE` | ActorSkin#Property} by default.
--[[
Returns a table of skins matching the specified filter and property.

**Note on namespace filter:**
--@findinfo

**NOTE:** Filtering by a non-namespace property is *very slow*!
Try not to do that too much.
]]


--@static
--@name         wrap
--@return       ActorSkin
--@param        id          | number    | The skin ID to wrap.
--[[
Returns an ActorSkin wrapper containing the provided skin ID.
]]



-- ========== Instance Methods ==========

--@section Instance Methods

Util.table_append(methods_content_class["ActorSkin"], {

    --@instance
    --@name         print
    --[[
    Prints the skin's properties.
    ]]

})
