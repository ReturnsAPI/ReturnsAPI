-- SurvivorLog

---@class SurvivorLogClass
SurvivorLog = C["SurvivorLog"]

local proxy              = P.proxy
local metatable          = W["SurvivorLog"]
local find_table_wrapper = P.class_find_tables_wrapper["SurvivorLog"]
local find_table_array   = P.class_find_tables_array["SurvivorLog"]

local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class SurvivorLog
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.

---@class SurvivorLog
-- Populate with properties


-- ========== Enums ==========

SurvivorLog.Property = {

}
local t = {}
for name, num in pairs(SurvivorLog.Property) do t[num] = name end
for i = 0, #t do SurvivorLog.Property[i] = t[i] end


-- ========== Static Methods ==========

--[[
Creates a new survivor log with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the survivor log.
---@return SurvivorLog
SurvivorLog.new = function(NAMESPACE, identifier)
    throw("Method has not been created for this class yet", "new")
end

--[[
Searches for the specified survivor log and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return SurvivorLog
SurvivorLog.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all survivor log in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>`SurvivorLog.Property.NAMESPACE` by default.
---@return table<number, SurvivorLog>
SurvivorLog.find_all = function(NAMESPACE, filter, property) end

--[[
Returns a survivor log wrapper containing the provided survivor log ID.
]]
---@param id number | SurvivorLog The survivor log to wrap.
---@return SurvivorLog
SurvivorLog.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class SurvivorLog
local methods = G.methods_content["SurvivorLog"]

-- Insert other methods before `print`

--[[
Prints the survivor log's properties.
]]
methods.print = function(self) end