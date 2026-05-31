-- ActorState

---@class ActorStateClass
ActorState = C["ActorState"]

local proxy              = P.proxy
local metatable          = W["ActorState"]
local find_table_wrapper = P.class_find_tables_wrapper["ActorState"]
local find_table_array   = P.class_find_tables_array["ActorState"]

local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class ActorState
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field properties Array The array storing this actor state's properties.
---@field array Array Alias for .properties.

---@class ActorState
---@field namespace                 string  The namespace the state is in.
---@field identifier                string  The identifier for the state within the namespace.
---@field on_enter                  number  The ID of the callback that runs when the state is entered. <br>The callback function should have the arguments actor, data. <br>data is a persistent Struct created by the game.
---@field on_exit                   number  The ID of the callback that runs when the state is exited. <br>The callback function should have the arguments actor, data. <br>data is a persistent Struct created by the game.
---@field on_step                   number  The ID of the callback that runs every frame while in the state. <br>The callback function should have the arguments actor, data. <br>data is a persistent Struct created by the game.
---@field on_get_interrupt_priority number  
---@field callable_serialize        unknown 
---@field callable_deserialize      unknown 
---@field is_skill_state            boolean 
---@field is_climb_state            boolean 
---@field activity_flags            number  


-- ========== Enums ==========

ActorState.Property = {
    NAMESPACE                 = 0,
    IDENTIFIER                = 1,
    ON_ENTER                  = 2,
    ON_EXIT                   = 3,
    ON_STEP                   = 4,
    ON_GET_INTERRUPT_PRIORITY = 5,
    CALLABLE_SERIALIZE        = 6,
    CALLABLE_DESERIALIZE      = 7,
    IS_SKILL_STATE            = 8,
    IS_CLIMB_STATE            = 9,
    ACTIVITY_FLAGS            = 10,
}
local t = {}
for name, num in pairs(ActorState.Property) do t[num] = name end
for i = 0, #t do ActorState.Property[i] = t[i] end

ActorState.ActivityFlag = {
    NONE              = 0,
    ALLOW_ROPE_CANCEL = 1,
    ALLOW_AIM_TURN    = 2,
}

ActorState.InterruptPriority = {
    ANY                    = 0,
    SKILL_INTERRUPT_PERIOD = 1,
    SKILL                  = 2,
    PRIORITY_SKILL         = 3,
    LEGACY_ACTIVITY_STATE  = 4,
    CLIMB                  = 5,
    PAIN                   = 6,
    FROZEN                 = 7,
    CHARGE                 = 8,
    VEHICLE                = 9,
    BURROWED               = 10,
    SPAWN                  = 11,
    TELEPORT               = 12,
}


-- ========== Static Methods ==========

--[[
Creates a new actor state with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the actor state.
---@return ActorState
ActorState.new = function(NAMESPACE, identifier)
    check_init_started("new")
    if not identifier then throw("No identifier provided", "new") end

    -- Return existing state if found
    local state = ActorState.find(identifier, NAMESPACE, true)
    if state then return state end

    -- Create new
    state = ActorState.wrap(gm.actor_state_create(
        NAMESPACE,
        identifier
    ))

    return state
end

--[[
Searches for the specified actor state and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return ActorState
ActorState.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all actor state in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>ActorState.Property.NAMESPACE by default.
---@return table<number, ActorState>
ActorState.find_all = function(NAMESPACE, filter, property) end

--[[
Returns an actor state wrapper containing the provided actor state ID.
]]
---@param id number | ActorState The actor state to wrap.
---@return ActorState
ActorState.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class ActorState
local methods = G.methods_content["ActorState"]

--[[
Prints the actor state's properties.
]]
methods.print = function(self) end