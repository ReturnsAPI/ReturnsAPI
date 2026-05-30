-- Survivor

---@class SurvivorClass
Survivor = C["Survivor"]

local proxy              = P.proxy
local metatable          = W["Survivor"]
local find_table_wrapper = P.class_find_tables_wrapper["Survivor"]
local find_table_array   = P.class_find_tables_array["Survivor"]

local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class Survivor
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field properties Array The array storing this survivor's properties.
---@field array Array Alias for `.properties`.

---@class Survivor
---@field namespace                       = 0
---@field identifier                      = 1
---@field token_name                      = 2
---@field token_name_upper                = 3
---@field token_description               = 4
---@field token_end_quote                 = 5
---@field skill_family_z                  = 6
---@field skill_family_x                  = 7
---@field skill_family_c                  = 8
---@field skill_family_v                  = 9
---@field skin_family                     = 10
---@field all_loadout_families            = 11
---@field all_skill_families              = 12
---@field sprite_loadout                  = 13
---@field sprite_title                    = 14
---@field sprite_idle                     = 15
---@field sprite_portrait                 = 16
---@field sprite_portrait_small           = 17
---@field sprite_palette                  = 18
---@field sprite_portrait_palette         = 19
---@field sprite_loadout_palette          = 20
---@field sprite_credits                  = 21
---@field primary_color                   = 22
---@field select_sound_id                 = 23
---@field log_id                          = 24
---@field achievement_id                  = 25
---@field milestone_kills_1               = 26
---@field milestone_items_1               = 27
---@field milestone_stages_1              = 28
---@field on_init                         = 29
---@field on_step                         = 30
---@field on_remove                       = 31
---@field is_secret                       = 32
---@field cape_offset                     = 33


-- ========== Enums ==========

Survivor.Property = {

}
local t = {}
for name, num in pairs(Survivor.Property) do t[num] = name end
for i = 0, #t do Survivor.Property[i] = t[i] end


-- ========== Static Methods ==========

--[[
Creates a new survivor with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the survivor.
---@return Survivor
Survivor.new = function(NAMESPACE, identifier)
    throw("Method has not been created for this class yet", "new")
end

--[[
Searches for the specified survivor and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return Survivor
Survivor.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all survivor in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>`Survivor.Property.NAMESPACE` by default.
---@return table<number, Survivor>
Survivor.find_all = function(NAMESPACE, filter, property) end

--[[
Returns a survivor wrapper containing the provided survivor ID.
]]
---@param id number | Survivor The survivor to wrap.
---@return Survivor
Survivor.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class Survivor
local methods = G.methods_content["Survivor"]

-- Insert other methods before `print`

--[[
Prints the survivor's properties.
]]
methods.print = function(self) end