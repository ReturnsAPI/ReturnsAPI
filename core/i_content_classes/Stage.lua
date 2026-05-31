-- Stage

---@class StageClass
Stage = C["Stage"]

run_on_initial_load(function()
    P.stage_variant_next_id = {}  ---@type table<stage_id, number> Stores the next identifier _ID to use for each stage; `[stage_id] = <next>` <br>This is to not reuse previously used variant IDs if the variant is removed from the stage
    P.stage_new_rooms       = {}  ---@type table<namespace, table> Stores new rooms added (for removal purposes)
    P.stage_populate_biome  = {}
end)

local stage_variant_next_id = P.stage_variant_next_id
local stage_new_rooms       = P.stage_new_rooms
local stage_populate_biome  = P.stage_populate_biome

local proxy              = P.proxy
local metatable          = W["Stage"]
local find_table_wrapper = P.class_find_tables_wrapper["Stage"]
local find_table_array   = P.class_find_tables_array["Stage"]

local type               = type
local math               = math
local table_insert       = table.insert
local table_unpack       = table.unpack
local gm                 = gm  ---@type table<string, function>
local Array              = Array
local List               = List
local Struct             = Struct
local Global             = Global
local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class Stage
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field properties Array The array storing this stage's properties.
---@field array Array Alias for .properties.

---@class Stage
---@field namespace                   string  The namespace the stage is in.
---@field identifier                  string  The identifier for the stage within the namespace.
---@field token_name                  string  The localization token for the stage's name.
---@field token_subname               string  The localization token for the stage's subname.
---@field spawn_enemies               number  List ID
---@field spawn_enemies_loop          number  List ID
---@field spawn_interactables         number  List ID
---@field spawn_interactables_loop    number  List ID
---@field spawn_interactable_rarity   unknown  
---@field interactable_spawn_points   unknown 
---@field allow_mountain_shrine_spawn boolean 
---@field classic_variant_count       unknown 
---@field is_new_stage                boolean 
---@field room_list                   number  The ID of a list containing the rooms (variants) of the stage.
---@field music_id                    number  The ID of the sound to play as background music.
---@field teleporter_index            number  
---@field populate_biome_properties   Struct  
---@field log_id                      number  The environment log ID of the stage.


-- ========== Enums ==========

Stage.Property = {
    NAMESPACE                   = 0,
    IDENTIFIER                  = 1,
    TOKEN_NAME                  = 2,
    TOKEN_SUBNAME               = 3,
    SPAWN_ENEMIES               = 4,
    SPAWN_ENEMIES_LOOP          = 5,
    SPAWN_INTERACTABLES         = 6,
    SPAWN_INTERACTABLES_LOOP    = 7,
    SPAWN_INTERACTABLE_RARITY   = 8,
    INTERACTABLE_SPAWN_POINTS   = 9,
    ALLOW_MOUNTAIN_SHRINE_SPAWN = 10,
    CLASSIC_VARIANT_COUNT       = 11,
    IS_NEW_STAGE                = 12,
    ROOM_LIST                   = 13,
    MUSIC_ID                    = 14,
    TELEPORTER_INDEX            = 15,
    POPULATE_BIOME_PROPERTIES   = 16,
    LOG_ID                      = 17,
}
local t = {}
for name, num in pairs(Stage.Property) do t[num] = name end
for i = 0, #t do Stage.Property[i] = t[i] end


-- ========== Internal ==========

local function get_variant_count()
    -- Get current variant count for each stage
    for i, stage in ipairs(Class.Stage) do
        stage_variant_next_id[i - 1] = List.wrap(stage:get(Stage.Property.ROOM_LIST)):size() + 1
    end
end
run_on_initialize(get_variant_count)


-- ========== Static Methods ==========

--[[
Creates a new stage with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the stage.
---@return Stage
Stage.new = function(NAMESPACE, identifier)
    check_init_started("new")
    if not identifier then throw("No identifier provided", "new") end

    -- Return existing stage if found
    local stage = Stage.find(identifier, NAMESPACE, true)
    if stage then return stage end

    -- Create new
    stage = Stage.wrap(gm.stage_create(
        NAMESPACE,
        identifier
    ))

    -- Remove `is_new_stage` flag
    stage.is_new_stage = false

    stage_variant_next_id[stage.value] = 0

    return stage
end

--[[
Searches for the specified stage and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return Stage
Stage.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all stage in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>Stage.Property.NAMESPACE by default.
---@return table<number, Stage>
Stage.find_all = function(NAMESPACE, filter, property) end

--[[
Prints the stage progression order.
]]
Stage.print_tiers = function()
    local order = Global.stage_progression_order  ---@type Array Array of Lists
    local str = ""

    for tier, list_id in ipairs(order) do
        if tier > 1 then str = str.."\n" end
            
        if tier < #order then str = str.."\n[Tier "..tier.."]"
        else str = str.."\n[Final Stage]"
        end

        local list = List.wrap(list_id)
        for _, stage in ipairs(list) do
            local stage = Stage.wrap(stage)
            str = str.."\n"..stage.namespace.."-"..stage.identifier
        end
    end

    print(str)
end

--[[
Adds a new room(s) to the stage, and adds it as <br>
a variant to the environment log (if applicable).
]]
---@param stage Stage The stage to add rooms to.
---@param ... string A variable number of paths. <br>~ expands to your mod folder.
Stage.add_room = function(NAMESPACE, stage, ...)
    if not stage then throw("stage is nil", "add_room") end

    local self = Stage.wrap(stage)
    local id = proxy[self]

    local identifier = self.identifier
    local room_list = List.wrap(self.room_list)

    stage_new_rooms[NAMESPACE] = stage_new_rooms[NAMESPACE] or {}

    -- Get environment log
    local display_room_ids
    local log_id = self.log_id
    if log_id ~= -1 then
        display_room_ids = EnvironmentLog.wrap(log_id).display_room_ids
    end

    -- Loop through paths
    local t = {...}
    if type(t[1]) == "table" then t = t[1] end

    for _, path in ipairs(t) do
        path = expand_path(NAMESPACE, path)

        -- Load room and add to list
        local room = gm.stage_load_room(NAMESPACE, identifier.."_"..stage_variant_next_id[id], path)
        if type(room) == "string" then  -- Return value is an error string apparently
            throw("Could not load room at '"..path.."'", "add_room")
        end
        room_list:add(room)

        stage_variant_next_id[id] = stage_variant_next_id[id] + 1

        table_insert(stage_new_rooms[NAMESPACE], {
            stage   = id,
            room_id = room
        })

        -- Associate environment log (if it exists)
        if display_room_ids then
            display_room_ids:push(room)
            gm.room_associate_environment_log(room, log_id, #room_list - 1)
        end
    end
end

--[[
Removes all rooms (variants) added from your mod.

Automatically called when you hotload your mod.
]]
Stage.remove_all_rooms = function(NAMESPACE)
    if not stage_new_rooms[NAMESPACE] then return end

    for _, t in ipairs(stage_new_rooms[NAMESPACE]) do
        local stage = Stage.wrap(t.stage)
        local room_list = List.wrap(stage.room_list)

        -- Remove variant
        room_list:delete_value(t.room_id)

        -- Get environment log
        local log_id = stage.log_id
        if log_id ~= -1 then
            local display_room_ids = EnvironmentLog.wrap(log_id).display_room_ids
            
            -- Remove variant
            display_room_ids:delete_value(t.room_id)

            -- Reassociate environment logs
            for i = 0, #display_room_ids - 1 do
                gm.room_associate_environment_log(room_list:get(i), log_id, i)
            end
        end
    end

    stage_new_rooms[NAMESPACE] = nil
end
run_on_import(Stage.remove_all_rooms)

--[[
Returns a stage wrapper containing the provided stage ID.
]]
---@param id number | Stage The stage to wrap.
---@return Stage
Stage.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class Stage
local methods = G.methods_content["Stage"]

--[[
Adds the stage to the specified tiers *after removing it from its previous ones* <br>
(i.e., overwrites the stage's tier list). <br>
Tiers are indexed from 1. <br>
If *no arguments* are provided, removes the stage from progression.

A new tier may be created by providing a tier 1 higher than the current count. <br>
(E.g., By default, there are 5 tiers of progression, excluding the final stage; <br>
assigning the stage to tier 6 will add another one.)
]]
---@param ... number A variable number of tiers. <br>Alternatively, a table may be provided. <br>If not provided, removes stage from progression.
methods.set_tier = function(self, ...)
    local order = Global.stage_progression_order  ---@type Array Array of Lists

    -- Remove from existing tier(s)
    -- Prevent full removal from tiers 1 to 5,
    -- so that those lists don't get deleted
    for tier, list_id in ipairs(order) do
        local list = List.wrap(list_id)
        if tier <= 5 and #list == 1 and list:contains(self) then
            log.warning("set_tier: Could not remove "..self.namespace.."-"..self.identifier.." from tier "..tier.."; tiers 1 to 5 must have at least 1 stage each")
        else list:delete_value(self)
        end
    end

    -- Add to target tier(s)
    -- The last List will always contain the final stage,
    -- so to create a new tier, move the List containing the
    -- final stage 1 slot foward, and then create a new List
    -- into where it was previously
    -- The game actually handles these new additions automatically
    local t = {...}
    if type(t[1]) == "table" then t = t[1] end
    for _, tier in ipairs(t) do
        local cap = #order
        if type(tier) ~= "number" or tier < 1 or tier > cap then
            throw("Stage tier should be between 1 and "..(cap - 1).." (current count, inclusive), or "..cap.." to add a new tier.")
        end

        -- Add a new tier
        if tier == cap then
            order:push(order[cap])  -- Push final stage List 1 slot forward
            order[cap] = List.new() -- Create new List in previous space
        end

        gm._mod_stage_register(tier, proxy[self])
    end

    -- Remove empty tiers
    for i = #order - 1, 1, -1 do
        local list = List.wrap(order[i])
        if #list <= 0 then
            list:destroy()
            order:delete(i)
        end
    end
end

--[[
Returns a table of tiers the stage is in.
]]
---@return table<number, number>
methods.get_tiers = function(self)
    local order = Global.stage_progression_order  ---@type Array Array of Lists
    local tiers, i = {}, 1
    for tier, list in ipairs(order) do
        list = List.wrap(list)
        if list:contains(self) then
            tiers[i] = tier
            i = i + 1
        end
    end
    return tiers
end

--[[
Returns the room ID of the specified variant.
]]
---@param variant number The stage variant to get the room of. <br>Starts from 1.
---@return number
methods.get_room = function(self, variant)
    local room_list = List.wrap(self.room_list)

    -- Check if variant is out-of-bounds
    if variant < 1 or variant > #room_list then
        throw("Variant must be between 1 and "..(#room_list).." (inclusive)")
        return
    end

    return room_list[variant]
end

--[[
Adds an @link {interactable card(s) | InteractableCard} to the stage's spawn pool. <br>
Does nothing for cards already present.
]]
---@param ... InteractableCard | string A variable number of interactable cards. <br>Alternatively, a table may be provided. <br>Identifier strings may be provided if they are vanilla.
methods.add_interactable = function(self, ...)
    local interactables_list = List.wrap(self.spawn_interactables)

    -- Check if varargs or single table
    local args = {...}
    if type(args[1]) == "table" and (not args[1].RAPI) then args = args[1] end

    -- Add cards
    for i, card in ipairs(args) do
        if type(card) == "string" then
            local str = card
            card = InteractableCard.find(card, "ror", true)
            if not card then
                throw("'"..str.."' is not a vanilla card")
            end
        end
        if not card then throw("card #"..i.." is nil") end
        if not interactables_list:contains(card) then
            interactables_list:add(card)
        end
    end
end

--[[
Removes an @link {interactable card(s) | InteractableCard} from the stage's spawn pool.
]]
---@param ... InteractableCard | string A variable number of interactable cards. <br>Alternatively, a table may be provided. <br>Identifier strings may be provided if they are vanilla.
methods.remove_interactable = function(self, ...)
    local interactables_list = List.wrap(self.spawn_interactables)

    -- Check if varargs or single table
    local args = {...}
    if type(args[1]) == "table" and (not args[1].RAPI) then args = args[1] end

    -- Remove cards
    for i, card in ipairs(args) do
        if type(card) == "string" then
            local str = card
            card = InteractableCard.find(card, "ror", true)
            if not card then
                throw("'"..str.."' is not a vanilla card", 2)
            end
        end
        if not card then throw("card #"..i.." is nil", 2) end
        interactables_list:delete_value(card)
    end
end

--[[
Removes all interactable cards from the stage's spawn pool.
]]
methods.remove_all_interactables = function(self)
    List.wrap(self.spawn_interactables):clear()
end

--[[
Adds an @link {interactable card(s) | InteractableCard} to the stage's post-loop spawn pool. <br>
Does nothing for cards already present.
]]
---@param ... InteractableCard | string A variable number of interactable cards. <br>Alternatively, a table may be provided. <br>Identifier strings may be provided if they are vanilla.
methods.add_interactable_loop = function(self, ...)
    local interactables_list = List.wrap(self.spawn_interactables_loop)

    -- Check if varargs or single table
    local args = {...}
    if type(args[1]) == "table" and (not args[1].RAPI) then args = args[1] end

    -- Add cards
    for i, card in ipairs(args) do
        if type(card) == "string" then
            local str = card
            card = InteractableCard.find(card, "ror", true)
            if not card then
                throw("'"..str.."' is not a vanilla card")
            end
        end
        if not card then throw("card #"..i.." is nil") end
        if not interactables_list:contains(card) then
            interactables_list:add(card)
        end
    end
end

--[[
Removes an @link {interactable card(s) | InteractableCard} from the stage's post-loop spawn pool.
]]
---@param ... InteractableCard | string A variable number of interactable cards. <br>Alternatively, a table may be provided. <br>Identifier strings may be provided if they are vanilla.
methods.remove_interactable_loop = function(self, ...)
    local interactables_list = List.wrap(self.spawn_interactables_loop)

    -- Check if varargs or single table
    local args = {...}
    if type(args[1]) == "table" and (not args[1].RAPI) then args = args[1] end

    -- Remove cards
    for i, card in ipairs(args) do
        if type(card) == "string" then
            local str = card
            card = InteractableCard.find(card, "ror", true)
            if not card then
                throw("'"..str.."' is not a vanilla card")
            end
        end
        if not card then throw("card #"..i.." is nil") end
        interactables_list:delete_value(card)
    end
end

--[[
Removes all interactable cards from the stage's post-loop spawn pool.
]]
methods.remove_all_interactables_loop = function(self)
    List.wrap(self.spawn_interactables_loop):clear()
end

--[[
Adds a @link {monster card(s) | MonsterCard} to the stage's spawn pool. <br>
Does nothing for cards already present.
]]
---@param ... MonsterCard | string A variable number of monster cards. <br>Alternatively, a table may be provided. <br>Identifier strings may be provided if they are vanilla.
methods.add_monster = function(self, ...)
    local enemy_list = List.wrap(self.spawn_enemies)

    -- Check if varargs or single table
    local args = {...}
    if type(args[1]) == "table" and (not args[1].RAPI) then args = args[1] end

    -- Add cards
    for i, card in ipairs(args) do
        if type(card) == "string" then
            local str = card
            card = MonsterCard.find(card, "ror", true)
            if not card then
                throw("'"..str.."' is not a vanilla card")
            end
        end
        if not card then throw("card #"..i.." is nil") end
        if not enemy_list:contains(card) then
            enemy_list:add(card)
        end
    end
end

--[[
Removes a @link {monster card(s) | MonsterCard} from the stage's spawn pool.
]]
---@param ... MonsterCard | string A variable number of monster cards. <br>Alternatively, a table may be provided. <br>Identifier strings may be provided if they are vanilla.
methods.remove_monster = function(self, ...)
    local enemy_list = List.wrap(self.spawn_enemies)

    -- Check if varargs or single table
    local args = {...}
    if type(args[1]) == "table" and (not args[1].RAPI) then args = args[1] end

    -- Remove cards
    for i, card in ipairs(args) do
        if type(card) == "string" then
            local str = card
            card = MonsterCard.find(card, "ror", true)
            if not card then
                throw("'"..str.."' is not a vanilla card")
            end
        end
        if not card then throw("card #"..i.." is nil") end
        enemy_list:delete_value(card)
    end
end

--[[
Removes all monster cards from the stage's spawn pool.
]]
methods.remove_all_monsters = function(self)
    List.wrap(self.spawn_enemies):clear()
end

--[[
Adds a @link {monster card(s) | MonsterCard} to the stage's post-loop spawn pool. <br>
Does nothing for cards already present.
]]
---@param ... MonsterCard | string A variable number of monster cards. <br>Alternatively, a table may be provided. <br>Identifier strings may be provided if they are vanilla.
methods.add_monster_loop = function(self, ...)
    local enemy_list = List.wrap(self.spawn_enemies_loop)

    -- Check if varargs or single table
    local args = {...}
    if type(args[1]) == "table" and (not args[1].RAPI) then args = args[1] end

    -- Add cards
    for i, card in ipairs(args) do
        if type(card) == "string" then
            local str = card
            card = MonsterCard.find(card, "ror", true)
            if not card then
                throw("'"..str.."' is not a vanilla card")
            end
        end
        if not card then throw("card #"..i.." is nil") end
        if not enemy_list:contains(card) then
            enemy_list:add(card)
        end
    end
end

--[[
Removes a @link {monster card(s) | MonsterCard} from the stage's post-loop spawn pool.
]]
---@param ... MonsterCard | string A variable number of monster cards. <br>Alternatively, a table may be provided. <br>Identifier strings may be provided if they are vanilla.
methods.remove_monster_loop = function(self, ...)
    local enemy_list = List.wrap(self.spawn_enemies_loop)

    -- Check if varargs or single table
    local args = {...}
    if type(args[1]) == "table" and (not args[1].RAPI) then args = args[1] end

    -- Remove cards
    for i, card in ipairs(args) do
        if type(card) == "string" then
            local str = card
            card = MonsterCard.find(card, "ror", true)
            if not card then
                throw("'"..str.."' is not a vanilla card")
            end
        end
        if not card then throw("card #"..i.." is nil") end
        enemy_list:delete_value(card)
    end
end

--[[
Removes all monster cards from the stage's post-loop spawn pool.
]]
methods.remove_all_monsters_loop = function(self)
    List.wrap(self.spawn_enemies_loop):clear()
end

--[[
Sets the properties of the mini-planet on the title screen.

If both `objs_back` and `objs_front` are empty, <br>
the default random object sprite set will be used.
]]
---@param ground_strip number | Sprite The sprite to use for the planet's ground (64px x 393px).
---@param objs_back? table<number, number | Sprite> A table of sprites for the random objects on the planet, rendered *behind*.
---@param objs_front? table<number, number | Sprite> A table of sprites for the random objects on the planet, rendered *in front*.
methods.set_title_screen_properties = function(self, ground_strip, objs_back, objs_front)
    stage_populate_biome[proxy[self]] = {
        ground_strip = ground_strip,
        objs_back    = objs_back  or {},
        objs_front   = objs_front or {},
    }
end

--[[
Prints the stage's properties.
]]
methods.print = function(self) end


-- ========== Hooks ==========

-- Title screen mini planet is based on last visited stage
local hook = gm.post_script_hook(gm.constants.callable_call, function(self, other, result, args)
    print("callable_call!")
    
    if #args ~= 3 then return end

    -- Loop through cached property tables
    for id, properties in pairs(stage_populate_biome) do
        local stage = Stage.wrap(id)

        -- Check if stage's populate_biome_properties
        -- matches the current stage being displayed
        if args[1].value == stage.populate_biome_properties.value then
            local struct = Struct.wrap(args[3].value)

            struct.ground_strip = properties.ground_strip

            local obj_sprites      = {}
            local force_draw_depth = {}

            -- Process back sprites
            for _, sprite in ipairs(properties.objs_back) do
                table_insert(obj_sprites, sprite)
            end

            -- Process front sprites
            for _, sprite in ipairs(properties.objs_front) do
                table_insert(obj_sprites, sprite)
                table_insert(force_draw_depth, sprite)
            end

            -- Use default set if no sprites provided
            if #obj_sprites <= 0 then return end

            -- Modify struct properties
            local array = Array.wrap(struct.obj_sprites)
            array:clear()
            array:push(table_unpack(obj_sprites))

            -- Mark front sprites in force_draw_depth
            -- TODO: This part might not be working correctly
            for _, sprite in ipairs(force_draw_depth) do
                struct.force_draw_depth[tostring(math(unwrap(sprite)))] = true
            end

            return
        end
    end
end)

gm.post_script_hook(gm.constants.run_create, function(self, other, result, args)
    gm.hook_disable(hook)
end)
gm.pre_script_hook(gm.constants.run_destroy, function(self, other, result, args)
    gm.hook_enable(hook)
end)