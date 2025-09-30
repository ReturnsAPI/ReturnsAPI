-- ActorState

local name_rapi = class_name_g2r["class_actor_state"]
ActorState = __class[name_rapi]



-- ========== Enums ==========

--@section Enums

--@enum
--@name Property
--[[
NAMESPACE                   0
IDENTIFIER                  1
ON_ENTER                    2
ON_EXIT                     3
ON_STEP                     4
ON_GET_INTERRUPT_PRIORITY   5
CALLABLE_SERIALIZE          6
CALLABLE_DESERIALIZE        7
IS_SKILL_STATE              8
IS_CLIMB_STATE              9
ACTIVITY_FLAGS              10
]]



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The state ID being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.

<br>

Property | Type | Description
| - | - | -
`namespace`                 | string    | The namespace the state is in.
`identifier`                | string    | The identifier for the state within the namespace.
`on_enter`                  | number    | 
`on_exit`                   | number    | 
`on_step`                   | number    | 
`on_get_interrupt_priority` | number    | 
`callable_serialize`        |           | 
`callable_deserialize`      |           | 
`is_skill_state`            | bool      | 
`is_climb_state`            | bool      | 
`activity_flags`            | number    | 
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@name         find
--@return       ActorState or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified state and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]


--@static
--@name         find_all
--@return       table
--@param        filter      |           | The filter to search by.
--@optional     property    | number    | The property to check. <br>@link {`ActorState.Property.NAMESPACE` | ActorState#Property} by default.
--[[
Returns a table of states matching the specified filter and property.

**NOTE:** Filtering by a non-namespace property is *very slow*!
Try not to do that too much.
]]


--@static
--@name         wrap
--@return       ActorState
--@param        id          | number    | The state ID to wrap.
--[[
Returns an ActorState wrapper containing the provided state ID.
]]



-- ========== Instance Methods ==========

--@section Instance Methods

Util.table_append(methods_class_array[name_rapi], {

    --@instance
    --@name         print_properties
    --[[
    Prints the state's properties.
    ]]

})
