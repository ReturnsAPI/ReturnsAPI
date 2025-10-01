-- Survivor

local name_rapi = class_name_g2r["class_survivor"]
Survivor = __class[name_rapi]

run_once(function()
    __survivor_data = {}    -- Stores some data for survivors (e.g., `on_init` callback for setting base stats)
end)



-- ========== Enums ==========

--@section Enums

--@enum
--@name Property
--[[
NAMESPACE               0
IDENTIFIER              1
TOKEN_NAME              2
TOKEN_NAME_UPPER        3
TOKEN_DESCRIPTION       4
TOKEN_END_QUOTE         5
SKILL_FAMILY_Z          6
SKILL_FAMILY_X          7
SKILL_FAMILY_C          8
SKILL_FAMILY_V          9
SKIN_FAMILY             10
ALL_LOADOUT_FAMILIES    11
ALL_SKILL_FAMILIES      12
SPRITE_LOADOUT          13
SPRITE_TITLE            14
SPRITE_IDLE             15
SPRITE_PORTRAIT         16
SPRITE_PORTRAIT_SMALL   17
SPRITE_PALETTE          18
SPRITE_PORTRAIT_PALETTE 19
SPRITE_LOADOUT_PALETTE  20
SPRITE_CREDITS          21
PRIMARY_COLOR           22
SELECT_SOUND_ID         23
LOG_ID                  24
ACHIEVEMENT_ID          25
MILESTONE_KILLS_1       26
MILESTONE_ITEMS_1       27
MILESTONE_STAGES_1      28
ON_INIT                 29
ON_STEP                 30
ON_REMOVE               31
IS_SECRET               32
CAPE_OFFSET             33
]]



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The survivor ID being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.

<br>

Property | Type | Description
| - | - | -
`namespace`                 | string    | The namespace the survivor is in.
`identifier`                | string    | The identifier for the survivor within the namespace.
`token_name`                | string    | 
`token_name_upper`          | string    | 
`token_description`         | string    | 
`token_end_quote`           | string    | 
`skill_family_z`            |           | 
`skill_family_x`            |           | 
`skill_family_c`            |           | 
`skill_family_v`            |           | 
`skin_family`               |           | 
`all_loadout_families`      |           | 
`all_skill_families`        |           | 
`sprite_loadout`            | sprite    | 
`sprite_title`              | sprite    | 
`sprite_idle`               | sprite    | 
`sprite_portrait`           | sprite    | 
`sprite_portrait_small`     | sprite    | 
`sprite_palette`            |           | 
`sprite_portrait_palette`   |           | 
`sprite_loadout_palette`    |           | 
`sprite_credits`            | sprite    | 
`primary_color`             | color     | 
`select_sound_id`           | sound     | 
`log_id`                    | number    | 
`achievement_id`            | number    | 
`milestone_kills_1`         |           | 
`milestone_items_1`         |           | 
`milestone_stages_1`        |           | 
`on_init`                   | number    | The ID of the callback that runs when an instance of the survivor is created. <br>The callback function should have the argument `actor`.
`on_step`                   | number    | The ID of the callback that runs when . <br>The callback function should have the arguments `(TODO)`.
`on_remove`                 | number    | The ID of the callback that runs when . <br>The callback function should have the arguments `(TODO)`.
`is_secret`                 | bool      | 
`cape_offset`               | Array     | Stores the drawing offset for Prophet's Cape. <br>Array order: `x_offset, y_offset, x_offset_climbing, y_offset_climbing`
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return   Survivor
--@param    identifier  | string    | The identifier for the survivor.
--[[
Creates a new survivor with the given identifier if it does not already exist,
or returns the existing one if it does.

The survivor will have a placeholder skill created for each slot.
You can call @link {`survivor:get_skills( slot )[1]` | Survivor#get_skills} to access them.
]]
Survivor.new = function(NAMESPACE, identifier)
    Initialize.internal.check_if_started()
    if not identifier then log.error("No identifier provided", 2) end

    -- Return existing survivor if found
    local survivor = Survivor.find(identifier, NAMESPACE)
    if survivor then return survivor end

    -- Create new
    survivor = Survivor.wrap(gm.survivor_create(
        NAMESPACE,
        identifier
    ))

    return survivor
end


--@static
--@name         find
--@return       Survivor or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified survivor and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]


--@static
--@name         find_all
--@return       table
--@param        filter      |           | The filter to search by.
--@optional     property    | number    | The property to check. <br>@link {`Survivor.Property.NAMESPACE` | Survivor#Property} by default.
--[[
Returns a table of survivors matching the specified filter and property.

**NOTE:** Filtering by a non-namespace property is *very slow*!
Try not to do that too much.
]]


--@static
--@name         wrap
--@return       Survivor
--@param        id          | number    | The survivor ID to wrap.
--[[
Returns an Survivor wrapper containing the provided survivor ID.
]]



-- ========== Instance Methods ==========

--@section Instance Methods

Util.table_append(methods_class_array[name_rapi], {

    --@instance
    --@name         print_properties
    --[[
    Prints the survivor's properties.
    ]]


    --@instance
    --@param        slot        | number    | The @link {slot | Skill#slot} to add to.
    --@param        skill       | Skill     | The skill to add.
    --[[
    Adds a skill to the specified slot.
    ]]
    add_skill = function(self, slot, skill)
        if type(slot) ~= "number"   then log.error("add_skill: Invalid slot argument", 2) end
        if not skill                then log.error("add_skill: skill not provided", 2) end

        local array = self.array:get(Survivor.Property.SKILL_FAMILY_Z + slot).elements
        array:push(
            Struct.new(
                gm.constants.SurvivorSkillLoadoutUnlockable,
                Wrap.unwrap(skill)
            )
        )
    end,


    --@instance
    --@param        slot        | number    | The @link {slot | Skill#slot} to remove from.
    --@param        skill       | Skill     | The skill to remove.
    --[[
    Removes a skill from the specified slot.
    ]]
    remove_skill = function(self, slot, skill)
        if type(slot) ~= "number"   then log.error("remove_skill: Invalid slot argument", 2) end
        if not skill                then log.error("remove_skill: skill not provided", 2) end

        skill = Wrap.unwrap(skill)

        local array = self.array:get(Survivor.Property.SKILL_FAMILY_Z + slot).elements
        for i, skill_loadout_unlockable in ipairs(array) do
            if skill_loadout_unlockable.skill_id == skill then
                array:delete(i)
                return
            end
        end
    end,


    --@instance
    --@param        slot        | number    | The @link {slot | Skill#slot} to remove from.
    --@param        index       | number    | The index at which to remove, starting at `1`.
    --[[
    Removes the skill at the given index from the specified slot.
    ]]
    remove_skill_at_index = function(self, slot, index)
        if type(slot) ~= "number"   then log.error("remove_skill: Invalid slot argument", 2) end
        if type(index) ~= "number"  then log.error("remove_skill: Invalid index argument", 2) end

        skill = Wrap.unwrap(skill)

        local array = self.array:get(Survivor.Property.SKILL_FAMILY_Z + slot).elements
        array:delete(index)
    end,


    --@instance
    --@return       table
    --@param        slot        | number    | The @link {slot | Skill#slot} to get from.
    --[[
    Returns a table containing a list of Skills belonging to the specified slot.
    *Technical:* Returns a table copy of `survivor.skill_family_<slot>.elements`.
    ]]
    get_skills = function(self, slot)
        if type(slot) ~= "number" then log.error("get_skills: Invalid slot argument", 2) end

        local t = {}
        local array = self.array:get(Survivor.Property.SKILL_FAMILY_Z + slot).elements
        for _, skill_loadout_unlockable in ipairs(array) do
            table.insert(t, Skill.wrap(skill_loadout_unlockable.skill_id))
        end
        return t
    end

})
