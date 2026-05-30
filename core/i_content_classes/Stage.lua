-- Stage

---@class StageClass
Stage = C["Stage"]

local proxy              = P.proxy
local metatable          = W["Stage"]
local find_table_wrapper = P.class_find_tables_wrapper["Stage"]
local find_table_array   = P.class_find_tables_array["Stage"]

local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class Stage
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field properties Array The array storing this stage's properties.
---@field array Array Alias for `.properties`.

---@class Stage
---@field namespace                       = 0
---@field identifier                      = 1
---@field token_name                      = 2
---@field token_subname                   = 3
---@field spawn_enemies                   = 4
---@field spawn_enemies_loop              = 5
---@field spawn_interactables             = 6
---@field spawn_interactables_loop        = 7
---@field spawn_interactable_rarity       = 8
---@field interactable_spawn_points       = 9
---@field allow_mountain_shrine_spawn     = 10
---@field classic_variant_count           = 11
---@field is_new_stage                    = 12
---@field room_list                       = 13
---@field music_id                        = 14
---@field teleporter_index                = 15
---@field populate_biome_properties       = 16
---@field log_id                          = 17


-- ========== Enums ==========

Stage.Property = {

}
local t = {}
for name, num in pairs(Stage.Property) do t[num] = name end
for i = 0, #t do Stage.Property[i] = t[i] end


-- ========== Static Methods ==========

--[[
Creates a new stage with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the stage.
---@return Stage
Stage.new = function(NAMESPACE, identifier)
    throw("Method has not been created for this class yet", "new")
end

--[[
Searches for the specified stage and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return Stage
Stage.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all stage in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>`Stage.Property.NAMESPACE` by default.
---@return table<number, Stage>
Stage.find_all = function(NAMESPACE, filter, property) end

--[[
Returns a stage wrapper containing the provided stage ID.
]]
---@param id number | Stage The stage to wrap.
---@return Stage
Stage.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class Stage
local methods = G.methods_content["Stage"]

-- Insert other methods before `print`

--[[
Prints the stage's properties.
]]
methods.print = function(self) end