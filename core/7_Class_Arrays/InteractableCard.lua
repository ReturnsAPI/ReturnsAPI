-- InteractableCard

local name_rapi = class_name_g2r["class_interactable_card"]
InteractableCard = __class[name_rapi]



-- ========== Enums ==========

--@section Enums

--@enum
--@name Property
--[[
NAMESPACE                       0
IDENTIFIER                      1
SPAWN_COST                      2
SPAWN_WEIGHT                    3
OBJECT_ID                       4
REQUIRED_TILE_SPACE             5
SPAWN_WITH_SACRIFICE            6
IS_NEW_INTERACTABLE             7
DEFAULT_SPAWN_RARITY_OVERRIDE   8
DECREASE_WEIGHT_ON_SPAWN        9
]]



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The interactable card ID being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.

<br>

Property | Type | Description
| - | - | -
`namespace`                     | string    | The namespace the interactable card is in.
`identifier`                    | string    | The identifier for the interactable card within the namespace.
`spawn_cost`                    | number    | 
`spawn_weight`                  | number    | 
`object_id`                     | number    | 
`required_tile_space`           | number    | 
`spawn_with_sacrifice`          | bool      | 
`is_new_interactable`           | bool      | 
`default_spawn_rarity_override` |           | 
`decrease_weight_on_spawn`      | bool      | 
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return   InteractableCard
--@param    identifier  | string    | The identifier for the card.
--[[
Creates a new card with the given identifier if it does not already exist,
or returns the existing one if it does.
]]
InteractableCard.new = function(NAMESPACE, identifier)
    Initialize.internal.check_if_started("InteractableCard.new")
    if not identifier then log.error("InteractableCard.new: No identifier provided", 2) end

    -- Return existing card if found
    local card = InteractableCard.find(identifier, NAMESPACE, true)
    if card then return card end

    -- Create new
    card = InteractableCard.wrap(gm.interactable_card_create(
        NAMESPACE,
        identifier
    ))

    return card
end


--@static
--@name         find
--@return       InteractableCard or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified interactable card and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]


--@static
--@name         find_all
--@return       table
--@param        filter      |           | The filter to search by.
--@optional     property    | number    | The property to check. <br>@link {`InteractableCard.Property.NAMESPACE` | InteractableCard#Property} by default.
--[[
Returns a table of interactable cards matching the specified filter and property.

**NOTE:** Filtering by a non-namespace property is *very slow*!
Try not to do that too much.
]]


--@static
--@name         wrap
--@return       InteractableCard
--@param        id          | number    | The interactable card ID to wrap.
--[[
Returns an InteractableCard wrapper containing the provided interactable card ID.
]]



-- ========== Instance Methods ==========

--@section Instance Methods

Util.table_append(methods_class_array[name_rapi], {

    --@instance
    --@name         print
    --[[
    Prints the interactable card's properties.
    ]]

})
