-- Portrait/loadout replacements

--[[
For some reason, the original Huntress portrait sprites have way
too many colors that are just a few hex values off from each other
]]
gm.sprite_replace(gm.constants["sHuntressPortrait"], path.combine(PATH, "core/sprites/portrait_replacements/sHuntressPortrait.png"), 3, false, false, 0, 0)
gm.sprite_replace(gm.constants["sHuntressPortraitSmall"], path.combine(PATH, "core/sprites/portrait_replacements/sHuntressPortraitSmall.png"), 1, false, false, 0, 0)

--[[
Miner shares a color with the light which makes replacing it impossible
]]
gm.sprite_replace(gm.constants["sSelectMiner"], path.combine(PATH, "core/sprites/portrait_replacements/sSelectMiner.png"), 17, false, false, 28, 0)