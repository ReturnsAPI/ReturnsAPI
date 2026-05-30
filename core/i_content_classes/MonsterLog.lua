-- MonsterLog

---@class MonsterLogClass
MonsterLog = C["MonsterLog"]

local proxy              = P.proxy
local metatable          = W["MonsterLog"]
local find_table_wrapper = P.class_find_tables_wrapper["MonsterLog"]
local find_table_array   = P.class_find_tables_array["MonsterLog"]

local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class MonsterLog
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field properties Array The array storing this monster log's properties.
---@field array Array Alias for `.properties`.

---@class MonsterLog
---@field namespace                       = 0
---@field identifier                      = 1
---@field token_name                      = 2
---@field token_story                     = 3
---@field sprite_id                       = 4
---@field portrait_id                     = 5
---@field portrait_index                  = 6
---@field sprite_offset_x                 = 7
---@field sprite_offset_y                 = 8
---@field sprite_force_horizontal_align   = 9
---@field sprite_height_offset            = 10
---@field stat_hp                         = 11
---@field stat_damage                     = 12
---@field stat_speed                      = 13
---@field log_backdrop_index              = 14
---@field object_id                       = 15
---@field enemy_object_ids_kills          = 16
---@field enemy_object_ids_deaths         = 17


-- ========== Enums ==========

MonsterLog.Property = {

}
local t = {}
for name, num in pairs(MonsterLog.Property) do t[num] = name end
for i = 0, #t do MonsterLog.Property[i] = t[i] end


-- ========== Static Methods ==========

--[[
Creates a new monster log with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the monster log.
---@return MonsterLog
MonsterLog.new = function(NAMESPACE, identifier)
    throw("Method has not been created for this class yet", "new")
end

--[[
Searches for the specified monster log and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return MonsterLog
MonsterLog.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all monster log in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>`MonsterLog.Property.NAMESPACE` by default.
---@return table<number, MonsterLog>
MonsterLog.find_all = function(NAMESPACE, filter, property) end

--[[
Returns a monster log wrapper containing the provided monster log ID.
]]
---@param id number | MonsterLog The monster log to wrap.
---@return MonsterLog
MonsterLog.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class MonsterLog
local methods = G.methods_content["MonsterLog"]

-- Insert other methods before `print`

--[[
Prints the monster log's properties.
]]
methods.print = function(self) end