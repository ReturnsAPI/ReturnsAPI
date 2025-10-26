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
SPRITE_LOADOUT_ID   5
SPRITE_PICKUP_ID    6
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
`token_name`        | string    | The localization token for the artifact's name.
`token_pickup_name` | string    | 
`token_description` | string    | 
`sprite_loadout_id` | sprite    | 
`sprite_pickup_id`  | sprite    | 
`on_set_active`     | number    | The ID of the callback that runs when entering *and* exiting a run with the artifact enabled. <br>The callback function should have the argument `active` (`true` when entering and `false` when exiting).
`active`            | bool      | `true` while in a run with the artifact enabled.
`achievement_id`    | number    | The achievement ID of the artifact. <br>If *not* `-1`, the artifact will be locked until the achievement is unlocked.
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return   Artifact
--@param    identifier  | string    | The identifier for the artifact.
--[[
Creates a new artifact with the given identifier if it does not already exist,
or returns the existing one if it does.
]]
Artifact.new = function(NAMESPACE, identifier)
    Initialize.internal.check_if_started("Artifact.new")
    if not identifier then log.error("Artifact.new: No identifier provided", 2) end

    -- Return existing artifact if found
    local artifact = Artifact.find(identifier, NAMESPACE, true)
    if artifact then return artifact end

    -- Create new
    artifact = Artifact.wrap(gm.artifact_create(
        NAMESPACE,
        identifier
    ))

    return artifact
end


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


    --@instance
    --@return       Achievement
    --[[
    Returns the associated @link {Achievement | Achievement} if it exists,
    or an invalid Achievement if it does not.
    ]]
    get_achievement = function(self)
        return Achievement.wrap(self.achievement_id)
    end

})
