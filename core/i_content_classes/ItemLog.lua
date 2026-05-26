-- ItemLog

---@class ItemLogClass
ItemLog = C["ItemLog"]

local proxy              = P.proxy
local metatable          = W["ItemLog"]
local find_table_wrapper = P.class_find_tables_wrapper["ItemLog"]
local find_table_array   = P.class_find_tables_array["ItemLog"]

local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class ItemLog
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.

---@class ItemLog
-- Populate with properties


-- ========== Enums ==========

ItemLog.Property = {

}
local t = {}
for name, num in pairs(ItemLog.Property) do t[num] = name end
for i = 0, #t do ItemLog.Property[i] = t[i] end


-- ========== Static Methods ==========

--[[
Creates a new item log with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the item log.
---@return ItemLog
ItemLog.new = function(NAMESPACE, identifier)
    throw("Method has not been created for this class yet", "new")
end

--[[
Searches for the specified item log and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return ItemLog
ItemLog.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all item log in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>`ItemLog.Property.NAMESPACE` by default.
---@return table<number, ItemLog>
ItemLog.find_all = function(NAMESPACE, filter, property) end

--[[
Returns an item log wrapper containing the provided item log ID.
]]
---@param id number | ItemLog The item log to wrap.
---@return ItemLog
ItemLog.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class ItemLog
local methods = G.methods_content["ItemLog"]

-- Insert other methods before `print`

--[[
Prints the item log's properties.
]]
methods.print = function(self) end