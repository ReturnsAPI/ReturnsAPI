-- EffectDisplay

EffectDisplay = new_class()



-- ========== Enums ==========

--@section Enums

--@enum
EffectDisplay.DrawPriority = {
	BARRIER_BEHIND  = 1020,
	HIDDEN_BEHIND   = 1010,
	PRE             = 1000,
	BEHIND          = 100,
	CAPE            = 20,
	BODY_PRE        = 10,
	BODY            = 0,
	HITFLASH        = -1,
	HIDDEN_ABOVE    = -5,
	BODY_POST       = -10,
	BODY_FREEZE     = -15,
	CAPE_ABOVE      = -20,
	ABOVE_BODY      = -100,
	ABOVE           = -200,
	PAST            = -1000,
	BARRIER_ABOVE   = -1020
}



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       Struct
--@param        sprite		| sprite   	| The sprite ID.
--@optional		priority	| number 	| The @link {draw priority | EffectDisplay#DrawPriority}. <br>`EffectDisplay.DrawPriority.ABOVE` by default.
--@optional     anim_speed 	| number    | The animation speed. <br>`0` by default.
--@optional     x_origin  	| number    | The x coordinate of the origin (offset). <br>`0` by default.
--@optional     y_origin  	| number    | The y coordinate of the origin (offset). <br>`0` by default.
--[[
Returns a EffectDisplaySprite struct.
]]
EffectDisplay.sprite = function(sprite_id, priority, anim_speed, x_offset, y_offset)
	return Struct.new(gm.constants.EffectDisplaySprite,
		sprite_id,
		priority 	or EffectDisplay.DrawPriority.ABOVE,
		anim_speed 	or 0,
		x_offset 	or 0,
		y_offset 	or 0
	)
end


--@static
--@return       Struct
--@param        func		| function	| The function to bind.
--@optional		priority	| number 	| The @link {draw priority | EffectDisplay#DrawPriority}. <br>`EffectDisplay.DrawPriority.BODY` by default.
--[[
Returns a EffectDisplayFunction struct.
]]
EffectDisplay.func = function(func, priority)
	local bind = Script.bind(func)
	return Struct.new(gm.constants.EffectDisplayFunction,
		bind,
		priority 	or EffectDisplay.DrawPriority.BODY
	)
end


--@static
--@return       Struct
--@param        object		| Object	| The object.
--@optional		host_only	| bool		| desc. <br>`false` by default.
--[[
Returns a EffectDisplayInstance struct.
]]
EffectDisplay.instance = function(object, host_only)
	return Struct.new(gm.constants.EffectDisplayInstance,
		object,
		nil,
		host_only	or false
	)
end


--@static
--@return       Struct
--@param        particle_type	| Particle	| The particle type.
--@param        rate			| number	| 
--@param        amount			| number	| 
--@optional     system			| number	| The @link {particle system | Particle#System} to use. <br>`Particle.System.ABOVE` by default.
--@optional     xrand			| number	| 
--@optional     yrand			| number	| 
--@optional     color			| color		| The color to blend with. <br>`Color.WHITE` by default.
--[[
Returns a EffectDisplayParticles struct.
]]
EffectDisplay.particles = function(particle_type, rate, amount, system, xrand, yrand, color)
	return Struct.new(gm.constants.EffectDisplayParticles,
		particle_type,
		rate,
		amount,
		system		or Particle.System.ABOVE,
		color		or Color.WHITE,
		xrand 		or 0,
		yrand 		or 0
	)
end



-- Public export
__class.EffectDisplay = EffectDisplay