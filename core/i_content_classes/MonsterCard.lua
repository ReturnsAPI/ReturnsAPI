-- MonsterCard

---@class MonsterCardClass
MonsterCard = C["MonsterCard"]

local proxy              = P.proxy
local metatable          = W["MonsterCard"]
local find_table_wrapper = P.class_find_tables_wrapper["MonsterCard"]
local find_table_array   = P.class_find_tables_array["MonsterCard"]

local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class MonsterCard
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.

---@class MonsterCard
-- Populate with properties


-- ========== Enums ==========

MonsterCard.Property = {

}
local t = {}
for name, num in pairs(MonsterCard.Property) do t[num] = name end
for i = 0, #t do MonsterCard.Property[i] = t[i] end


-- ========== Static Methods ==========

--[[
Creates a new monster card with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the monster card.
---@return MonsterCard
-- MonsterCard.new = function(NAMESPACE, identifier)

-- end

--[[
Searches for the specified monster card and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return MonsterCard
MonsterCard.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all monster card in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>`MonsterCard.Property.NAMESPACE` by default.
---@return table<number, MonsterCard>
MonsterCard.find_all = function(NAMESPACE, filter, property) end

--[[
Returns a monster card wrapper containing the provided monster card ID.
]]
---@param id number | MonsterCard The monster card to wrap.
---@return MonsterCard
MonsterCard.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class MonsterCard
local methods = G.methods_content["MonsterCard"]

-- Insert other methods before `print`

--[[
Prints the monster card's properties.
]]
methods.print = function(self) end