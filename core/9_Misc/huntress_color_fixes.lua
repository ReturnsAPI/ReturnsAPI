-- Huntress color fixes (for portrait sprites)

--[[
For some reason, the original sprites have way too many
colors that are just a few hex values off from each other
]]

gm.sprite_replace(gm.constants["sHuntressPortrait"], path.combine(PATH, "core/data/huntress_color_fixes/sHuntressPortrait.png"), 3, false, false, 0, 0)
gm.sprite_replace(gm.constants["sHuntressPortraitSmall"], path.combine(PATH, "core/data/huntress_color_fixes/sHuntressPortraitSmall.png"), 1, false, false, 0, 0)