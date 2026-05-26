-- EnvironmentLog

---@class EnvironmentLogClass
EnvironmentLog = C["EnvironmentLog"]

local proxy              = P.proxy
local metatable          = W["EnvironmentLog"]
local find_table_wrapper = P.class_find_tables_wrapper["EnvironmentLog"]
local find_table_array   = P.class_find_tables_array["EnvironmentLog"]

local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class EnvironmentLog
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.

---@class EnvironmentLog
-- Populate with properties


-- ========== Enums ==========

EnvironmentLog.Property = {

}
local t = {}
for name, num in pairs(EnvironmentLog.Property) do t[num] = name end
for i = 0, #t do EnvironmentLog.Property[i] = t[i] end


-- ========== Static Methods ==========

--[[
Creates a new environment log with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the environment log.
---@return EnvironmentLog
-- EnvironmentLog.new = function(NAMESPACE, identifier)

-- end

--[[
Searches for the specified environment log and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return EnvironmentLog
EnvironmentLog.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all environment log in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>`EnvironmentLog.Property.NAMESPACE` by default.
---@return table<number, EnvironmentLog>
EnvironmentLog.find_all = function(NAMESPACE, filter, property) end

--[[
Returns an environment log wrapper containing the provided environment log ID.
]]
---@param id number | EnvironmentLog The environment log to wrap.
---@return EnvironmentLog
EnvironmentLog.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class EnvironmentLog
local methods = G.methods_content["EnvironmentLog"]

-- Insert other methods before `print`

--[[
Prints the environment log's properties.
]]
methods.print = function(self) end