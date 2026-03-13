-- Skill

--[[
Not to be confused with @link {ActorSkill | ActorSkill}.
]]



-- ========== Enums ==========

--@section Enums

--@enum
--@name Property
--[[
NAMESPACE                       0
IDENTIFIER                      1
TOKEN_NAME                      2
TOKEN_DESCRIPTION               3
SPRITE                          4
SUBIMAGE                        5
COOLDOWN                        6
DAMAGE                          7
MAX_STOCK                       8
START_WITH_STOCK                9
AUTO_RESTOCK                    10
REQUIRED_STOCK                  11
REQUIRE_KEY_PRESS               12
ALLOW_BUFFERED_INPUT            13
USE_DELAY                       14
ANIMATION                       15
IS_UTILITY                      16
IS_PRIMARY                      17
REQUIRED_INTERRUPT_PRIORITY     18
HOLD_FACING_DIRECTION           19
OVERRIDE_STRAFE_DIRECTION       20
IGNORE_AIM_DIRECTION            21
DISABLE_AIM_STALL               22
DOES_CHANGE_ACTIVITY_STATE      23
ON_CAN_ACTIVATE                 24
ON_ACTIVATE                     25
ON_STEP                         26
ON_EQUIPPED                     27
ON_UNEQUIPPED                   28
UPGRADE_SKILL                   29
]]


--@enum
Skill.Slot = {
    PRIMARY     = 0,
    SECONDARY   = 1,
    UTILITY     = 2,
    SPECIAL     = 3
}


--@enum
Skill.OverridePriority = {
    UPGRADE     = 0,
    BOOSTED     = 1,
    RELOAD      = 2,
    CANCEL      = 3
}



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The skill ID being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.

<br>

Property | Type | Description
| - | - | -
`namespace`                     | string    | The namespace the skill is in.
`identifier`                    | string    | The identifier for the skill within the namespace.
`token_name`                    | string    | 
`token_description`             | string    | 
`sprite`                        | sprite    |
`subimage`                      | number    | 
`cooldown`                      | number    | The base cooldown of the skill (in frames).
`damage`                        | number    | The damage of the skill; `1` is 100% damage. <br>Does nothing if the skill/states themselves do not refer to it. <br>Can also be gotten using `GM.skill_get_damage( skill )`.
`max_stock`                     | number    | 
`start_with_stock`              | bool      | If `true`, this skill will start with `max_stock` instead of `0`.
`auto_restock`                  |           | 
`required_stock`                |           | 
`require_key_press`             | bool      | 
`allow_buffered_input`          |           | 
`use_delay`                     |           | 
`animation`                     |           | 
`is_utility`                    | bool      | 
`is_primary`                    | bool      | 
`required_interrupt_priority`   |           | 
`hold_facing_direction`         |           | 
`override_strafe_direction`     |           | 
`ignore_aim_direction`          | bool      | 
`disable_aim_stall`             | bool      | 
`does_change_activity_state`    |           | 
`on_can_activate`               | number    | The ID of the callback that runs when . <br>The callback function should have the arguments `(TODO)`.
`on_activate`                   | number    | The ID of the callback that runs when the skill is used. <br>The callback function should have the arguments `actor, skill, slot`.
`on_step`                       | number    | The ID of the callback that runs every frame while slotted. <br>The callback function should have the arguments `actor, skill, slot`.
`on_equipped`                   | number    | The ID of the callback that runs when the skill is slotted. <br>The callback function should have the arguments `actor, skill, slot`.
`on_unequipped`                 | number    | The ID of the callback that runs when the skill is unslotted. <br>The callback function should have the arguments `actor, skill, slot`.
`upgrade_skill`                 | number    | The ID of the skill to upgrade to when picking up Ancient Scepter.
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return   Skill
--@param    identifier  | string    | The identifier for the skill.
--[[
Creates a new skill with the given identifier if it does not already exist,
or returns the existing one if it does.
]]
Skill.new = function(NAMESPACE, identifier)
    Initialize.internal.check_if_started("Skill.new")
    if not identifier then log.error("Skill.new: No identifier provided", 2) end

    -- Return existing skill if found
    local skill = Skill.find(identifier, NAMESPACE, true)
    if skill then return skill end

    -- Create new
    skill = Skill.wrap(gm.skill_create(
        NAMESPACE,
        identifier
    ))

    return skill
end


--@static
--@name         find
--@return       Skill or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified skill and returns it.

--@findinfo
]]


--@static
--@name         find_all
--@return       table
--@param        filter      |           | The filter to search by.
--@optional     property    | number    | The property to check. <br>@link {`Skill.Property.NAMESPACE` | Skill#Property} by default.
--[[
Returns a table of skills matching the specified filter and property.

**Note on namespace filter:**
--@findinfo

**NOTE:** Filtering by a non-namespace property is *very slow*!
Try not to do that too much.
]]


--@static
--@name         wrap
--@return       Skill
--@param        id          | number    | The skill ID to wrap.
--[[
Returns an Skill wrapper containing the provided skill ID.
]]



-- ========== Instance Methods ==========

--@section Instance Methods

Util.table_append(methods_content_class["Skill"], {

    --@instance
    --@name         print
    --[[
    Prints the skill's properties.
    ]]


    --@instance
    --@return       Achievement
    --[[
    Returns the associated @link {Achievement | Achievement} if it exists,
    or an invalid Achievement if it does not.
    ]]
    get_achievement = function(self)
        return Achievement.wrap(skill_achievement_map[self.value] or -1)
    end

})
