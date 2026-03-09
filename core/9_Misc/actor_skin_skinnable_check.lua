-- Prevent `actor_skin_skinnable_set_skin`
-- from assigning a nil value to palette

Hook.add_pre(gm.constants.actor_skin_skinnable_set_skin, function(self, other, result, args)
    if not args[1].value.sprite_palette then return false end
end)