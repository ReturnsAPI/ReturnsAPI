-- Stage

local rapi_name = class_gm_to_rapi["class_stage"]
Stage = __class[rapi_name]

if not __stage_populate_biome then __stage_populate_biome = {} end  -- Preserve on hotload



-- ========== Static Methods ==========

Stage.new = function(namespace, identifier)
    Initialize.internal.check_if_done()
    if not identifier then log.error("No identifier provided", 2) end

    -- Return existing stage if found
    local stage = Stage.find(identifier, namespace)
    if stage then return stage end

    -- Create new
    stage = Stage.wrap(GM.stage_create(
        namespace,
        identifier
    ))

    return stage
end



-- ========== Instance Methods ==========

methods_class[rapi_name] = {

    --$instance
    --$optional     ...     |           | A variable number of tiers. <br>Alternatively, a table may be provided.
    --[[
    Adds the stage to the specified tiers after removing it from its previous ones.
    If no arguments are provided, removes the stage from progression.
    
    A new tier may be created by providing a tier 1 higher than the current count.
    (E.g., By default, there are 5 tiers of progression, excluding the final stage;
    assigning the stage to tier 6 will add another one.)
    ]]
    set_tier = function(self, ...)
        local order = Global.stage_progression_order    -- Array of Lists

        -- Remove from existing tier(s)
        for _, list_id in ipairs(order) do
            local list = List.wrap(list_id)
            list:delete_value(self.value)
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

            GM._mod_stage_register(tier, self.value)
        end

        -- Remove empty tiers
        for i = #order - 1, 1, -1 do
            if #order[i] <= 0 then order:delete(i) end
        end
    end,

    -- TODO populate rest of methods

}



-- ========== Hooks ==========

-- TODO convert to dynamic hook

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