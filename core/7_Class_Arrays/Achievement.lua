-- Achievement

skill_achievement_map = {}



-- ========== Enums ==========

--@section Enums

--@enum
--@name Property
--[[
NAMESPACE               0
IDENTIFIER              1
TOKEN_NAME              2
TOKEN_DESC              3
TOKEN_DESC2             4
TOKEN_UNLOCK_NAME       5
UNLOCK_KIND             6
UNLOCK_ID               7
SPRITE_ID               8
SPRITE_SUBIMAGE         9
SPRITE_SCALE            10
SPRITE_SCALE_INGAME     11
IS_HIDDEN               12
IS_TRIAL                13
IS_SERVER_AUTHORATIVE   14
MILESTONE_ALT_UNLOCK    15
MILESTONE_SURVIVOR      16
PROGRESS                17
UNLOCKED                18
PARENT_ID               19
PROGRESS_NEEDED         20
DEATH_RESET             21
GROUP                   22
ON_COMPLETED            23
]]


--@enum
Achievement.Kind = {
    NONE                        = 0,
    MODE                        = 1,
    SURVIVOR                    = 2,
    ITEM                        = 3,
    EQUIPMENT                   = 4,
    ARTIFACT                    = 5,
    SURVIVOR_LOADOUT_UNLOCKABLE = 6 
}


--@enum
Achievement.Group = {
    CHALLENGE   = 0,
    CHARACTER   = 1,
    ARTIFACT    = 2
}



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The achievement ID being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.

<br>

Property | Type | Description
| - | - | -
`namespace`             | string    | The namespace the achievement is in.
`identifier`            | string    | The identifier for the achievement within the namespace.
`token_name`            | string    | The localization token for the achievement's name.
`token_desc`            | string    | 
`token_desc2`           | string    | 
`token_unlock_name`     | string    | The localization token for the name of the associated content.
`unlock_kind`           | number    | 
`unlock_id`             | number    | 
`sprite_id`             | number    | 
`sprite_subimage`       | number    | 
`sprite_scale`          | number    | 
`sprite_scale_ingame`   | number    | 
`is_hidden`             | bool      | 
`is_trial`              | bool      | 
`is_server_authorative` | bool      | 
`milestone_alt_unlock`  |           | 
`milestone_survivor`    |           | 
`progress`              | number    | 
`unlocked`              |           | 
`parent_id`             | number    | The ID of the parent achievement to list the achievement under in Logbook. <br>Used in vanilla for survivor skill unlocks. <br>`-1` by default.
`progress_needed`       | number    | The amount of progress required to unlock the achievement. <br>`1` by default.
`death_reset`           | bool      | If `true`, progress will be reset on death. <br>`false` by default.
`group`                 | number    | The section to list under in Logbook. <br>`0` - Challenge <br>`1` - Characters <br>`2` - Artifacts <br>`0` by default.
`on_completed`          | number    | The ID of the callback that runs when the achievement is unlocked. <br>The callback function should have no arguments.
]]



-- ========== Internal ==========

Achievement.internal.populate_skill_achievement_map = function()
    -- Loop through unlockables array and associate
    -- with the first instance of the skill found
    -- (Will have to ignore if the skill appears anywhere else)
    local unlockables_array = Global.survivor_loadout_unlockables
    for i, unlockable in ipairs(unlockables_array) do
        local skill_id = unlockable.skill_id
        if skill_id then
            skill_achievement_map[skill_id] = unlockable.achievement_id
        end
    end
end
table.insert(_rapi_initialize, Achievement.internal.populate_skill_achievement_map)



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return   Achievement
--@param    identifier  | string    | The identifier for the achievement.
--[[
Creates a new achievement with the given identifier if it does not already exist,
or returns the existing one if it does.

The achievement can be associated with a *single*
piece of content using the `set_unlock_*` instance methods below.
]]
Achievement.new = function(NAMESPACE, identifier)
    Initialize.internal.check_if_started("Achievement.new")
    if not identifier then log.error("Achievement.new: No identifier provided", 2) end

    -- Return existing achievement if found
    local achievement = Achievement.find(identifier, NAMESPACE, true)
    if achievement then return achievement end

    -- Create new
    achievement = Achievement.wrap(gm.achievement_create(
        NAMESPACE,
        identifier
    ))

    return achievement
end


--@static
--@name         find
--@return       Achievement or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified achievement and returns it.

--@findinfo
]]


--@static
--@name         find_all
--@return       table
--@param        filter      |           | The filter to search by.
--@optional     property    | number    | The property to check. <br>@link {`Achievement.Property.NAMESPACE` | Achievement#Property} by default.
--[[
Returns a table of achievements matching the specified filter and property.

**Note on namespace filter:**
--@findinfo

**NOTE:** Filtering by a non-namespace property is *very slow*!
Try not to do that too much.
]]


--@static
--@name         wrap
--@return       Achievement
--@param        id          | number    | The achievement ID to wrap.
--[[
Returns an Achievement wrapper containing the provided achievement ID.
]]



-- ========== Instance Methods ==========

--@section Instance Methods

Util.table_append(methods_content_class["Achievement"], {

    --@instance
    --@name         print
    --[[
    Prints the achievement's properties.
    ]]


    --@instance
    --@param        artifact   | Artifact   | The artifact to associate with.
    --[[
    Associates the achievement with an artifact.
    ]]
    set_unlock_artifact = function(self, content)
        if self.value < 0 then log.error("set_unlock_artifact: Achievement does not exist", 2) end
        if not content then log.error("set_unlock_artifact: artifact is not provided", 2) end
        gm.achievement_set_unlock_artifact(self.value, Wrap.unwrap(content))
    end,


    --@instance
    --@param        equipment   | Equipment | The equipment to associate with.
    --[[
    Associates the achievement with an equipment.
    ]]
    set_unlock_equipment = function(self, content)
        if self.value < 0 then log.error("set_unlock_equipment: Achievement does not exist", 2) end
        if not content then log.error("set_unlock_equipment: equipment is not provided", 2) end
        gm.achievement_set_unlock_equipment(self.value, Wrap.unwrap(content))
    end,


    --@instance
    --@param        item        | Item      | The item to associate with.
    --[[
    Associates the achievement with an item.
    ]]
    set_unlock_item = function(self, content)
        if self.value < 0 then log.error("set_unlock_item: Achievement does not exist", 2) end
        if not content then log.error("set_unlock_item: item is not provided", 2) end
        gm.achievement_set_unlock_item(self.value, Wrap.unwrap(content))
    end,


    --@instance
    --@param        skill       | Skill     | The skill to associate with.
    --[[
    Associates the achievement with a skill.

    More specifically, it associates with all `SurvivorSkillLoadoutUnlockable`s
    that are of the skill, so the **skill must be added to the survivor first**.
    ]]
    set_unlock_skill = function(self, content)
        if self.value < 0 then log.error("set_unlock_skill: Achievement does not exist", 2) end
        if not content then log.error("set_unlock_skill: skill is not provided", 2) end
        local skill_id = Wrap.unwrap(content)
        
        -- Loop through unlockables array and associate
        -- with the first instance of the skill found
        -- (Will have to ignore if the skill appears anywhere else)
        local unlockables_array = Global.survivor_loadout_unlockables
        for i, unlockable in ipairs(unlockables_array) do
            if unlockable.skill_id == skill_id then
                gm.achievement_set_unlock_survivor_loadout_unlockable(self.value, unlockable.index)
                skill_achievement_map[skill_id] = self.value

                -- Game currently does not set this due to a mistake
                -- (`scr_achievement` line 602)
                unlockable.achievement_id = self.value
                break
            end
        end
    end,


    --@instance
    --@param        skin        | ActorSkin | The skin to associate with.
    --[[
    (TODO)

    Associates the achievement with a skin.

    More specifically, it associates with all `SurvivorSkinLoadoutUnlockable`s
    that are of the skin, so the **skin must be added to the survivor first**.
    ]]
    set_unlock_skin = function(self, content)
        -- Similar to set_unlock_skill
    end,


    --@instance
    --@param        survivor    | Survivor  | The survivor to associate with.
    --[[
    Associates the achievement with a survivor.
    ]]
    set_unlock_survivor = function(self, content)
        if self.value < 0 then log.error("set_unlock_survivor: Achievement does not exist", 2) end
        if not content then log.error("set_unlock_survivor: survivor is not provided", 2) end
        gm.achievement_set_unlock_survivor(self.value, Wrap.unwrap(content))
    end,


    --@instance
    --@return       bool
    --[[
    Returns `true` if the achievement is unlocked for this player.
    ]]
    is_unlocked = function(self)
        return gm.achievement_is_unlocked_or_null(self.value)
    end,


    --@instance
    --@return       bool
    --[[
    Returns `true` if the achievement is unlocked for any player in multiplayer.
    ]]
    is_unlocked_any = function(self)
        return gm.achievement_is_unlocked_or_null_any_player(self.value)
    end,


    --@instance
    --@param        amount      | number    | The amount of progress to add. <br>`1` by default.
    --[[
    Adds progress towards unlocking the achievement.
    The achievement will be unlocked once progress reaches `progress_needed`.
    ]]
    add_progress = function(self, amount)
        if self.value < 0 then log.error("add_progress: Achievement does not exist", 2) end
        gm.achievement_add_progress(self.value, amount or 1)
    end

})
