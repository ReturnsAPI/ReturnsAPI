-- Stage

local name_rapi = class_name_g2r["class_stage"]
Stage = __class[name_rapi]

run_once(function()
    __stage_variant_next_id = {}    -- Stores the next identifier `_ID` to use for each stage; [stage_id] = <next>
                                    -- This is to not reuse previously used variant IDs if the variant is removed from the stage
    __stage_new_rooms = {}          -- Stores new rooms added (for removal purposes)
    __stage_populate_biome = {}
end)



-- ========== Enums ==========

--@section Enums

--@enum
--@name Property
--[[
NAMESPACE                   0
IDENTIFIER                  1
TOKEN_NAME                  2
TOKEN_SUBNAME               3
SPAWN_ENEMIES               4
SPAWN_ENEMIES_LOOP          5
SPAWN_INTERACTABLES         6
SPAWN_INTERACTABLES_LOOP    7
SPAWN_INTERACTABLE_RARITY   8
INTERACTABLE_SPAWN_POINTS   9
ALLOW_MOUNTAIN_SHRINE_SPAWN 10
CLASSIC_VARIANT_COUNT       11
IS_NEW_STAGE                12
ROOM_LIST                   13
MUSIC_ID                    14
TELEPORTER_INDEX            15
POPULATE_BIOME_PROPERTIES   16
LOG_ID                      17
]]



-- ========== Properties ==========

--@section Properties

--[[
Property | Type | Description
| - | - | -
`namespace`                     | string    | The namespace the stage is in.
`identifier`                    | string    | The identifier for the stage within the namespace.
`token_name`                    | string    | The localization token for the stage's name.
`token_subname`                 | string    | The localization token for the stage's subname.
`spawn_enemies`                 |           | 
`spawn_enemies_loop`            |           | 
`spawn_interactables`           |           | 
`spawn_interactables_loop`      |           | 
`spawn_interactable_rarity`     |           | 
`interactable_spawn_points`     |           | 
`allow_mountain_shrine_spawn`   |           | 
`classic_variant_count`         |           | 
`is_new_stage`                  | bool      | 
`room_list`                     | number    | The ID of a list containing the rooms (variants) of the stage.
`music_id`                      | number    | The ID of the sound to play as background music.
`teleporter_index`              |           | 
`populate_biome_properties`     |           | 
`log_id`                        | number    | The environment log ID of the stage.
]]



-- ========== Internal ==========

Stage.internal.initialize = function()
    -- Get current variant count for each stage
    for i, stage in ipairs(Class.Stage) do
        __stage_variant_next_id[i - 1] = List.wrap(stage:get(13)):size() + 1
    end
end
table.insert(_rapi_initialize, Stage.internal.initialize)



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return   Stage
--@param    identifier  | string    | The identifier for the stage.
--[[
Creates a new stage with the given identifier if it does not already exist,
or returns the existing one if it does.
]]
Stage.new = function(NAMESPACE, identifier)
    Initialize.internal.check_if_started()
    if not identifier then log.error("No identifier provided", 2) end

    -- Return existing stage if found
    local stage = Stage.find(identifier, NAMESPACE)
    if stage then return stage end

    -- Create new
    stage = Stage.wrap(gm.stage_create(
        NAMESPACE,
        identifier
    ))

    -- Remove `is_new_stage` flag
    stage.is_new_stage = false

    return stage
end


--@static
--@name         find
--@return       Stage or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified stage and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]


--@static
--@name         find_all
--@return       table
--@param        filter      |           | The filter to search by.
--@optional     property    | number    | The property to check. <br>@link {`Stage.Property.NAMESPACE` | Stage#Property} by default.
--[[
Returns a table of stages matching the specified filter and property.

**NOTE:** Filtering by a non-namespace property is *very slow*!
Try not to do that too much.
]]


--@static
--[[
Prints the stage progression order.
]]
Stage.print_tiers = function()
    local order = Global.stage_progression_order    -- Array of Lists
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


--@static
--@param        ...         |           | A variable number of paths.
--[[
Adds a new room(s) to the stage, and adds it as
a variant to the environment log (if applicable).
]]
Stage.add_room = function(NAMESPACE, stage, ...)
    local self = Stage.wrap(stage)
    local id = self.value

    local identifier = self.identifier
    local room_list = List.wrap(self.room_list)

    __stage_new_rooms[NAMESPACE] = __stage_new_rooms[NAMESPACE] or {}

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
        -- Load room and add to list
        local room = gm.stage_load_room(NAMESPACE, identifier.."_"..__stage_variant_next_id[id], path)
        room_list:add(room)

        __stage_variant_next_id[id] = __stage_variant_next_id[id] + 1

        table.insert(__stage_new_rooms[NAMESPACE], {
            stage   = id,
            room_id = room
        })

        -- Associate environment log (if applicable)
        if display_room_ids then
            display_room_ids:push(room)
            gm.room_associate_environment_log(room, log_id, num)
        end
    end
end


--@static
--[[
Removes all rooms (variants) added from your mod.

Automatically called when you hotload your mod.
]]
Stage.remove_all_rooms = function(NAMESPACE)
    if not __stage_new_rooms[NAMESPACE] then return end

    for _, t in ipairs(__stage_new_rooms[NAMESPACE]) do
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

    __stage_new_rooms[NAMESPACE] = nil
end


--@static
--@name         wrap
--@return       Stage
--@param        stage_id    | number    | The stage ID to wrap.
--[[
Returns a Stage wrapper containing the provided stage ID.
]]



-- ========== Instance Methods ==========

--@section Instance Methods

Util.table_append(methods_class_array[name_rapi], {

    --@instance
    --@optional     ...         |           | A variable number of tiers. <br>Alternatively, a table may be provided. <br>If not provided, removes stage from progression.
    --[[
    Adds the stage to the specified tiers after removing it from its previous ones.
    If *no arguments* are provided, removes the stage from progression.
    
    A new tier may be created by providing a tier 1 higher than the current count.
    (E.g., By default, there are 5 tiers of progression, excluding the final stage;
    assigning the stage to tier 6 will add another one.)
    ]]
    set_tier = function(self, ...)
        local order = Global.stage_progression_order    -- Array of Lists

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
                log.error("set_tier: Stage tier should be between 1 and "..(cap - 1).." (current count, inclusive), or "..cap.." to add a new tier.", 2)
            end

            -- Add a new tier
            if tier == cap then
                order:push(order[cap])  -- Push final stage List 1 slot forward
                order[cap] = List.new() -- Create new List in previous space
            end

            gm._mod_stage_register(tier, self.value)
        end

        -- Remove empty tiers
        for i = #order - 1, 1, -1 do
            local list = List.wrap(order[i])
            if #list <= 0 then
                list:destroy()
                order:delete(i)
            end
        end
    end,


    get_room = function(self, variant)
        local room_list = List.wrap(self.room_list)

        if variant < 1 or variant > #room_list then
            log.error("Variant must be between 1 and "..(#room_list).." (inclusive)", 2)
            return
        end

        return room_list[variant]
    end,


    -- TODO populate rest of methods

})



-- ========== Hooks ==========

-- Title screen mini planet is based on last visited stage

gm.post_script_hook(gm.constants.callable_call, function(self, other, result, args)
    if #args ~= 3 then return end

    for id, t in pairs(__stage_populate_biome) do
        local stage = Stage.find(id)
        if args[1].value == stage.populate_biome_properties then
            local struct = args[3].value

            struct.ground_strip = t.ground_strip

            if t.obj_sprites then
                local array = Array.wrap(struct.obj_sprites)
                array:clear()
                for _, spr in ipairs(t.obj_sprites) do
                    array:push(spr)
                end
            end

            if t.force_draw_depth then
                for _, v in ipairs(t.force_draw_depth) do
                    struct.force_draw_depth[tostring(math.floor(v))] = true
                end
            end

            break
        end
    end
end)