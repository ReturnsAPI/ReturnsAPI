--[[
Generates correct palettes from baked-in spritestrips
and saves them to AppData/Roaming/Risk_of_Rain_Returns.

These are VERY slow!
]]

local chars = {
    "Commando",
    "Huntress",
    "Enforcer",
    "Bandit",
    "HAND",
    "Engi",
    "Miner",
    "Sniper",
    "Acrid",
    "Mercenary",
    "Loader",
    "Chef",
    "Pilot",
    "Arti",
    "Robomando",

    -- Drifter is weird
    -- "Drifter",
}

gui.add_to_menu_bar(function()
    if ImGui.Button("Generate loadout palettes") then
        for _, char in ipairs(chars) do
            print("")
            print("Now processing "..char)

            local mapping = {}
            local mapping_pos = {}
            local mapping_total = 0
            
            local default = Sprite.wrap(gm.constants["sSelect"..char])
            local w       = default.width
            local h       = default.height
            local imgs    = default.subimages

            print("w: "..w..", h: "..h..", imgs: "..imgs)
            print("Drawing default 'sSelect"..char.."' to surface...")

            -- Draw default palette onto surface
            local def = gm.surface_create(w * imgs, h)
            gm.surface_set_target(def)
            for img = 0, imgs - 1 do
                gm.draw_sprite(default.value, img, w * img, 0)
            end
            gm.surface_reset_target()

            print("Getting every unique color...")

            -- Get every unique color and store their coordinates
            for y = 0, h - 1 do
                for x = 0, (w * imgs) - 1 do
                    local col = gm.surface_getpixel(def, x, y)
                    if not mapping[col] then
                        mapping[col] = {}
                        mapping_pos[col] = {x = x, y = y}
                        mapping_total = mapping_total + 1
                    end
                end
            end

            -- Get palette count
            -- Last one is Judgement
            local count = 0
            repeat count = count + 1
            until (not gm.constants["sSelect"..char.."_PAL"..count])

            -- Edge case: Engi_PAL4 is unused
            if char == "Engi" then count = count - 1 end

            for i = 1, count do
                local name = "sSelect"..char.."_PAL"..i
                if i == count then name = "sSelect"..char.."_PROV" end

                print("Drawing alt palette '"..name.."' to surface...")

                -- Draw baked-in alt palette onto surface
                local alt = gm.surface_create(w * imgs, h)
                gm.surface_set_target(alt)
                for img = 0, imgs - 1 do
                    gm.draw_sprite(gm.constants[name], img, w * img, 0)
                end
                gm.surface_reset_target()

                print("Comparing differing pixels...")

                -- Compare differing pixels at stored coordinates
                for col_def, pos in pairs(mapping_pos) do
                    local col_alt = gm.surface_getpixel(alt, pos.x, pos.y)

                    -- If differing, save to mapping
                    if col_def ~= col_alt then
                        mapping[col_def][i] = col_alt
                        mapping[col_def].has_any = true
                    end
                end
                gm.surface_free(alt)
            end
            gm.surface_free(def)

            -- Create palette
            print("Creating draft surface...")
            local pal = gm.surface_create(1 + count, mapping_total)
            gm.surface_set_target(pal)

            print("Drawing colors to draft surface...")

            local y = 0
            for col_def, col_alts in pairs(mapping) do
                if col_alts.has_any then
                    gm.draw_point_color(0, y, col_def)

                    for i = 1, count do
                        local col = col_alts[i]
                        if not col then col = col_def end
                        gm.draw_point_color(i, y, col)
                    end

                    y = y + 1
                end
            end
            gm.surface_reset_target()

            print("Creating output surface...")
            local out = gm.surface_create(1 + count, y)
            gm.surface_set_target(out)

            print("Drawing draft surface to output surface...")
            gm.draw_surface(pal, 0, 0)

            gm.surface_reset_target()
            
            print("Saving output surface as PNG...")
            gm.surface_save(out, "sSelect"..char.."Palette.png")

            gm.surface_free(pal)
            gm.surface_free(out)

            print(char.." complete!")
        end
    end
end)