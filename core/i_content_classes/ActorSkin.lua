-- ActorSkin

---@class ActorSkinClass
ActorSkin = C["ActorSkin"]

local proxy              = P.proxy
local metatable          = W["ActorSkin"]
local find_table_wrapper = P.class_find_tables_wrapper["ActorSkin"]
local find_table_array   = P.class_find_tables_array["ActorSkin"]

local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class ActorSkin
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field properties Array The array storing this actor skin's properties.
---@field array Array Alias for `.properties`.

---@class ActorSkin
-- Populate with properties


-- ========== Enums ==========

ActorSkin.Property = {

}
local t = {}
for name, num in pairs(ActorSkin.Property) do t[num] = name end
for i = 0, #t do ActorSkin.Property[i] = t[i] end


-- ========== Static Methods ==========

--[[
Creates a new actor skin with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the actor skin.
---@return ActorSkin
ActorSkin.new = function(NAMESPACE, identifier)
    throw("Method has not been created for this class yet", "new")
end

--[[
Searches for the specified actor skin and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return ActorSkin
ActorSkin.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all actor skin in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>`ActorSkin.Property.NAMESPACE` by default.
---@return table<number, ActorSkin>
ActorSkin.find_all = function(NAMESPACE, filter, property) end

--[[
Returns an actor skin wrapper containing the provided actor skin ID.
]]
---@param id number | ActorSkin The actor skin to wrap.
---@return ActorSkin
ActorSkin.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class ActorSkin
local methods = G.methods_content["ActorSkin"]

-- Insert other methods before `print`

--[[
Prints the actor skin's properties.
]]
methods.print = function(self) end