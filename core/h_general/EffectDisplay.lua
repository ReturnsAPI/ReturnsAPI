-- EffectDisplay

---@class EffectDisplay
EffectDisplay = new_class()
C.EffectDisplay = EffectDisplay

local struct_new  = Struct.new
local script_bind = Script.bind
local unwrap      = Wrap.unwrap

local efdis_sprite 	  = gm.constants.EffectDisplaySprite   ---@type number
local efdis_function  = gm.constants.EffectDisplayFunction ---@type number
local efdis_instance  = gm.constants.EffectDisplayInstance ---@type number
local efdis_particles = gm.constants.EffectDisplayParticles ---@type number


-- ========== Enums ==========

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
    POST            = -1000,
    BARRIER_ABOVE   = -1020,
}


-- ========== Static Methods ==========

--[[
Returns a EffectDisplaySprite struct.
]]
---@param sprite number | Sprite The sprite.
---@param priority? number The @link {draw priority | EffectDisplay#DrawPriority}. <br>`EffectDisplay.DrawPriority.ABOVE` by default.
---@param anim_speed? number The animation speed. <br>`0` by default.
---@param x_origin? number The x coordinate of the origin (offset). <br>`0` by default.
---@param y_origin? number The y coordinate of the origin (offset). <br>`0` by default.
---@return Struct
EffectDisplay.sprite = function(sprite, priority, anim_speed, x_offset, y_offset)
    return struct_new(efdis_sprite,
        unwrap(sprite),
        priority   or EffectDisplay.DrawPriority.ABOVE,
        anim_speed or 0,
        x_offset   or 0,
        y_offset   or 0
    )
end

--@static
--@return       Struct
--[[
Returns a EffectDisplayFunction struct.
]]
---@param func function The function to bind.
---@param priority? number The @link {draw priority | EffectDisplay#DrawPriority}. <br>`EffectDisplay.DrawPriority.BODY` by default.
---@return Struct
EffectDisplay.func = function(func, priority)
    local bind = script_bind(func)
    return struct_new(efdis_function,
        bind,
        priority or EffectDisplay.DrawPriority.BODY
    )
end

--@static
--[[
Returns a EffectDisplayInstance struct.
]]
---@param object number | Object The object.
---@param host_only? boolean `false` by default.
---@return Struct
EffectDisplay.instance = function(object, host_only)
    return struct_new(efdis_instance,
        unwrap(object),
        nil,  -- This is supposed to be a function that is called when the EffectDisplayInstance comes into existence
        host_only or false
    )
end

--[[
Returns a EffectDisplayParticles struct.
]]
---@param particle_type	number | Particle The particle type.
---@param rate number
---@param amount number
---@param system? number The @link {particle system | Particle#System} to use. <br>`Particle.System.ABOVE` by default.
---@param xrand? number `0` by default.
---@param yrand? number `0` by default.
---@param color? number The color to blend with. <br>`Color.WHITE` by default.
---@return Struct
EffectDisplay.particles = function(particle_type, rate, amount, system, xrand, yrand, color)
    return struct_new(efdis_particles,
        unwrap(particle_type),
        rate,
        amount,
        system or Particle.System.ABOVE,
        color  or Color.WHITE,
        xrand  or 0,
        yrand  or 0
    )
end