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


--@enum
ActorState.ActivityFlag = {
    NONE                    = 0,
    ALLOW_ROPE_CANCEL       = 1,
    ALLOW_AIM_TURN          = 2
}


--@enum
ActorState.InterruptPriority = {
    ANY                     = 0,
    SKILL_INTERRUPT_PERIOD  = 1,
    SKILL                   = 2,
    PRIORITY_SKILL          = 3,
    LEGACY_ACTIVITY_STATE   = 4,
    CLIMB                   = 5,
    PAIN                    = 6,
    FROZEN                  = 7,
    CHARGE                  = 8,
    VEHICLE                 = 9,
    BURROWED                = 10,
    SPAWN                   = 11,
    TELEPORT                = 12
}



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
`on_enter`                  | number    | The ID of the callback that runs when the state is entered. <br>The callback function should have the arguments `actor, data`. <br>`data` is a persistent Struct created by the game.
`on_exit`                   | number    | The ID of the callback that runs when the state is exited. <br>The callback function should have the arguments `actor, data`. <br>`data` is a persistent Struct created by the game.
`on_step`                   | number    | The ID of the callback that runs every frame while in the state. <br>The callback function should have the arguments `actor, data`. <br>`data` is a persistent Struct created by the game.
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
--@return   ActorState
--@param    identifier  | string    | The identifier for the state.
--[[
Creates a new state with the given identifier if it does not already exist,
or returns the existing one if it does.
]]
ActorState.new = function(NAMESPACE, identifier)
    Initialize.internal.check_if_started()
    if not identifier then log.error("No identifier provided", 2) end

    -- Return existing state if found
    local state = ActorState.find(identifier, NAMESPACE)
    if state then return state end

    -- Create new
    state = ActorState.wrap(gm.actor_state_create(
        NAMESPACE,
        identifier
    ))

    return state
end


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
