-- SurvivorLog

---@class SurvivorLogClass
SurvivorLog = C["SurvivorLog"]

local proxy              = P.proxy
local metatable          = W["SurvivorLog"]
local find_table_wrapper = P.class_find_tables_wrapper["SurvivorLog"]
local find_table_array   = P.class_find_tables_array["SurvivorLog"]

local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class SurvivorLog
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field properties Array The array storing this survivor log's properties.
---@field array Array Alias for `.properties`.

---@class SurvivorLog
---@field namespace         string The namespace the survivor log is in.
---@field identifier        string The identifier for the survivor log within the namespace.
---@field token_name        string The localization token for the log's name.
---@field token_story       string The localization token for the log's story.
---@field token_id          string The localization token for the log's travel ID.
---@field token_departed    string The localization token for the log's departure location.
---@field token_arrival     string The localization token for the log's destination.
---@field sprite_icon_id    number The sprite ID for the grid character icon in the Logbook.
---@field sprite_id         number The sprite ID for the walk animation displayed beside the character name in the Logbook.
---@field portrait_id       number The sprite ID for the big portrait in the Logbook.
---@field portrait_index    number The subimage of `portrait_id` to use in the Logbook.
---@field stat_hp_base      number The base health to display.
---@field stat_hp_level     number The health gained per level up to display.
---@field stat_damage_base  number The base damage to display.
---@field stat_damage_level number The damage gained per level up to display.
---@field stat_regen_base   number The base health regeneration to display.
---@field stat_regen_level  number The health regeneration gained per level up to display.
---@field stat_armor_base   number The base armor to display.
---@field stat_armor_level  number The armor gained per level up to display.
---@field survivor_id       number The ID of the survivor this log is linked to.


-- ========== Enums ==========

SurvivorLog.Property = {
    NAMESPACE         = 0,
    IDENTIFIER        = 1,
    TOKEN_NAME        = 2,
    TOKEN_STORY       = 3,
    TOKEN_ID          = 4,
    TOKEN_DEPARTED    = 5,
    TOKEN_ARRIVAL     = 6,
    SPRITE_ICON_ID    = 7,
    SPRITE_ID         = 8,
    PORTRAIT_ID       = 9,
    PORTRAIT_INDEX    = 10,
    STAT_HP_BASE      = 11,
    STAT_HP_LEVEL     = 12,
    STAT_DAMAGE_BASE  = 13,
    STAT_DAMAGE_LEVEL = 14,
    STAT_REGEN_BASE   = 15,
    STAT_REGEN_LEVEL  = 16,
    STAT_ARMOR_BASE   = 17,
    STAT_ARMOR_LEVEL  = 18,
    SURVIVOR_ID       = 19,
}
local t = {}
for name, num in pairs(SurvivorLog.Property) do t[num] = name end
for i = 0, #t do SurvivorLog.Property[i] = t[i] end


-- ========== Static Methods ==========

--[[
Creates a new survivor log with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the survivor log.
---@return SurvivorLog
SurvivorLog.new = function(NAMESPACE, identifier)
    check_init_started("new")
    if not identifier then throw("No identifier provided", "new") end

    -- Return existing log if found
    local log = SurvivorLog.find(identifier, NAMESPACE, true)
    if log then return log end

    -- Create new
    log = SurvivorLog.wrap(gm.survivor_log_create(
        NAMESPACE,
        identifier
    ))

    return log
end

--[[
Creates a new survivor log using an survivor as a base, <br>
automatically populating the log's properties and <br>
setting the survivor's `log_id` property.

This should be called *after* setting the survivor's base and level stats.
]]
---@param survivor number | Survivor The survivor to use as a base.
---@return SurvivorLog
SurvivorLog.new_from_survivor = function(NAMESPACE, survivor)
    check_init_started("new_from_survivor")
    if not survivor then throw("No survivor provided", "new_from_survivor") end
    
    survivor = Survivor.wrap(survivor)
    if type(survivor.value) ~= "number" then throw("Invalid survivor '"..tostring(survivor.value).."'", "new_from_survivor") end

    -- Use existing log or create a new one
    local log = SurvivorLog.find(survivor.identifier, NAMESPACE, true)
             or SurvivorLog.new(NAMESPACE, survivor.identifier)

    -- Set sprite and icon IDs
    log.sprite_id      = survivor.sprite_title
    log.sprite_icon_id = survivor.sprite_portrait

    -- Set survivor ID
    log.survivor_id = survivor

    -- Set stats
    local stats_base = survivor:get_stats_base()
    if stats_base then
        log.stat_hp_base     = stats_base.health
        log.stat_damage_base = stats_base.damage
        log.stat_regen_base  = stats_base.regen
        log.stat_armor_base  = stats_base.armor
    end
    local stats_level = survivor:get_stats_level()
    if stats_level then
        log.stat_hp_level     = stats_level.health
        log.stat_damage_level = stats_level.damage
        log.stat_regen_level  = stats_level.regen
        log.stat_armor_level  = stats_level.armor
    end

    -- Set the log ID of the survivor
    survivor.log_id = log

    return log
end

--[[
Searches for the specified survivor log and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return SurvivorLog
SurvivorLog.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all survivor log in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>`SurvivorLog.Property.NAMESPACE` by default.
---@return table<number, SurvivorLog>
SurvivorLog.find_all = function(NAMESPACE, filter, property) end

--[[
Returns a survivor log wrapper containing the provided survivor log ID.
]]
---@param id number | SurvivorLog The survivor log to wrap.
---@return SurvivorLog
SurvivorLog.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class SurvivorLog
local methods = G.methods_content["SurvivorLog"]

--[[
Prints the survivor log's properties.
]]
methods.print = function(self) end