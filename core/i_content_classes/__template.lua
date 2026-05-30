if true then return end

-- CLASS_UPPER

---@class CLASS_UPPERClass
CLASS_UPPER = C["CLASS_UPPER"]

local proxy              = P.proxy
local metatable          = W["CLASS_UPPER"]
local find_table_wrapper = P.class_find_tables_wrapper["CLASS_UPPER"]
local find_table_array   = P.class_find_tables_array["CLASS_UPPER"]

local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class CLASS_UPPER
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field properties Array The array storing this CLASS_LOWER's properties.
---@field array Array Alias for `.properties`.

---@class CLASS_UPPER
-- Populate with properties


-- ========== Enums ==========

CLASS_UPPER.Property = {

}
local t = {}
for name, num in pairs(CLASS_UPPER.Property) do t[num] = name end
for i = 0, #t do CLASS_UPPER.Property[i] = t[i] end


-- ========== Static Methods ==========

--[[
Creates a new CLASS_LOWER with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the CLASS_LOWER.
---@return CLASS_UPPER
CLASS_UPPER.new = function(NAMESPACE, identifier)
    throw("Method has not been created for this class yet", "new")
end

--[[
Searches for the specified CLASS_LOWER and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return CLASS_UPPER
CLASS_UPPER.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all CLASS_LOWER in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>`CLASS_UPPER.Property.NAMESPACE` by default.
---@return table<number, CLASS_UPPER>
CLASS_UPPER.find_all = function(NAMESPACE, filter, property) end

--[[
Returns a CLASS_LOWER wrapper containing the provided CLASS_LOWER ID.
]]
---@param id number | CLASS_UPPER The CLASS_LOWER to wrap.
---@return CLASS_UPPER
CLASS_UPPER.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class CLASS_UPPER
local methods = G.methods_content["CLASS_UPPER"]

-- Insert other methods before `print`

--[[
Prints the CLASS_LOWER's properties.
]]
methods.print = function(self) end