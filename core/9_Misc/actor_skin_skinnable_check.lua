-- Prevent `actor_skin_skinnable_set_skin`
-- from assigning a nil value to palette

gm.pre_script_hook(gm.constants.actor_skin_skinnable_set_skin, function(self, other, result, args)
    if not args[1].value.sprite_palette then return false end
end)