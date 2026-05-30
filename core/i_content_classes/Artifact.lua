-- Artifact

---@class ArtifactClass
Artifact = C["Artifact"]

local proxy              = P.proxy
local metatable          = W["Artifact"]
local find_table_wrapper = P.class_find_tables_wrapper["Artifact"]
local find_table_array   = P.class_find_tables_array["Artifact"]

local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class Artifact
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field properties Array The array storing this artifact's properties.
---@field array Array Alias for `.properties`.

---@class Artifact
-- Populate with properties


-- ========== Enums ==========

Artifact.Property = {

}
local t = {}
for name, num in pairs(Artifact.Property) do t[num] = name end
for i = 0, #t do Artifact.Property[i] = t[i] end


-- ========== Static Methods ==========

--[[
Creates a new artifact with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the artifact.
---@return Artifact
Artifact.new = function(NAMESPACE, identifier)
    throw("Method has not been created for this class yet", "new")
end

--[[
Searches for the specified artifact and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return Artifact
Artifact.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all artifact in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>`Artifact.Property.NAMESPACE` by default.
---@return table<number, Artifact>
Artifact.find_all = function(NAMESPACE, filter, property) end

--[[
Returns an artifact wrapper containing the provided artifact ID.
]]
---@param id number | Artifact The artifact to wrap.
---@return Artifact
Artifact.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class Artifact
local methods = G.methods_content["Artifact"]

-- Insert other methods before `print`

--[[
Prints the artifact's properties.
]]
methods.print = function(self) end