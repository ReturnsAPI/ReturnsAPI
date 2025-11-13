-- SurvivorLog

local name_rapi = class_name_g2r["class_survivor_log"]
SurvivorLog = __class[name_rapi]



-- ========== Enums ==========

--@section Enums

--@enum
--@name Property
--[[
NAMESPACE           0
IDENTIFIER          1
TOKEN_NAME          2
TOKEN_STORY         3
TOKEN_ID            4
TOKEN_DEPARTED      5
TOKEN_ARRIVAL       6
SPRITE_ICON_ID      7
SPRITE_ID           8
PORTRAIT_ID         9
PORTRAIT_INDEX      10
STAT_HP_BASE        11
STAT_HP_LEVEL       12
STAT_DAMAGE_BASE    13
STAT_DAMAGE_LEVEL   14
STAT_REGEN_BASE     15
STAT_REGEN_LEVEL    16
STAT_ARMOR_BASE     17
STAT_ARMOR_LEVEL    18
SURVIVOR_ID         19
]]



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The survivor log ID being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.

<br>

Property | Type | Description
| - | - | -
`namespace`                     | string    | The namespace the survivor log is in.
`identifier`                    | string    | The identifier for the survivor log within the namespace.
`token_name`                    | string    | The localization token for the log's name.
`token_story`                   | string    | The localization token for the log's story.
`token_id`                      | string    | The localization token for the log's travel ID.
`token_departed`                | string    | The localization token for the log's departure location.
`token_arrival`                 | string    | The localization token for the log's destination.
`sprite_icon_id`                | sprite    | The grid character icon in the Logbook.
`sprite_id`                     | sprite    | The walk animation displayed beside the character name in the Logbook.
`portrait_id`                   | sprite    | The big portrait in the Logbook.
`portrait_index`                | number    | The subimage of `portrait_id` to use in the Logbook.
`stat_hp_base`                  | number    | The base health to display.
`stat_hp_level`                 | number    | The health gained per level up to display.
`stat_damage_base`              | number    | The base damage to display.
`stat_damage_level`             | number    | The damage gained per level up to display.
`stat_regen_base`               | number    | The base health regeneration to display.
`stat_regen_level`              | number    | The health regeneration gained per level up to display.
`stat_armor_base`               | number    | The base armor to display.
`stat_armor_level`              | number    | The armor gained per level up to display.
`survivor_id`                   | number    | The ID of the survivor this log is linked to.
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return   SurvivorLog
--@param    identifier  | string    | The identifier for the survivor log.
--[[
Creates a new survivor log with the given identifier if it does not already exist,
or returns the existing one if it does.
]]
SurvivorLog.new = function(NAMESPACE, identifier)
    Initialize.internal.check_if_started("SurvivorLog.new")
    if not identifier then log.error("SurvivorLog.new: No identifier provided", 2) end

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


--@static
--@return   SurvivorLog
--@param    survivor        | Survivor  | The survivor to use as a base.
--[[
Creates a new survivor log using an survivor as a base,
automatically populating the log's properties and
setting the survivor's `log_id` property.

This should be called *after* setting the survivor's base and level stats.
]]
SurvivorLog.new_from_survivor = function(NAMESPACE, survivor)
    Initialize.internal.check_if_started("SurvivorLog.new_from_survivor")
    
    if not survivor then log.error("SurvivorLog.new_from_survivor: No survivor provided", 2) end
    survivor = Survivor.wrap(survivor)
    
    if type(survivor.value) ~= "number" then log.error("SurvivorLog.new_from_survivor: Invalid survivor", 2) end

    -- Use existing log or create a new one
    local log = SurvivorLog.find(survivor.identifier, NAMESPACE, true)
             or SurvivorLog.new(NAMESPACE, survivor.identifier)

    -- Set sprite and icon IDs
    log.sprite_id       = survivor.sprite_title
    log.sprite_icon_id  = survivor.sprite_portrait

    -- Set survivor ID
    log.survivor_id     = survivor

    -- Set stats
    local stats_base = survivor:get_stats_base()
    if stats_base then
        log.stat_hp_base        = stats_base.health
        log.stat_damage_base    = stats_base.damage
        log.stat_regen_base     = stats_base.regen
        log.stat_armor_base     = stats_base.armor
    end
    local stats_level = survivor:get_stats_level()
    if stats_level then
        log.stat_hp_level       = stats_level.health
        log.stat_damage_level   = stats_level.damage
        log.stat_regen_level    = stats_level.regen
        log.stat_armor_level    = stats_level.armor
    end

    -- Set the log ID of the survivor
    survivor.log_id = log

    return log
end


--@static
--@name         find
--@return       SurvivorLog or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified survivor log and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]


--@static
--@name         find_all
--@return       table
--@param        filter      |           | The filter to search by.
--@optional     property    | number    | The property to check. <br>@link {`SurvivorLog.Property.NAMESPACE` | SurvivorLog#Property} by default.
--[[
Returns a table of monster logs matching the specified filter and property.

**NOTE:** Filtering by a non-namespace property is *very slow*!
Try not to do that too much.
]]


--@static
--@name         wrap
--@return       SurvivorLog
--@param        id          | number    | The survivor log ID to wrap.
--[[
Returns an SurvivorLog wrapper containing the provided survivor log ID.
]]



-- ========== Instance Methods ==========

--@section Instance Methods

Util.table_append(methods_class_array[name_rapi], {

    --@instance
    --@name         print_properties
    --[[
    Prints the survivor log's properties.
    ]]

})
