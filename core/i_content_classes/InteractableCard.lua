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
---@field array Array Alias for .properties.

---@class InteractableCard
---@field namespace                     string  The namespace the interactable card is in.
---@field identifier                    string  The identifier for the interactable card within the namespace.
---@field spawn_cost                    number  
---@field spawn_weight                  number  
---@field object_id                     number  
---@field required_tile_space           number  
---@field spawn_with_sacrifice          boolean 
---@field is_new_interactable           boolean 
---@field default_spawn_rarity_override unknown 
---@field decrease_weight_on_spawn      boolean 


-- ========== Enums ==========

InteractableCard.Property = {
    NAMESPACE                     = 0,
    IDENTIFIER                    = 1,
    SPAWN_COST                    = 2,
    SPAWN_WEIGHT                  = 3,
    OBJECT_ID                     = 4,
    REQUIRED_TILE_SPACE           = 5,
    SPAWN_WITH_SACRIFICE          = 6,
    IS_NEW_INTERACTABLE           = 7,
    DEFAULT_SPAWN_RARITY_OVERRIDE = 8,
    DECREASE_WEIGHT_ON_SPAWN      = 9,
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
    check_init_started("new")
    if not identifier then throw("No identifier provided", "new") end

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
---@param property? number The property to check. <br>InteractableCard.Property.NAMESPACE by default.
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

--[[
Prints the interactable card's properties.
]]
methods.print = function(self) end