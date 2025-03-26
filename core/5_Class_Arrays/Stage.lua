-- Stage

-- TODO populate methods
if true then return end

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

methods_stage = {    

    

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