-- Survivor

local name_rapi = class_name_g2r["class_survivor"]
Survivor = __class[name_rapi]

run_once(function()
    __survivor_data = {}    -- Stores some data for survivors
    __skin_default_counter = 0
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


--@enum
Survivor.Class = {
    COMMANDO    = 0,
    HUNTRESS    = 1,
    ENFORCER    = 2,
    BANDIT      = 3,
    HAND        = 4,
    ENGINEER    = 5,
    MINER       = 6,
    SNIPER      = 7,
    ACRID       = 8,
    MERCENARY   = 9,
    LOADER      = 10,
    CHEF        = 11,
    PILOT       = 12,
    ARTIFICER   = 13,
    DRIFTER     = 14,
    ROBOMANDO   = 15
}


--@constants
--[[
CUSTOM_START    16
]]
Survivor.CUSTOM_START = 16



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
`sprite_palette`            | sprite    | **This should not be manually set.**
`sprite_portrait_palette`   | sprite    | Unused in vanilla, but used by ReturnsAPI. **This should not be manually set.**
`sprite_loadout_palette`    | sprite    | Unused in vanilla, but used by ReturnsAPI. **This should not be manually set.**
`sprite_credits`            | sprite    | 
`primary_color`             | color     | 
`select_sound_id`           | sound     | 
`log_id`                    | number    | 
`achievement_id`            | number    | 
`milestone_kills_1`         |           | 
`milestone_items_1`         |           | 
`milestone_stages_1`        |           | 
`on_init`                   | number    | The ID of the callback that runs when an instance of the survivor is created. <br>The callback function should have the argument `actor`.
`on_step`                   | number    | The ID of the callback that runs when (TODO). <br>The callback function should have the arguments `(TODO)`.
`on_remove`                 | number    | The ID of the callback that runs when (TODO). <br>The callback function should have the arguments `(TODO)`.
`is_secret`                 | bool      | 
`cape_offset`               | Array     | Stores the drawing offset for Prophet's Cape. <br>Array order: `x_offset, y_offset, x_offset_climbing, y_offset_climbing`
]]



-- ========== Internal ==========

Survivor.internal.initialize = function()
    -- Add correct palettes
    for _, dir in ipairs{
        path.combine(PATH, "core/sprites/portrait_palettes"),
        path.combine(PATH, "core/sprites/loadout_palettes")
    } do
        local files = path.get_files(dir)
        for _, filepath in ipairs(files) do
            local identifier = path.stem(path.filename(filepath))
            Sprite.new(RAPI_NAMESPACE, identifier, filepath)
        end
    end

    -- Add existing vanilla palette sprites to default skin (SurvivorSkillLoadoutUnlockable)
    -- Judgement skin should be separated and added to the last alt skin
    for i = 0, Survivor.CUSTOM_START - 1 do
        local survivor = Survivor.wrap(i)
        local skin_family = survivor.skin_family.elements

        -- Vanilla resources (fallback)
        local name = string.upper(survivor.identifier:sub(1, 1))..survivor.identifier:sub(2, -1)
        if survivor.identifier == "hand"     then name = "HAND" end
        if survivor.identifier == "engineer" then name = "Engi" end

        local name2 = name
        if survivor.identifier == "mercenary" then name2 = "Merc" end

        local palettes = {
            gm.constants["s"..name.."Palette"],
            gm.constants["s"..name2.."PortraitPalette"],
            gm.constants["sSelect"..name.."Palette"]
        }

        -- RAPI-added resources
        local palette   = Sprite.find(survivor.identifier.."Palette", RAPI_NAMESPACE, true)
        local portrait  = Sprite.find(survivor.identifier.."PalettePortrait", RAPI_NAMESPACE, true)
        local loadout   = Sprite.find(survivor.identifier.."PaletteLoadout", RAPI_NAMESPACE, true)
        if palette  then palettes[1] = palette.value end
        if portrait then palettes[2] = portrait.value end
        if loadout  then palettes[3] = loadout.value end

        -- Separate palettes into main set and judgement
        local pal_main = {}
        local pal_judgement = {}

        for p, spr in ipairs(palettes) do
            local width = gm.sprite_get_width(spr)
            local height = gm.sprite_get_height(spr)

            local surf = gm.surface_create(width, height)
            gm.surface_set_target(surf)
            gm.draw_sprite(spr, 0, 0, 0)
            gm.surface_reset_target()

            -- Main set
            pal_main[p] = gm.sprite_create_from_surface_w(
                RAPI_NAMESPACE,
                "skinIntermediate",
                surf,       -- index
                0,          -- x
                0,          -- y
                width - 1,  -- w
                height,     -- h
                0,          -- yorig
                0           -- xorig
            )

            -- Judgement
            pal_judgement[p] = gm.sprite_create_from_surface_w(
                RAPI_NAMESPACE,
                "skinIntermediate",
                surf,       -- index
                width - 1,  -- x
                0,          -- y
                1,          -- w
                height,     -- h
                0,          -- yorig
                0           -- xorig
            )

            gm.surface_free(surf)
        end

        -- Store in SurvivorSkinLoadoutUnlockables
        local default = skin_family:get(0)
        default.identifier       = "main_set"
        default.palette          = pal_main[1]
        default.palette_portrait = pal_main[2]
        default.palette_loadout  = pal_main[3]

        local judgement = skin_family:get(#skin_family - 1)
        judgement.identifier       = "judgement"
        judgement.palette          = pal_judgement[1]
        judgement.palette_portrait = pal_judgement[2]
        judgement.palette_loadout  = pal_judgement[3]
    end
end
table.insert(_rapi_initialize, Survivor.internal.initialize)



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
    Initialize.internal.check_if_started("Survivor.new")
    if not identifier then log.error("Survivor.new: No identifier provided", 2) end

    -- Return existing survivor if found
    local survivor = Survivor.find(identifier, NAMESPACE, true)
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
    --@param        table       | table     | A key-value pair table containing stats to set.
    --[[
    Sets the base stats for the survivor.

    **Valid stats**
    Property | Type | Description
    | - | - | -
    `health`            | number    | `110` by default.
    `damage`            | number    | `12` by default.
    `regen`             | number    | `0.01` by default.
    `armor`             | number    | `0` by default.
    `attack_speed`      | number    | `1` by default.
    `critical_chance`   | number    | `1` by default.
    ]]
    set_stats_base = function(self, t)
        __survivor_data[self.value].stats_base = __survivor_data[self.value].stats_base or {
            health          = 110,
            damage          = 12,
            regen           = 0.01,
            armor           = 0,
            attack_speed    = 1,
            critical_chance = 1
        }

        Util.table_append(__survivor_data[self.value].stats_base, t)
    end,


    --@instance
    --@param        table       | table     | A key-value pair table containing stats to set.
    --[[
    Sets the stats gained per level up for the survivor.

    **Valid stats**
    Property | Type | Description
    | - | - | -
    `health`            | number    | `32` by default.
    `damage`            | number    | `3` by default.
    `regen`             | number    | `0.002` by default.
    `armor`             | number    | `2` by default.
    `attack_speed`      | number    | `0` by default.
    `critical_chance`   | number    | `0` by default.
    ]]
    set_stats_level = function(self, t)
        __survivor_data[self.value].stats_level = __survivor_data[self.value].stats_level or {
            health          = 32,
            damage          = 3,
            regen           = 0.002,
            armor           = 2,
            attack_speed    = 0,
            critical_chance = 0
        }

        Util.table_append(__survivor_data[self.value].stats_level, t)
    end,


    --@instance
    --@return       table or nil
    --[[
    Returns the base stats for the survivor; valid stats are listed in @link {`set_stats_base` | Survivor#set_stats_base}.
    Returns `nil` if `set_stats_base` was never called for the survivor.
    ]]
    get_stats_base = function(self)
        if not __survivor_data[self.value].stats_base then return nil end
        return Util.table_shallow_copy(__survivor_data[self.value].stats_base)
    end,


    --@instance
    --@return       table or nil
    --[[
    Returns the stats gained per level up for the survivor; valid stats are listed in @link {`set_stats_level` | Survivor#set_stats_level}.
    Returns `nil` if `set_stats_level` was never called for the survivor.
    ]]
    get_stats_level = function(self)
        if not __survivor_data[self.value].stats_level then return nil end
        return Util.table_shallow_copy(__survivor_data[self.value].stats_level)
    end,


    --@instance
    --@param        slot        | number    | The @link {slot | Skill#slot} to add to.
    --@param        skill       | Skill     | The skill to add.
    --[[
    Adds a skill to the specified slot.
    Does nothing if the skill is already present in that slot.
    ]]
    add_skill = function(self, slot, skill)
        skill = Wrap.unwrap(skill)

        if type(slot) ~= "number"   then log.error("add_skill: Invalid slot argument", 2) end
        if type(skill) ~= "number"  then log.error("add_skill: Invalid skill argument", 2) end

        -- Check if skill is already present in this slot family
        for _, s in ipairs(self:get_skills(slot)) do
            if s.value == skill then
                return
            end
        end

        -- Add new SurvivorSkillLoadoutUnlockable to slot family
        local array = self.array:get(Survivor.Property.SKILL_FAMILY_Z + slot).elements
        array:push(
            Struct.new(
                gm.constants.SurvivorSkillLoadoutUnlockable,
                skill
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
        skill = Wrap.unwrap(skill)

        if type(slot) ~= "number"   then log.error("remove_skill: Invalid slot argument", 2) end
        if type(skill) ~= "number"  then log.error("remove_skill: Invalid skill argument", 2) end

        -- Remove correct SurvivorSkillLoadoutUnlockable from slot family
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
        if type(slot) ~= "number"   then log.error("remove_skill_at_index: Invalid slot argument", 2) end
        if type(index) ~= "number"  then log.error("remove_skill_at_index: Invalid index argument", 2) end

        -- Remove SurvivorSkillLoadoutUnlockable at index from slot family
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

        -- Store every SurvivorSkillLoadoutUnlockable from slot family into table
        local t = {}
        local array = self.array:get(Survivor.Property.SKILL_FAMILY_Z + slot).elements
        for _, skill_loadout_unlockable in ipairs(array) do
            table.insert(t, Skill.wrap(skill_loadout_unlockable.skill_id))
        end
        return t
    end,


    --@instance
    --@param        identifiers         | string or table   | The identifier(s) for the skin(s); consider prefixing with your mod's namespace. <br>If multiple skins are in the given sprites, pass a table of identifiers (one for each).
    --@param        palette             | sprite            | The palette sprite used in-run.
    --@param        palette_portrait    | sprite            | The palette sprite used in the character portrait. <br>Skin count (width) should be equal to `palette`.
    --@param        palette_loadout     | sprite            | The palette sprite used in the character select animation. <br>Skin count (width) should be equal to `palette`.
    --[[
    Adds a skin(s).
    Existing identifiers will be overwritten with the new palette.

    For modded survivors, the **first skin added should be the default palette**.
    ]]
    add_skin = function(self, identifiers, palette, palette_portrait, palette_loadout)
        Initialize.internal.check_if_started("add_skin")

        if not identifiers then log.error("add_skin: Invalid identifiers argument", 2) end
        if type(identifiers) == "string" then identifiers = {identifiers} end

        palette          = Wrap.unwrap(palette)
        palette_portrait = Wrap.unwrap(palette_portrait)
        palette_loadout  = Wrap.unwrap(palette_loadout)
        if type(palette)          ~= "number" then log.error("add_skin: Invalid palette argument", 2) end
        if type(palette_portrait) ~= "number" then log.error("add_skin: Invalid palette_portrait argument", 2) end
        if type(palette_loadout)  ~= "number" then log.error("add_skin: Invalid palette_loadout argument", 2) end

        local count = gm.sprite_get_width(palette)
        local countp = gm.sprite_get_width(palette_portrait)
        local countl = gm.sprite_get_width(palette_loadout)
        if count ~= countp then log.error("add_skin: palette_portrait skin count does not match palette", 2) end
        if count ~= countl then log.error("add_skin: palette_loadout skin count does not match palette", 2) end

        for i = 1, count do
            local identifier = identifiers[i]

            local skin = {palette, palette_portrait, palette_loadout}
            local skin_suffix = {"palette", "portrait", "loadout"}

            -- Extract relevant columns from each sprite
            for j, spr in ipairs(skin) do
                local height = gm.sprite_get_height(spr)

                -- Draw relevant column onto surface
                local surf = gm.surface_create(1, height)
                gm.surface_set_target(surf)
                gm.draw_sprite(spr, 0, 1 - i, 0)
                gm.surface_reset_target()

                -- Create new sprite from surface
                skin[j] = gm.sprite_create_from_surface_w(
                    RAPI_NAMESPACE,
                    "skin_"..self.identifier.."-"..identifier.."_"..skin_suffix[j],
                    surf,   -- index
                    0,      -- x
                    0,      -- y
                    1,      -- w
                    height, -- h
                    0,      -- yorig
                    0       -- xorig
                )
                gm.surface_free(surf)
            end

            local skin_family = self.skin_family.elements
            local default = skin_family:get(0)

            -- Check if identifier is already present in skin_family
            local index
            for j, sslu in ipairs(skin_family) do
                if sslu.identifier == identifier then
                    index = j - 1
                    break
                end
            end

            -- Check if this is a modded survivor
            -- and first skin being added
            -- OR if index is 0 (in which case modifying default by identifier)
            if  (self.value >= Survivor.CUSTOM_START
            and (not default.identifier))
            or  index == 0 then
                default.identifier       = identifier
                default.palette          = skin[1]
                default.palette_portrait = skin[2]
                default.palette_loadout  = skin[3]
                
            else
                -- Create new SurvivorSkinLoadoutUnlockable
                local unlockable = Struct.new(
                    gm.constants.SurvivorSkinLoadoutUnlockable,
                    gm.actor_skin_get_default_palette_swap(index or #skin_family)
                )
                unlockable.identifier       = identifier
                unlockable.palette          = skin[1]
                unlockable.palette_portrait = skin[2]
                unlockable.palette_loadout  = skin[3]

                -- Add unlockable to skin_family
                -- or replace existing
                if not index then skin_family:insert(#skin_family, unlockable)
                else skin_family:set(index, unlockable)
                end

            end
        end
    end,


    --@instance
    --@return       Achievement
    --[[
    Returns the associated @link {Achievement | Achievement} if it exists,
    or an invalid Achievement if it does not.
    ]]
    get_achievement = function(self)
        return Achievement.wrap(self.achievement_id)
    end

})



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.survivor_create, function(self, other, result, args)
    __survivor_data[result.value] = {}

    -- Add stat initialization callback
    -- This is created post `survivor_create` to allow for
    -- modifying vanilla survivor stats too if desired
    local survivor = Survivor.wrap(result.value)
    Callback.add("__permanent", survivor.on_init, Callback.internal.FIRST, function(actor)
        -- Base and level stats
        local data = __survivor_data[actor.class]
        if data then
            local base = data.stats_base
            if base then
                actor.maxhp_base            = base.health
                actor.damage_base           = base.damage
                actor.hp_regen_base         = base.regen
                actor.armor_base            = base.armor
                actor.attack_speed_base     = base.attack_speed
                actor.critical_chance_base  = base.critical_chance
            end

            local level = data.stats_level
            if level then
                actor.maxhp_level           = level.health
                actor.damage_level          = level.damage
                actor.hp_regen_level        = level.regen
                actor.armor_level           = level.armor
                actor.attack_speed_level    = level.attack_speed
                actor.critical_chance_level = level.critical_chance
            end
        end

        -- Set base speed to 2.8 for custom survivors
        if actor.class >= Survivor.CUSTOM_START then
            actor.pHmax_base = 2.8
        end

        -- Set palette
        if Util.bool(survivor.sprite_palette) then
            actor.sprite_palette = survivor.sprite_palette
        else
            log.warning("Survivor '"..survivor.namespace.."-"..survivor.identifier.."' has no `sprite_palette` set; defaulting to 'gm.constants.sCommandoPalette'")
            actor.sprite_palette = gm.constants.sCommandoPalette
        end
    end)

    -- For hook below this one
    Global._survivor_skin_default = nil
end)


-- Prevent every survivor from sharing the same default SurvivorSkinLoadoutUnlockable
gm.pre_script_hook(gm.constants.actor_skin_create, function(self, other, result, args)
    if args[2].value == "default" then
        args[2].value = args[2].value..math.floor(__skin_default_counter)
        __skin_default_counter = __skin_default_counter + 1
    end
end)


-- On going to character select screen,
gm.pre_script_hook(gm.constants.room_goto_w, function(self, other, result, args)
    if args[1].value ~= gm.constants.rSelect then return end

    -- Build final palette sprites for each survivor
    for i = 0, #Class.Survivor - 1 do
        local survivor = Survivor.wrap(i)

        local palettes = {} -- palette (in-run), portrait, loadout
        local keys = {"palette", "palette_portrait", "palette_loadout"}
        local skin_family = survivor.skin_family.elements

        -- Loop through skin_family and assemble palette sprites together
        for j, unlockable in ipairs(skin_family) do
            if unlockable.identifier then

                for p, key in ipairs(keys) do
                    local spr = palettes[p]
                    local new = unlockable[key]

                    -- Start with this if this is the first sprite found
                    if not spr then
                        palettes[p] = new
                    
                    -- Otherwise merge with existing sprite
                    else
                        local width = gm.sprite_get_width(spr)
                        local height = gm.sprite_get_height(spr)

                        -- Draw existing sprite onto surface
                        -- and then the new one at the end
                        -- (Assuming palette sprites past the initial
                        -- are 1 column wide, which should be the case)
                        local surf = gm.surface_create(width + 1, height)
                        gm.surface_set_target(surf)
                        gm.draw_sprite(spr, 0, 0, 0)
                        gm.draw_sprite(new, 0, width, 0)
                        gm.surface_reset_target()

                        -- Create new sprite from surface
                        palettes[p] = gm.sprite_create_from_surface_w(
                            RAPI_NAMESPACE,
                            "skinIntermediate",
                            surf,       -- index
                            0,          -- x
                            0,          -- y
                            width + 1,  -- w
                            height,     -- h
                            0,          -- yorig
                            0           -- xorig
                        )
                        gm.surface_free(surf)
                        
                    end
                end

                -- Judgement skins: Reassign `pal_index` based on slot index
                -- Apparently `pal_index` here is indexed from -1(?), therefore j - 2
                if unlockable.identifier == "judgement" then
                    ActorSkin.wrap(unlockable.skin_id).effect_display.pal_index = j - 2
                end
            end
        end

        -- Assign constructed palettes to survivor properties
        -- (These sprites are not stored anywhere in ResourceManager but whatever)
        survivor.sprite_palette          = palettes[1] or -1
        survivor.sprite_portrait_palette = palettes[2] or -1
        survivor.sprite_loadout_palette  = palettes[3] or -1
    end
end)


-- Draw palette-swapped loadout animation
gm.pre_script_hook(gm.constants.actor_skin_draw_loadout_sprite, function(self, other, result, args)
    local survivor = Survivor.wrap(args[1].value)
    local skin_id = args[7].value   -- Indexed from 0

    if survivor.sprite_loadout_palette == -1 then return end

    -- Edge case: Ignore Engineer Judgement skin
    if  survivor.value == Survivor.Class.ENGINEER
    and skin_id == 29 then
        return
    end

    -- Look for slot index of the SurvivorSkinLoadoutUnlockable matching the skin_id
    local index = skin_id
    local skin_family = survivor.skin_family.elements
    for i, unlockable in ipairs(skin_family) do
        if unlockable.skin_id == skin_id then
            index = i - 1
            break
        end
    end

    gm.pal_swap_set(survivor.sprite_loadout_palette, index)

    -- Draw loadout animation
    gm.draw_sprite_ext(
        survivor.sprite_loadout,    -- sprite
        args[2].value,              -- subimg
        args[3].value,              -- x
        args[4].value,              -- y
        args[5].value,              -- xscale
        args[6].value,              -- yscale
        0,                          -- rot
        Color.WHITE,                -- color
        1                           -- alpha
    )

    gm.pal_swap_reset()

    return false
end)


-- Draw palette-swapped portraits
gm.pre_script_hook(gm.constants.actor_skin_draw_portrait, function(self, other, result, args)
    local survivor = Survivor.wrap(args[1].value)
    local skin_id = args[8].value   -- Indexed from 0

    if survivor.sprite_portrait_palette == -1 then return end

    -- Look for slot index of the SurvivorSkinLoadoutUnlockable matching the skin_id
    local index = skin_id
    local skin_family = survivor.skin_family.elements
    for i, unlockable in ipairs(skin_family) do
        if unlockable.skin_id == skin_id then
            index = i - 1
            break
        end
    end
    
    gm.pal_swap_set(survivor.sprite_portrait_palette, index)

    -- Draw portrait
    gm.draw_sprite_ext(
        gm.actor_skin_get_portrait_sprite(args[1].value, args[2].value, args[8].value),
        args[3].value,  -- subimg
        args[4].value,  -- x
        args[5].value,  -- y
        args[6].value,  -- xscale
        args[7].value,  -- yscale
        0,              -- rot
        Color.WHITE,    -- color
        1               -- alpha
    )

    gm.pal_swap_reset()

    return false
end)