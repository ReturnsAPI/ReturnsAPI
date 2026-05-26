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

---@class ActorState
-- Populate with properties


-- ========== Enums ==========

ActorState.Property = {

}
local t = {}
for name, num in pairs(ActorState.Property) do t[num] = name end
for i = 0, #t do ActorState.Property[i] = t[i] end


-- ========== Static Methods ==========

--[[
Creates a new actor state with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the actor state.
---@return ActorState
-- ActorState.new = function(NAMESPACE, identifier)

-- end

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
---@param property? number The property to check. <br>`ActorState.Property.NAMESPACE` by default.
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

-- Insert other methods before `print`

--[[
Prints the actor state's properties.
]]
methods.print = function(self) end