-- EffectDisplay

EffectDisplay = new_class()

EffectDisplay.DrawPriority = ReadOnly.new({
	BARRIER_BEHIND = 1020,
	HIDDEN_BEHIND = 1010,
	PRE = 1000,
	BEHIND= 100,
	CAPE = 20,
	BODY_PRE = 10,
	BODY = 0,
	HITFLASH = -1,
	HIDDEN_ABOVE = -5,
	BODY_POST = -10,
	BODY_FREEZE = -15,
	CAPE_ABOVE = -20,
	ABOVE_BODY = -100,
	ABOVE = -200,
	PAST = -1000,
	BARRIER_ABOVE = -1020,
})


EffectDisplay.sprite = function(sprite_id, priority, anim_speed, x_offset, y_offset)
	local struct = gm["@@NewGMLObject@@"](gm.constants.EffectDisplaySprite, sprite_id, priority or -200, anim_speed or 0, x_offset or 0, y_offset or 0)

	return struct
end

EffectDisplay.func = function(func, priority)
	local bind = bind_lua_to_cscriptref(func)
	local struct = gm["@@NewGMLObject@@"](gm.constants.EffectDisplayFunction, bind, priority or 0)

	return struct
end

EffectDisplay.instance = function(object, host_only)
	local struct = gm["@@NewGMLObject@@"](gm.constants.EffectDisplayInstance, Wrap.unwrap(object), nil, host_only or false)

	return struct
end

EffectDisplay.particles = function(particle_type, rate, amount, partlayer, xrand, yrand, color)
	local struct = gm["@@NewGMLObject@@"](gm.constants.EffectDisplayParticles, Wrap.unwrap(particle_type), rate, amount, partlayer, color or Color.WHITE, xrand or 0, yrand or 0)

	return struct
end

_CLASS["EffectDisplay"] = EffectDisplay
