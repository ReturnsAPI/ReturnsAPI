-- EndingType

---@class EndingTypeClass
EndingType = C["EndingType"]

local proxy              = P.proxy
local metatable          = W["EndingType"]
local find_table_wrapper = P.class_find_tables_wrapper["EndingType"]
local find_table_array   = P.class_find_tables_array["EndingType"]

local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class EndingType
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.

---@class EndingType
-- Populate with properties


-- ========== Enums ==========

EndingType.Property = {

}
local t = {}
for name, num in pairs(EndingType.Property) do t[num] = name end
for i = 0, #t do EndingType.Property[i] = t[i] end


-- ========== Static Methods ==========

--[[
Creates a new ending type with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the ending type.
---@return EndingType
EndingType.new = function(NAMESPACE, identifier)
    throw("Method has not been created for this class yet", "new")
end

--[[
Searches for the specified ending type and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return EndingType
EndingType.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all ending type in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>`EndingType.Property.NAMESPACE` by default.
---@return table<number, EndingType>
EndingType.find_all = function(NAMESPACE, filter, property) end

--[[
Returns an ending type wrapper containing the provided ending type ID.
]]
---@param id number | EndingType The ending type to wrap.
---@return EndingType
EndingType.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class EndingType
local methods = G.methods_content["EndingType"]

-- Insert other methods before `print`

--[[
Prints the ending type's properties.
]]
methods.print = function(self) end