-- Elite

---@class EliteClass
Elite = C["Elite"]

local proxy              = P.proxy
local metatable          = W["Elite"]
local find_table_wrapper = P.class_find_tables_wrapper["Elite"]
local find_table_array   = P.class_find_tables_array["Elite"]

local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class Elite
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.

---@class Elite
-- Populate with properties


-- ========== Enums ==========

Elite.Property = {

}
local t = {}
for name, num in pairs(Elite.Property) do t[num] = name end
for i = 0, #t do Elite.Property[i] = t[i] end


-- ========== Static Methods ==========

--[[
Creates a new elite with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the elite.
---@return Elite
-- Elite.new = function(NAMESPACE, identifier)

-- end

--[[
Searches for the specified elite and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return Elite
Elite.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all elite in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>`Elite.Property.NAMESPACE` by default.
---@return table<number, Elite>
Elite.find_all = function(NAMESPACE, filter, property) end

--[[
Returns an elite wrapper containing the provided elite ID.
]]
---@param id number | Elite The elite to wrap.
---@return Elite
Elite.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class Elite
local methods = G.methods_content["Elite"]

-- Insert other methods before `print`

--[[
Prints the elite's properties.
]]
methods.print = function(self) end