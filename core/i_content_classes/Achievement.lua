-- Achievement

---@class AchievementClass
Achievement = C["Achievement"]

local proxy              = P.proxy
local metatable          = W["Achievement"]
local find_table_wrapper = P.class_find_tables_wrapper["Achievement"]
local find_table_array   = P.class_find_tables_array["Achievement"]

local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class Achievement
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.

---@class Achievement
-- Populate with properties


-- ========== Enums ==========

Achievement.Property = {

}
local t = {}
for name, num in pairs(Achievement.Property) do t[num] = name end
for i = 0, #t do Achievement.Property[i] = t[i] end


-- ========== Static Methods ==========

--[[
Creates a new achievement with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the achievement.
---@return Achievement
-- Achievement.new = function(NAMESPACE, identifier)

-- end

--[[
Searches for the specified achievement and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return Achievement
Achievement.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all achievement in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>`Achievement.Property.NAMESPACE` by default.
---@return table<number, Achievement>
Achievement.find_all = function(NAMESPACE, filter, property) end

--[[
Returns an achievement wrapper containing the provided achievement ID.
]]
---@param id number | Achievement The achievement to wrap.
---@return Achievement
Achievement.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class Achievement
local methods = G.methods_content["Achievement"]

-- Insert other methods before `print`

--[[
Prints the achievement's properties.
]]
methods.print = function(self) end