-- MonsterLog

---@class MonsterLogClass
MonsterLog = C["MonsterLog"]

local proxy              = P.proxy
local metatable          = W["MonsterLog"]
local find_table_wrapper = P.class_find_tables_wrapper["MonsterLog"]
local find_table_array   = P.class_find_tables_array["MonsterLog"]

local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class MonsterLog
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.

---@class MonsterLog
-- Populate with properties


-- ========== Enums ==========

MonsterLog.Property = {

}
local t = {}
for name, num in pairs(MonsterLog.Property) do t[num] = name end
for i = 0, #t do MonsterLog.Property[i] = t[i] end


-- ========== Static Methods ==========

--[[
Creates a new monster log with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the monster log.
---@return MonsterLog
-- MonsterLog.new = function(NAMESPACE, identifier)

-- end

--[[
Searches for the specified monster log and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return MonsterLog
MonsterLog.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all monster log in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>`MonsterLog.Property.NAMESPACE` by default.
---@return table<number, MonsterLog>
MonsterLog.find_all = function(NAMESPACE, filter, property) end

--[[
Returns a monster log wrapper containing the provided monster log ID.
]]
---@param id number | MonsterLog The monster log to wrap.
---@return MonsterLog
MonsterLog.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class MonsterLog
local methods = G.methods_content["MonsterLog"]

-- Insert other methods before `print`

--[[
Prints the monster log's properties.
]]
methods.print = function(self) end