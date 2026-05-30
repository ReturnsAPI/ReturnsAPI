-- Buff

---@class BuffClass
Buff = C["Buff"]

local proxy              = P.proxy
local metatable          = W["Buff"]
local find_table_wrapper = P.class_find_tables_wrapper["Buff"]
local find_table_array   = P.class_find_tables_array["Buff"]

local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class Buff
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field properties Array The array storing this buff's properties.
---@field array Array Alias for `.properties`.

---@class Buff
---@field namespace                       = 0
---@field identifier                      = 1
---@field show_icon                       = 2
---@field icon_sprite                     = 3
---@field icon_subimage                   = 4
---@field icon_frame_speed                = 5
---@field icon_stack_subimage             = 6
---@field draw_stack_number               = 7
---@field stack_number_col                = 8
---@field max_stack                       = 9
---@field on_apply                        = 10
---@field on_remove                       = 11
---@field on_step                         = 12
---@field is_timed                        = 13
---@field is_debuff                       = 14
---@field client_handles_removal          = 15
---@field effect_display                  = 16


-- ========== Enums ==========

Buff.Property = {

}
local t = {}
for name, num in pairs(Buff.Property) do t[num] = name end
for i = 0, #t do Buff.Property[i] = t[i] end


-- ========== Static Methods ==========

--[[
Creates a new buff with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the buff.
---@return Buff
Buff.new = function(NAMESPACE, identifier)
    throw("Method has not been created for this class yet", "new")
end

--[[
Searches for the specified buff and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return Buff
Buff.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all buff in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>`Buff.Property.NAMESPACE` by default.
---@return table<number, Buff>
Buff.find_all = function(NAMESPACE, filter, property) end

--[[
Returns a buff wrapper containing the provided buff ID.
]]
---@param id number | Buff The buff to wrap.
---@return Buff
Buff.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class Buff
local methods = G.methods_content["Buff"]

-- Insert other methods before `print`

--[[
Prints the buff's properties.
]]
methods.print = function(self) end