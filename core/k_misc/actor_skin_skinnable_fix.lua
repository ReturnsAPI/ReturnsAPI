-- Fix crash related to assigning nil palette

Hook.add_pre(RAPI_NAMESPACE, gm.constants.init_actor_default, function(self, other, result, args)
    self:actor_skin_skinnable_init()
end)