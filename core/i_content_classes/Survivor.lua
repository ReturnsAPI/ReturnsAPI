-- Survivor

---@class SurvivorClass
Survivor = C["Survivor"]

run_on_initial_load(function()
    P.survivor_data        = {}    -- Stores some data for survivors.
    P.skin_default_counter = 0     
    P.enable_palette_swap  = true  -- If `false`, uses vanilla implementation.
end)

local survivor_data = P.survivor_data

local proxy              = P.proxy
local metatable          = W["Survivor"]
local find_table_wrapper = P.class_find_tables_wrapper["Survivor"]
local find_table_array   = P.class_find_tables_array["Survivor"]

local type               = type
local gm                 = gm
local Struct             = Struct
local Achievement        = Achievement
local ActorSkin          = ActorSkin
local Skill              = Skill
local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class Survivor
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field properties Array The array storing this survivor's properties.
---@field array Array Alias for .properties.

---@class Survivor
---@field namespace               string  The namespace the survivor is in.
---@field identifier              string  The identifier for the survivor within the namespace.
---@field token_name              string  
---@field token_name_upper        string  
---@field token_description       string  
---@field token_end_quote         string  
---@field skill_family_z          unknown 
---@field skill_family_x          unknown 
---@field skill_family_c          unknown 
---@field skill_family_v          unknown 
---@field skin_family             unknown 
---@field all_loadout_families    unknown 
---@field all_skill_families      unknown 
---@field sprite_loadout          number  Sprite ID.
---@field sprite_title            number  Sprite ID.
---@field sprite_idle             number  Sprite ID.
---@field sprite_portrait         number  Sprite ID.
---@field sprite_portrait_small   number  Sprite ID.
---@field sprite_palette          number  Sprite ID. <br>**This should not be manually set.**
---@field sprite_portrait_palette number  Sprite ID. <br>Unused in vanilla, but used by ReturnsAPI. **This should not be manually set.**
---@field sprite_loadout_palette  number  Sprite ID. <br>Unused in vanilla, but used by ReturnsAPI. **This should not be manually set.**
---@field sprite_credits          number  Sprite ID.
---@field primary_color           number  
---@field select_sound_id         number  Sound ID.
---@field log_id                  number  
---@field achievement_id          number  
---@field milestone_kills_1       unknown 
---@field milestone_items_1       unknown 
---@field milestone_stages_1      unknown 
---@field on_init                 number  The ID of the callback that runs when an instance of the survivor is created. <br>The callback function should have the argument actor.
---@field on_step                 number  The ID of the callback that runs when (TODO). <br>The callback function should have the arguments (TODO).
---@field on_remove               number  The ID of the callback that runs when (TODO). <br>The callback function should have the arguments (TODO).
---@field is_secret               boolean 
---@field cape_offset             Array   Stores the drawing offset for Prophet's Cape. <br>Array order: x_offset, y_offset, x_offset_climbing, y_offset_climbing


-- ========== Constants and Enums ==========

Survivor.Property = {
    NAMESPACE               = 0,
    IDENTIFIER              = 1,
    TOKEN_NAME              = 2,
    TOKEN_NAME_UPPER        = 3,
    TOKEN_DESCRIPTION       = 4,
    TOKEN_END_QUOTE         = 5,
    SKILL_FAMILY_Z          = 6,
    SKILL_FAMILY_X          = 7,
    SKILL_FAMILY_C          = 8,
    SKILL_FAMILY_V          = 9,
    SKIN_FAMILY             = 10,
    ALL_LOADOUT_FAMILIES    = 11,
    ALL_SKILL_FAMILIES      = 12,
    SPRITE_LOADOUT          = 13,
    SPRITE_TITLE            = 14,
    SPRITE_IDLE             = 15,
    SPRITE_PORTRAIT         = 16,
    SPRITE_PORTRAIT_SMALL   = 17,
    SPRITE_PALETTE          = 18,
    SPRITE_PORTRAIT_PALETTE = 19,
    SPRITE_LOADOUT_PALETTE  = 20,
    SPRITE_CREDITS          = 21,
    PRIMARY_COLOR           = 22,
    SELECT_SOUND_ID         = 23,
    LOG_ID                  = 24,
    ACHIEVEMENT_ID          = 25,
    MILESTONE_KILLS_1       = 26,
    MILESTONE_ITEMS_1       = 27,
    MILESTONE_STAGES_1      = 28,
    ON_INIT                 = 29,
    ON_STEP                 = 30,
    ON_REMOVE               = 31,
    IS_SECRET               = 32,
    CAPE_OFFSET             = 33,
}
local t = {}
for name, num in pairs(Survivor.Property) do t[num] = name end
for i = 0, #t do Survivor.Property[i] = t[i] end

Survivor.Class = {
    COMMANDO  = 0,
    HUNTRESS  = 1,
    ENFORCER  = 2,
    BANDIT    = 3,
    HAND      = 4,
    ENGINEER  = 5,
    MINER     = 6,
    SNIPER    = 7,
    ACRID     = 8,
    MERCENARY = 9,
    LOADER    = 10,
    CHEF      = 11,
    PILOT     = 12,
    ARTIFICER = 13,
    DRIFTER   = 14,
    ROBOMANDO = 15,
}

Survivor.CUSTOM_START = 16


-- ========== Internal ==========

local function initialize_vanilla_palettes()
    -- Add correct palettes
    for _, dir in ipairs{
        path.combine(PATH, "data", "sprites", "palettes"),
        path.combine(PATH, "data", "sprites", "portrait_palettes"),
        path.combine(PATH, "data", "sprites", "loadout_palettes"),
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
        local palette  = Sprite.find(survivor.identifier.."Palette", RAPI_NAMESPACE, true)
        local portrait = Sprite.find(survivor.identifier.."PalettePortrait", RAPI_NAMESPACE, true)
        local loadout  = Sprite.find(survivor.identifier.."PaletteLoadout", RAPI_NAMESPACE, true)
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
run_on_initialize(initialize_vanilla_palettes)


-- ========== Static Methods ==========

--[[
Creates a new survivor with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the survivor.
---@return Survivor
Survivor.new = function(NAMESPACE, identifier)
    check_init_started("new")
    if not identifier then throw("No identifier provided", "new") end

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

--[[
Searches for the specified survivor and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return Survivor
Survivor.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all survivor in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>Survivor.Property.NAMESPACE by default.
---@return table<number, Survivor>
Survivor.find_all = function(NAMESPACE, filter, property) end

--[[
Returns a survivor wrapper containing the provided survivor ID.
]]
---@param id number | Survivor The survivor to wrap.
---@return Survivor
Survivor.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class Survivor
local methods = G.methods_content["Survivor"]

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
---@param t table<string, number> A hash table containing stats to set.
methods.set_stats_base = function(self, t)
    local stats_base = survivor_data[proxy[self]].stats_base
    if not stats_base then
        stats_base = {
            health          = 110,
            damage          = 12,
            regen           = 0.01,
            armor           = 0,
            attack_speed    = 1,
            critical_chance = 1,
        }
        survivor_data[proxy[self]].stats_base = stats_base
    end
    table.merge(stats_base, t)
end

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
---@param t table<string, number> A hash table containing stats to set.
methods.set_stats_level = function(self, t)
    local stats_level = survivor_data[proxy[self]].stats_level
    if not stats_level then
        stats_level = {
            health          = 32,
            damage          = 3,
            regen           = 0.002,
            armor           = 2,
            attack_speed    = 0,
            critical_chance = 0,
        }
        survivor_data[proxy[self]].stats_level = stats_level
    end
    table.merge(stats_level, t)
end

--[[
Returns the base stats for the survivor; valid stats are listed in @link {`set_stats_base` | Survivor#set_stats_base}, <br>
or `nil` if `set_stats_base` was never called for the survivor.
]]
---@return table | nil
methods.get_stats_base = function(self)
    local stats_base = survivor_data[proxy[self]].stats_base
    if not stats_base then return nil end
    return table.shallow_copy(stats_base)
end

--[[
Returns the stats gained per level up for the survivor; valid stats are listed in @link {`set_stats_level` | Survivor#set_stats_level}, <br>
or `nil` if `set_stats_level` was never called for the survivor.
]]
---@return table | nil
methods.get_stats_level = function(self)
    local stats_level = survivor_data[proxy[self]].stats_level
    if not stats_level then return nil end
    return table.shallow_copy(stats_level)
end

--[[
Adds a skill to the specified slot. <br>
Does nothing if the skill is already present in that slot.
]]
---@param slot number The @link {slot | Skill#slot} to add to.
---@param skill number | Skill The skill to add.
methods.add_skill = function(self, slot, skill)
    skill = unwrap(skill)
    if type(slot)  ~= "number" then throw("Invalid slot argument") end
    if type(skill) ~= "number" then throw("Invalid skill argument") end

    -- Check if skill is already present in this slot family
    local array = self.array:get(Survivor.Property.SKILL_FAMILY_Z + slot).elements
    for i, skill_loadout_unlockable in ipairs(array) do
        if skill_loadout_unlockable.skill_id == skill then
            return
        end
    end

    -- Add new SurvivorSkillLoadoutUnlockable to slot family
    array:push(
        Struct.new(
            gm.constants.SurvivorSkillLoadoutUnlockable,
            skill
        )
    )
end

--[[
Removes a skill from the specified slot.
]]
---@param slot number The @link {slot | Skill#slot} to remove from.
---@param skill number | Skill The skill to remove.
methods.remove_skill = function(self, slot, skill)
    skill = unwrap(skill)
    if type(slot)  ~= "number" then throw("Invalid slot argument") end
    if type(skill) ~= "number" then throw("Invalid skill argument") end

    -- Remove correct SurvivorSkillLoadoutUnlockable from slot family
    local array = self.array:get(Survivor.Property.SKILL_FAMILY_Z + slot).elements
    for i, skill_loadout_unlockable in ipairs(array) do
        if skill_loadout_unlockable.skill_id == skill then
            array:delete(i)
            return
        end
    end
end

--[[
Removes the skill at the given index from the specified slot.
]]
---@param slot number The @link {slot | Skill#slot} to remove from.
---@param index number The index at which to remove, starting at `1`.
methods.remove_skill_at_index = function(self, slot, index)
    if type(slot)  ~= "number" then throw("Invalid slot argument") end
    if type(index) ~= "number" then throw("Invalid index argument") end

    -- Remove SurvivorSkillLoadoutUnlockable at index from slot family
    local array = self.array:get(Survivor.Property.SKILL_FAMILY_Z + slot).elements
    array:delete(index)
end

--[[
Returns a table containing a list of Skills belonging to the specified slot.

*Technical:* Returns a table copy of `survivor.skill_family_<slot>.elements[i].skill_id`.
]]
---@param slot number The @link {slot | Skill#slot} to get from.
---@return table<number, Skill>
methods.get_skills = function(self, slot)
    if type(slot) ~= "number" then throw("Invalid slot argument") end

    -- Store every SurvivorSkillLoadoutUnlockable from slot family into table
    local t, i = {}
    local array = self.array:get(Survivor.Property.SKILL_FAMILY_Z + slot).elements
    for _, skill_loadout_unlockable in ipairs(array) do
        t[i] = Skill.wrap(skill_loadout_unlockable.skill_id)
        i = i + 1
    end
    return t
end

--[[
Adds a skin(s). <br>
Existing identifiers will be overwritten with the new palette.

For modded survivors, the **first skin added should be the default palette**.

**Vanilla skins** <br>
The modified vanilla palettes that ReturnsAPI uses can be found in `ReturnsAPI-ReturnsAPI", "core", "sprites`.
]]
---@param identifiers string | table The identifier(s) for the skin(s); consider prefixing with your mod's namespace. <br>If multiple skins are in the given sprites, pass a table of identifiers (one for each).
---@param palette number | Sprite The palette sprite used in-run.
---@param palette_portrait number | Sprite The palette sprite used in the character portrait. <br>Skin count (width) should be equal to `palette`.
---@param palette_loadout number | Sprite The palette sprite used in the character select animation. <br>Skin count (width) should be equal to `palette`.
---@param paint_color? number | table The color of the paint in the achievement popup's paint bucket. <br>If multiple skins are in the given sprites, pass a table of colors (one for each). <br>If not provided, the paint bucket icon will not appear.
methods.add_skin = function(self, identifiers, palette, palette_portrait, palette_loadout, paint_color)
    check_init_started()

    if not identifiers then throw("Invalid identifiers argument") end
    if type(identifiers) == "string" then identifiers = {identifiers} end
    if paint_color and type(paint_color) ~= "table" then paint_color = {paint_color} end

    palette          = unwrap(palette)
    palette_portrait = unwrap(palette_portrait)
    palette_loadout  = unwrap(palette_loadout)
    if type(palette)          ~= "number" then throw("Invalid palette argument") end
    if type(palette_portrait) ~= "number" then throw("Invalid palette_portrait argument") end
    if type(palette_loadout)  ~= "number" then throw("Invalid palette_loadout argument") end

    local count  = gm.sprite_get_width(palette)
    local countp = gm.sprite_get_width(palette_portrait)
    local countl = gm.sprite_get_width(palette_loadout)
    if count ~= countp then throw("palette_portrait skin count does not match palette") end
    if count ~= countl then throw("palette_loadout skin count does not match palette") end

    if count ~= #identifiers then throw("identifiers count does not match palette skin count") end
    if paint_color and (count ~= #paint_color) then throw("paint_color count does not match palette skin count") end

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
        if  (proxy[self] >= Survivor.CUSTOM_START
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

            -- Create achievement popup sprite
            local height = gm.sprite_get_height(skin[2])
            local surf = gm.surface_create(2, height)
            gm.surface_set_target(surf)
            gm.draw_sprite_part(default.palette_portrait, 0, 0, 0, 1, height, 0, 0)
            gm.draw_sprite(skin[2], 0, 1, 0)
            gm.surface_reset_target()

            local pal = gm.sprite_create_from_surface_w(
                RAPI_NAMESPACE,
                "skin_"..self.identifier.."-"..identifier.."_achievementPalette",
                surf,   -- index
                0,      -- x
                0,      -- y
                2,      -- w
                height, -- h
                0,      -- yorig
                0       -- xorig
            )
            gm.surface_free(surf)

            local sprite_portrait = self.sprite_portrait
            local w = gm.sprite_get_width(sprite_portrait)
            local h = gm.sprite_get_height(sprite_portrait)
            surf = gm.surface_create(w, h)
            gm.surface_set_target(surf)
            gm.pal_swap_set(pal, 1)
            gm.draw_sprite(sprite_portrait, 0, 0, 0)
            gm.pal_swap_reset()
            if paint_color and paint_color[i] then
                gm.draw_sprite(gm.constants.sPaintBucket, 0, 16, h - 17)
                gm.draw_sprite_ext(gm.constants.sPaintBucket, 1, 16, h - 17, 1, 1, 0, paint_color[i], 1)
            end
            gm.surface_reset_target()

            unlockable.achievement_sprite = gm.sprite_create_from_surface_w(
                RAPI_NAMESPACE,
                "skin_"..self.identifier.."-"..identifier.."_achievement",
                surf,   -- index
                0,      -- x
                0,      -- y
                w,      -- w
                h,      -- h
                0,      -- yorig
                0       -- xorig
            )
            gm.surface_free(surf)

        end
    end
end

--[[
Returns the associated @link {Achievement | Achievement} if it exists, <br>
or an invalid Achievement if it does not.
]]
---@return Achievement
methods.get_achievement = function(self)
    return Achievement.wrap(self.achievement_id)
end

--[[
Prints the survivor's properties.
]]
methods.print = function(self) end


-- ========== Hooks ==========

gm.post_script_hook(gm.constants.survivor_create, function(self, other, result, args)
    survivor_data[result.value] = {}

    -- Add stat initialization callback
    -- This is created post `survivor_create` to allow for
    -- modifying vanilla survivor stats too if desired
    local survivor = Survivor.wrap(result.value)
    Callback.add(PERMANENT_NAMESPACE, survivor.on_init, Callback.internal.FIRST, function(actor)
        -- Base and level stats
        local data = survivor_data[actor.class]
        if data then
            local base = data.stats_base
            if base then
                actor.maxhp_base           = base.health
                actor.damage_base          = base.damage
                actor.hp_regen_base        = base.regen
                actor.armor_base           = base.armor
                actor.attack_speed_base    = base.attack_speed
                actor.critical_chance_base = base.critical_chance
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

    -- For the hook below this one
    -- This is a cache variable used by the game that stores the same default SurvivorSkinLoadoutUnlockable
    Global._survivor_skin_default = nil
end)

-- Prevent every survivor from sharing the same default SurvivorSkinLoadoutUnlockable
gm.pre_script_hook(gm.constants.actor_skin_create, function(self, other, result, args)
    if args[2].value == "default" then
        args[2].value = args[2].value..math.floor(P.skin_default_counter)
        P.skin_default_counter = P.skin_default_counter + 1
    end
end)

gm.pre_script_hook(gm.constants.room_goto_w, function(self, other, result, args)
    -- On going to character select screen,
    if args[1].value ~= gm.constants.rSelect then return end

    -- Build final palette sprites for each survivor
    for i = 0, #Class.Survivor - 1 do
        local survivor = Survivor.wrap(i)

        local palettes = {} ---@type table<number, number> palette (in-run), portrait, loadout
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
                        local width  = gm.sprite_get_width(spr)
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
    if not P.enable_palette_swap then return end
    
    local survivor = Survivor.wrap(args[1].value)
    local skin_id  = args[7].value  -- Indexed from 0

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
    if not P.enable_palette_swap then return end

    local survivor = Survivor.wrap(args[1].value)
    local skin_id  = args[8].value  -- Indexed from 0

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

gui.add_to_menu_bar(function()
    if ImGui.Button("Palette swapping: "..tostring(P.enable_palette_swap)) then
        P.enable_palette_swap = not P.enable_palette_swap
    end
end)