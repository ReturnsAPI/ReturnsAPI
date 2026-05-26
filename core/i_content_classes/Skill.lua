-- Skill

---@class SkillClass
Skill = C["Skill"]

local proxy              = P.proxy
local metatable          = W["Skill"]
local find_table_wrapper = P.class_find_tables_wrapper["Skill"]
local find_table_array   = P.class_find_tables_array["Skill"]

local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class Skill
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.

---@class Skill
-- Populate with properties


-- ========== Enums ==========

Skill.Property = {

}
local t = {}
for name, num in pairs(Skill.Property) do t[num] = name end
for i = 0, #t do Skill.Property[i] = t[i] end


-- ========== Static Methods ==========

--[[
Creates a new skill with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the skill.
---@return Skill
Skill.new = function(NAMESPACE, identifier)
    throw("Method has not been created for this class yet", "new")
end

--[[
Searches for the specified skill and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return Skill
Skill.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all skill in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>`Skill.Property.NAMESPACE` by default.
---@return table<number, Skill>
Skill.find_all = function(NAMESPACE, filter, property) end

--[[
Returns a skill wrapper containing the provided skill ID.
]]
---@param id number | Skill The skill to wrap.
---@return Skill
Skill.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class Skill
local methods = G.methods_content["Skill"]

-- Insert other methods before `print`

--[[
Prints the skill's properties.
]]
methods.print = function(self) end