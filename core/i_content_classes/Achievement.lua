-- Achievement

---@class AchievementClass
Achievement = C["Achievement"]

local proxy              = P.proxy
local metatable          = W["Achievement"]
local find_table_wrapper = P.class_find_tables_wrapper["Achievement"]
local find_table_array   = P.class_find_tables_array["Achievement"]

local gm                 = gm  ---@type table<string, function>
local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap

G.skill_achievement_map = {} ---@type table<skill_id, achievement_id> Located in `Achievement.lua`.


-- ========== Annotations ==========

---@class Achievement
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field properties Array The array storing this achievement's properties.
---@field array Array Alias for .properties.

---@class Achievement
---@field namespace             string  The namespace the achievement is in.
---@field identifier            string  The identifier for the achievement within the namespace.
---@field token_name            string  The localization token for the achievement's name.
---@field token_desc            string  
---@field token_desc2           string  
---@field token_unlock_name     string  The localization token for the name of the associated survivor.
---@field unlock_kind           number  
---@field unlock_id             number  
---@field sprite_id             number  
---@field sprite_subimage       number  
---@field sprite_scale          number  
---@field sprite_scale_ingame   number  
---@field is_hidden             boolean 
---@field is_trial              boolean 
---@field is_server_authorative boolean 
---@field milestone_alt_unlock  unknown 
---@field milestone_survivor    unknown 
---@field progress              number  
---@field unlocked              unknown 
---@field parent_id             number  The ID of the parent achievement to list the achievement under in Logbook. <br>Used in vanilla for survivor skill unlocks. <br>-1 by default.
---@field progress_needed       number  The amount of progress required to unlock the achievement. <br>1 by default.
---@field death_reset           boolean If true, progress will be reset on death. <br>false by default.
---@field group                 number  The section to list under in Logbook. <br>0 - Challenge <br>1 - Characters <br>2 - Artifacts <br>0 by default.
---@field on_completed          number  The ID of the callback that runs when the achievement is unlocked. <br>The callback function should have no arguments.


-- ========== Enums ==========

Achievement.Property = {
    NAMESPACE             = 0,
    IDENTIFIER            = 1,
    TOKEN_NAME            = 2,
    TOKEN_DESC            = 3,
    TOKEN_DESC2           = 4,
    TOKEN_UNLOCK_NAME     = 5,
    UNLOCK_KIND           = 6,
    UNLOCK_ID             = 7,
    SPRITE_ID             = 8,
    SPRITE_SUBIMAGE       = 9,
    SPRITE_SCALE          = 10,
    SPRITE_SCALE_INGAME   = 11,
    IS_HIDDEN             = 12,
    IS_TRIAL              = 13,
    IS_SERVER_AUTHORATIVE = 14,
    MILESTONE_ALT_UNLOCK  = 15,
    MILESTONE_SURVIVOR    = 16,
    PROGRESS              = 17,
    UNLOCKED              = 18,
    PARENT_ID             = 19,
    PROGRESS_NEEDED       = 20,
    DEATH_RESET           = 21,
    GROUP                 = 22,
    ON_COMPLETED          = 23,
}
local t = {}
for name, num in pairs(Achievement.Property) do t[num] = name end
for i = 0, #t do Achievement.Property[i] = t[i] end

Achievement.Kind = {
    NONE                        = 0,
    MODE                        = 1,
    SURVIVOR                    = 2,
    ITEM                        = 3,
    EQUIPMENT                   = 4,
    ARTIFACT                    = 5,
    SURVIVOR_LOADOUT_UNLOCKABLE = 6,
}

Achievement.Group = {
    CHALLENGE = 0,
    CHARACTER = 1,
    ARTIFACT  = 2,
}


-- ========== Internal ==========

local function populate_skill_achievement_map()
    -- Loop through unlockables array and associate
    -- with the first instance of the skill found
    -- (Will have to ignore if the skill appears anywhere else)
    local unlockables_array = Global.survivor_loadout_unlockables
    for i, unlockable in ipairs(unlockables_array) do
        local skill_id = unlockable.skill_id
        if skill_id then
            G.skill_achievement_map[skill_id] = unlockable.achievement_id
        end
    end
end
run_on_initialize(populate_skill_achievement_map)


-- ========== Static Methods ==========

--[[
Creates a new achievement with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the achievement.
---@return Achievement
Achievement.new = function(NAMESPACE, identifier)
    check_init_started("new")
    if not identifier then throw("No identifier provided", "new") end

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

--[[
Searches for the specified achievement and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return Achievement
Achievement.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all achievement in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>Achievement.Property.NAMESPACE by default.
---@return table<number, Achievement>
Achievement.find_all = function(NAMESPACE, filter, property) end

--[[
Returns an achievement wrapper containing the provided achievement ID.
]]
---@param id number | Achievement The achievement to wrap.
---@return Achievement
Achievement.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class Achievement
local methods = G.methods_content["Achievement"]

--[[
Associates the achievement with an artifact.
]]
---@param artifact number | Artifact The artifact to associate with.
methods.set_unlock_artifact = function(self, artifact)
    if proxy[self] < 0 then throw("Achievement does not exist") end
    if not artifact then throw("artifact is nil") end
    gm.achievement_set_unlock_artifact(proxy[self], unwrap(artifact))
end

--[[
Associates the achievement with an equipment.
]]
---@param equipment number | Equipment The equipment to associate with.
methods.set_unlock_equipment = function(self, equipment)
    if proxy[self] < 0 then throw("Achievement does not exist") end
    if not equipment then throw("equipment is nil") end
    gm.achievement_set_unlock_equipment(proxy[self], unwrap(equipment))
end

--[[
Associates the achievement with an item.
]]
---@param item number | Item The item to associate with.
methods.set_unlock_item = function(self, item)
    if proxy[self] < 0 then throw("Achievement does not exist") end
    if not item then throw("item is nil") end
    gm.achievement_set_unlock_item(proxy[self], unwrap(item))
end

--[[
Associates the achievement with a skill.

More specifically, it associates with all `SurvivorSkillLoadoutUnlockable`s <br>
that are of the skill, so the **skill must be added to the survivor first**.
]]
---@param skill number | Skill The skill to associate with.
methods.set_unlock_skill = function(self, skill)
    if proxy[self] < 0 then throw("Achievement does not exist") end
    if not skill then throw("skill is nil") end
    local skill_id = unwrap(skill)
    
    -- Loop through unlockables array and associate
    -- with the first instance of the skill found
    -- (Will have to ignore if the skill appears anywhere else)
    local unlockables_array = Global.survivor_loadout_unlockables
    for i, unlockable in ipairs(unlockables_array) do
        if unlockable.skill_id == skill_id then
            gm.achievement_set_unlock_survivor_loadout_unlockable(proxy[self], unlockable.index)
            G.skill_achievement_map[skill_id] = proxy[self]

            -- Game currently does not set this due to a mistake
            -- (`scr_achievement` line 602)
            unlockable.achievement_id = proxy[self]
            break
        end
    end
end

--[[
Associates the achievement with a skin.

**The skin must be added to the survivor first.**
]]
---@param survivor number | Survivor The survivor the skin belongs to.
---@param identifier string The identifier of the skin.
methods.set_unlock_skin = function(self, survivor, identifier)
    if proxy[self] < 0 then throw("Achievement does not exist") end
    if not survivor    then throw("survivor is nil") end
    if not identifier  then throw("identifier is nil") end

    survivor = Survivor.wrap(survivor)
    
    -- Loop through survivor's skin_family
    -- and associate with the skin if found
    local skin_family = survivor.skin_family.elements
    for i, unlockable in ipairs(skin_family) do
        if unlockable.identifier == identifier then
            gm.achievement_set_unlock_survivor_loadout_unlockable(proxy[self], unlockable.index)
            self.sprite_id = unlockable.achievement_sprite or gm.constants.sDummySprite
            break
        end
    end
end

--[[
Associates the achievement with a survivor.
]]
---@param survivor number | Survivor The survivor to associate with.
methods.set_unlock_survivor = function(self, survivor)
    if proxy[self] < 0 then throw("Achievement does not exist") end
    if not survivor then throw("survivor is nil") end
    gm.achievement_set_unlock_survivor(proxy[self], unwrap(survivor))
end

--[[
Returns `true` if the achievement is unlocked for this player.
]]
---@return boolean
methods.is_unlocked = function(self)
    return gm.achievement_is_unlocked_or_null(proxy[self])
end

--[[
Returns `true` if the achievement is unlocked for any player in multiplayer.
]]
---@return boolean
methods.is_unlocked_any = function(self)
    return gm.achievement_is_unlocked_or_null_any_player(proxy[self])
end

--[[
Adds progress towards unlocking the achievement. <br>
The achievement will be unlocked once progress reaches `progress_needed`.
]]
---@param amount? number The amount of progress to add. <br>`1` by default.
methods.add_progress = function(self, amount)
    if proxy[self] < 0 then throw("Achievement does not exist") end
    gm.achievement_add_progress(proxy[self], amount or 1)
end

--[[
Prints the achievement's properties.
]]
methods.print = function(self) end