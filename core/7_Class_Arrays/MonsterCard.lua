-- MonsterCard

local name_rapi = class_name_g2r["class_monster_card"]
MonsterCard = __class[name_rapi]



-- ========== Enums ==========

--@section Enums

--@enum
--@name Property
--[[
NAMESPACE           0
IDENTIFIER          1
SPAWN_TYPE          2
SPAWN_COST          3
OBJECT_ID           4
IS_BOSS             5
IS_NEW_ENEMY        6
ELITE_LIST          7
CAN_BE_BLIGHTED     8
]]



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The monster card ID being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.

<br>

Property | Type | Description
| - | - | -
`namespace`                     | string    | The namespace the monster card is in.
`identifier`                    | string    | The identifier for the monster card within the namespace.
`spawn_type`                    | number    | 
`spawn_cost`                    | number    | 
`object_id`                     | number    | 
`is_boss`                       | bool      | 
`is_new_enemy`                  | bool      | 
`elite_list`                    |           | 
`can_be_blighted`               | bool      | 
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return   MonsterCard
--@param    identifier  | string    | The identifier for the card.
--[[
Creates a new card with the given identifier if it does not already exist,
or returns the existing one if it does.
]]
MonsterCard.new = function(NAMESPACE, identifier)
    Initialize.internal.check_if_started("MonsterCard.new")
    if not identifier then log.error("MonsterCard.new: No identifier provided", 2) end

    -- Return existing card if found
    local card = MonsterCard.find(identifier, NAMESPACE)
    if card then return card end

    -- Create new
    card = MonsterCard.wrap(gm.monster_card_create(
        NAMESPACE,
        identifier
    ))

    return card
end


--@static
--@name         find
--@return       MonsterCard or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified monster card and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]


--@static
--@name         find_all
--@return       table
--@param        filter      |           | The filter to search by.
--@optional     property    | number    | The property to check. <br>@link {`MonsterCard.Property.NAMESPACE` | MonsterCard#Property} by default.
--[[
Returns a table of monster cards matching the specified filter and property.

**NOTE:** Filtering by a non-namespace property is *very slow*!
Try not to do that too much.
]]


--@static
--@name         wrap
--@return       MonsterCard
--@param        id          | number    | The monster card ID to wrap.
--[[
Returns an MonsterCard wrapper containing the provided monster card ID.
]]



-- ========== Instance Methods ==========

--@section Instance Methods

Util.table_append(methods_class_array[name_rapi], {

    --@instance
    --@name         print_properties
    --[[
    Prints the monster card's properties.
    ]]

})
