-- Difficulty

---@class DifficultyClass
Difficulty = C["Difficulty"]

local proxy              = P.proxy
local metatable          = W["Difficulty"]
local find_table_wrapper = P.class_find_tables_wrapper["Difficulty"]
local find_table_array   = P.class_find_tables_array["Difficulty"]

local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class Difficulty
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field properties Array The array storing this difficulty's properties.
---@field array Array Alias for `.properties`.

---@class Difficulty
---@field namespace                       = 0
---@field identifier                      = 1
---@field token_name                      = 2
---@field token_description               = 3
---@field sprite_id                       = 4
---@field sprite_loadout_id               = 5
---@field primary_color                   = 6
---@field sound_id                        = 7
---@field diff_scale                      = 8
---@field general_scale                   = 9
---@field point_scale                     = 10
---@field is_monsoon_or_higher            = 11
---@field allow_blight_spawns             = 12


-- ========== Enums ==========

Difficulty.Property = {

}
local t = {}
for name, num in pairs(Difficulty.Property) do t[num] = name end
for i = 0, #t do Difficulty.Property[i] = t[i] end


-- ========== Static Methods ==========

--[[
Creates a new difficulty with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the difficulty.
---@return Difficulty
Difficulty.new = function(NAMESPACE, identifier)
    throw("Method has not been created for this class yet", "new")
end

--[[
Searches for the specified difficulty and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return Difficulty
Difficulty.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all difficulty in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>`Difficulty.Property.NAMESPACE` by default.
---@return table<number, Difficulty>
Difficulty.find_all = function(NAMESPACE, filter, property) end

--[[
Returns a difficulty wrapper containing the provided difficulty ID.
]]
---@param id number | Difficulty The difficulty to wrap.
---@return Difficulty
Difficulty.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class Difficulty
local methods = G.methods_content["Difficulty"]

-- Insert other methods before `print`

--[[
Prints the difficulty's properties.
]]
methods.print = function(self) end