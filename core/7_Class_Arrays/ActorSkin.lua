-- ActorSkin

local name_rapi = class_name_g2r["class_actor_skin"]
ActorSkin = __class[name_rapi]



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
--@return   ActorSkin
--@param    identifier  | string    | The identifier for the skin.
--[[
Creates a new skin with the given identifier if it does not already exist,
or returns the existing one if it does.

This should generally not be called; use @link {`add_from_palette` | ActorSkin#add_from_palette} instead.
]]
ActorSkin.new = function(NAMESPACE, identifier)
    Initialize.internal.check_if_started("ActorSkin.new")
    if not identifier then log.error("ActorSkin.new: No identifier provided", 2) end

    -- Return existing skin if found
    local skin = ActorSkin.find(identifier, NAMESPACE, true)
    if skin then return skin end

    -- Create new
    skin = ActorSkin.wrap(gm.actor_skin_create(
        NAMESPACE,
        identifier
    ))

    return skin
end


--@static
--@name         find
--@return       ActorSkin or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified skin and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]


--@static
--@name         find_all
--@return       table
--@param        filter      |           | The filter to search by.
--@optional     property    | number    | The property to check. <br>@link {`ActorSkin.Property.NAMESPACE` | ActorSkin#Property} by default.
--[[
Returns a table of skins matching the specified filter and property.

**NOTE:** Filtering by a non-namespace property is *very slow*!
Try not to do that too much.
]]


--@instance
--@return       table
--@param        survivor            | Survivor  | The survivor to add skins to.
--@param        identifiers         | table     | A table of string identifiers for the skins (in order).
--@param        palette             | sprite    | A sprite containing palette data for in-game sprites. <br>Each new skin should be in a single column, and the <br> width of the sprite is the amount of new skins to add.
--@optional     palette_portrait    | sprite    | A sprite containing palette data for the mini portrait. <br>Uses `palette` by default.
--@optional     palette_loadout     | sprite    | A sprite containing palette data for the select animation. <br>Uses `palette` by default.
--[[
Adds new skins from a palette sprite.
Returns a table of ActorSkins.

If adding skins to a survivor without an existing `palette` (i.e., in the
case of new survivors), the first column should be the original colors.

WIP
]]
ActorSkin.add_from_palette = function(NAMESPACE, survivor, identifiers, palette, palette_portrait, palette_loadout)
    -- TODO

    -- Cannot have this run before prov skin stuff is setup (since that uses `gm.sprite_get_width()`)
    Initialize.internal.check_if_started("ActorSkin.add_from_palette")

    survivor         = Survivor.wrap(survivor)
    palette          = Wrap.unwrap(palette)
    palette_portrait = Wrap.unwrap(palette_portrait) or palette
    palette_loadout  = Wrap.unwrap(palette_loadout)  or palette
    if type(identifiers)      ~= "table"  then log.error("ActorSkin.add_from_palette: Invalid identifiers argument", 2) end
    if type(palette)          ~= "number" then log.error("ActorSkin.add_from_palette: Invalid palette argument", 2) end
    if type(palette_portrait) ~= "number" then log.error("ActorSkin.add_from_palette: Invalid palette_portrait argument", 2) end
    if type(palette_loadout)  ~= "number" then log.error("ActorSkin.add_from_palette: Invalid palette_loadout argument", 2) end

    -- also check if #identifiers < palette
    -- identifiers are checked to not readd skins to survivor on hotload

    
end


--@static
--@name         wrap
--@return       ActorSkin
--@param        id          | number    | The skin ID to wrap.
--[[
Returns an ActorSkin wrapper containing the provided skin ID.
]]



-- ========== Instance Methods ==========

--@section Instance Methods

Util.table_append(methods_class_array[name_rapi], {

    --@instance
    --@name         print_properties
    --[[
    Prints the skin's properties.
    ]]

})
