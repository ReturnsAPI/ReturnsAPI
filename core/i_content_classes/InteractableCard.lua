-- InteractableCard

---@class InteractableCardClass
InteractableCard = C["InteractableCard"]

local proxy              = P.proxy
local metatable          = W["InteractableCard"]
local find_table_wrapper = P.class_find_tables_wrapper["InteractableCard"]
local find_table_array   = P.class_find_tables_array["InteractableCard"]

local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class InteractableCard
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field properties Array The array storing this interactable card's properties.
---@field array Array Alias for `.properties`.

---@class InteractableCard
-- Populate with properties


-- ========== Enums ==========

InteractableCard.Property = {

}
local t = {}
for name, num in pairs(InteractableCard.Property) do t[num] = name end
for i = 0, #t do InteractableCard.Property[i] = t[i] end


-- ========== Static Methods ==========

--[[
Creates a new interactable card with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the interactable card.
---@return InteractableCard
InteractableCard.new = function(NAMESPACE, identifier)
    throw("Method has not been created for this class yet", "new")
end

--[[
Searches for the specified interactable card and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return InteractableCard
InteractableCard.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all interactable card in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>`InteractableCard.Property.NAMESPACE` by default.
---@return table<number, InteractableCard>
InteractableCard.find_all = function(NAMESPACE, filter, property) end

--[[
Returns an interactable card wrapper containing the provided interactable card ID.
]]
---@param id number | InteractableCard The interactable card to wrap.
---@return InteractableCard
InteractableCard.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class InteractableCard
local methods = G.methods_content["InteractableCard"]

-- Insert other methods before `print`

--[[
Prints the interactable card's properties.
]]
methods.print = function(self) end