-- Equipment

---@class EquipmentClass
Equipment = C["Equipment"]

local proxy              = P.proxy
local metatable          = W["Equipment"]
local find_table_wrapper = P.class_find_tables_wrapper["Equipment"]
local find_table_array   = P.class_find_tables_array["Equipment"]

local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class Equipment
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field properties Array The array storing this equipment's properties.
---@field array Array Alias for `.properties`.

---@class Equipment
---@field namespace                       = 0
---@field identifier                      = 1
---@field token_name                      = 2
---@field token_text                      = 3
---@field on_use                          = 4
---@field cooldown                        = 5
---@field tier                            = 6
---@field sprite_id                       = 7
---@field object_id                       = 8
---@field item_log_id                     = 9
---@field achievement_id                  = 10
---@field effect_display                  = 11
---@field loot_tags                       = 12
---@field is_new_equipment                = 13


-- ========== Enums ==========

Equipment.Property = {

}
local t = {}
for name, num in pairs(Equipment.Property) do t[num] = name end
for i = 0, #t do Equipment.Property[i] = t[i] end


-- ========== Static Methods ==========

--[[
Creates a new equipment with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the equipment.
---@return Equipment
Equipment.new = function(NAMESPACE, identifier)
    throw("Method has not been created for this class yet", "new")
end

--[[
Searches for the specified equipment and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return Equipment
Equipment.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all equipment in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>`Equipment.Property.NAMESPACE` by default.
---@return table<number, Equipment>
Equipment.find_all = function(NAMESPACE, filter, property) end

--[[
Returns an equipment wrapper containing the provided equipment ID.
]]
---@param id number | Equipment The equipment to wrap.
---@return Equipment
Equipment.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class Equipment
local methods = G.methods_content["Equipment"]

-- Insert other methods before `print`

--[[
Prints the equipment's properties.
]]
methods.print = function(self) end