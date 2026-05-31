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
---@field array Array Alias for .properties.

---@class MonsterLog
---@field namespace                     string  The namespace the monster log is in.
---@field identifier                    string  The identifier for the monster log within the namespace.
---@field token_name                    string  
---@field token_story                   string  
---@field sprite_id                     number  
---@field portrait_id                   unknown 
---@field portrait_index                unknown 
---@field sprite_offset_x               number  
---@field sprite_offset_y               number  
---@field sprite_force_horizontal_align boolean 
---@field sprite_height_offset          number  
---@field stat_hp                       number  
---@field stat_damage                   number  
---@field stat_speed                    number  
---@field log_backdrop_index            unknown 
---@field object_id                     number  
---@field enemy_object_ids_kills        unknown 
---@field enemy_object_ids_deaths       unknown 


-- ========== Enums ==========

MonsterLog.Property = {
    NAMESPACE                     = 0,
    IDENTIFIER                    = 1,
    TOKEN_NAME                    = 2,
    TOKEN_STORY                   = 3,
    SPRITE_ID                     = 4,
    PORTRAIT_ID                   = 5,
    PORTRAIT_INDEX                = 6,
    SPRITE_OFFSET_X               = 7,
    SPRITE_OFFSET_Y               = 8,
    SPRITE_FORCE_HORIZONTAL_ALIGN = 9,
    SPRITE_HEIGHT_OFFSET          = 10,
    STAT_HP                       = 11,
    STAT_DAMAGE                   = 12,
    STAT_SPEED                    = 13,
    LOG_BACKDROP_INDEX            = 14,
    OBJECT_ID                     = 15,
    ENEMY_OBJECT_IDS_KILLS        = 16,
    ENEMY_OBJECT_IDS_DEATHS       = 17,
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
    check_init_started("new")
    if not identifier then throw("No identifier provided", "new") end

    -- Return existing card if found
    local card = MonsterCard.find(identifier, NAMESPACE, true)
    if card then return card end

    -- Create new
    card = MonsterLog.wrap(gm.monster_log_create(
        NAMESPACE,
        identifier
    ))

    return card
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
---@param property? number The property to check. <br>MonsterLog.Property.NAMESPACE by default.
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

--[[
Prints the monster log's properties.
]]
methods.print = function(self) end