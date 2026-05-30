-- Particle

---@class ParticleClass
Particle = new_class()
C.Particle = Particle

run_on_initial_load(function()
    P.part_find_table = FindTable.new()
end)

local part_find_table = P.part_find_table

local proxy = P.proxy
local metatable

local gm        = gm  ---@type table<string, function>
local new_proxy = new_proxy
local unwrap    = Wrap.unwrap


-- ========== Enums ==========

Particle.System = {
    ABOVE        = 0,
    BELOW        = 1,
    MIDDLE       = 2,
    BACKGROUND   = 3,
    VERYABOVE    = 4,
    DAMAGE       = 5,
    DAMAGE_ABOVE = 6,
}

Particle.Shape = {
    PIXEL     = 0,
    DISK      = 1,
    SQUARE    = 2,
    LINE      = 3,
    STAR      = 4,
    CIRCLE    = 5,
    RING      = 6,
    SPHERE    = 7,
    FLARE     = 8,
    SPARK     = 9,
    EXPLOSION = 10,
    CLOUD     = 11,
    SMOKE     = 12,
    SNOW      = 13,
}


-- ========== Internal ==========

local function populate_find_table()
    -- Populate find table with vanilla particles
    local resource_manager = Map.wrap(Global.ResourceManager_particleTypes.__namespacedAssetLookup)
    
    for identifier, part in pairs(Map.wrap(resource_manager["ror"])) do
        local wrapper = Particle.wrap(part)
        part_find_table:set(wrapper, identifier, "ror", part)
    end
end
run_on_initialize(populate_find_table)


-- ========== Static Methods ==========

--@section Static Methods

--[[
Creates a new particle type with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the particle type.
---@return Particle
Particle.new = function(NAMESPACE, identifier)
    -- Return existing particle if found
    local part = Particle.find(identifier, NAMESPACE, true)
    if part then return part end

    -- Create new particle
    local part = gm.part_type_create_w(NAMESPACE, identifier)

    -- Adding to find table is done in the hook at the bottom

    return Particle.wrap(part)
end

--[[
Searches for the specified particle and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return Particle | nil
Particle.find = function(identifier, namespace, namespace_is_specified)
    return part_find_table:get(identifier, namespace, namespace_is_specified)
end

--[[
Returns a table of all particles in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param namespace? string The namespace to search in.
---@return table<number, Particle>
Particle.find_all = function(namespace, namespace_is_specified)
    return part_find_table:get_all(namespace, namespace_is_specified)
end

--[[
Returns a Particle wrapper containing the provided particle type.
]]
---@param id number | Particle The particle type to wrap.
---@return Particle
Particle.wrap = function(id)
    return new_proxy(unwrap(id), metatable)
end


-- ========== Wrapper Methods ==========

---@class Particle
local methods = {}

--[[
Spawns particles at the specified location.
]]
---@param x number The x coordinate to spawn at.
---@param y number The y coordinate to spawn at.
---@param count? number The number of particles to spawn. <br>`1` by default.
---@param system? number The @link {particle system | Particle#System} to use. <br>`Particle.System.ABOVE` by default.
methods.create = function(self, x, y, count, system)
    if not x then throw("x is nil") end
    if not y then throw("y is nil") end

    gm.part_particles_create(
        system or Particle.System.ABOVE,
        x,
        y,
        proxy[self],
        count or 1
    )
end

--[[
Spawns colored particles at the specified location.
]]
---@param x number The x coordinate to spawn at.
---@param y number The y coordinate to spawn at.
---@param color? number The color to blend. <br>`Color.WHITE` by default.
---@param count? number The number of particles to spawn. <br>`1` by default.
---@param system? number The @link {particle system | Particle#System} to use. <br>`Particle.System.ABOVE` by default.
methods.create_color = function(self, x, y, color, count, system)
    if not x then throw("x is nil") end
    if not y then throw("y is nil") end

    gm.part_particles_create_color(
        system or Particle.System.ABOVE, 
        x,
        y,
        proxy[self],
        color or Color.WHITE,
        count or 1
    )
end

--[[
Spawns colored particles at the specified location.
]]
---@param x number The x coordinate to spawn at.
---@param y number The y coordinate to spawn at.
---@param color? number The color to blend. <br>`Color.WHITE` by default.
---@param count? number The number of particles to spawn. <br>`1` by default.
---@param system? number The @link {particle system | Particle#System} to use. <br>`Particle.System.ABOVE` by default.
methods.create_colour = function(self, x, y, color, count, system)
    if not x then throw("x is nil") end
    if not y then throw("y is nil") end
    self:create_color(x, y, color, count, system)
end

-- [GameMaker particle type docs](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm)
---@param shape number
methods.set_shape = function(self, shape)
    GM.part_type_shape(self, shape)
end

-- [GameMaker particle type docs](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm)
---@param sprite number | Sprite
---@param animate boolean
---@param stretch boolean
---@param random boolean
methods.set_sprite = function(self, sprite, animate, stretch, random)
    GM.part_type_sprite(self, sprite, animate, stretch, random)
end

-- [GameMaker particle type docs](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm)
---@param subimg number
methods.set_subimage = function(self, subimg)
    GM.part_type_subimage(self, subimg)
end

-- [GameMaker particle type docs](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm)
---@param size_min number
---@param size_max number
---@param size_incr number
---@param size_wiggle number
methods.set_size = function(self, size_min, size_max, size_incr, size_wiggle)
    GM.part_type_size(self, size_min, size_max, size_incr, size_wiggle)
end

-- [GameMaker particle type docs](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm)
---@param size_min_x number
---@param size_max_x number
---@param size_incr_x number
---@param size_wiggle_x number
methods.set_size_x = function(self, size_min_x, size_max_x, size_incr_x, size_wiggle_x)
    GM.part_type_size_x(self, size_min_x, size_max_x, size_incr_x, size_wiggle_x)
end

-- [GameMaker particle type docs](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm)
---@param size_min_y number
---@param size_max_y number
---@param size_incr_y number
---@param size_wiggle_y number
methods.set_size_y = function(self, size_min_y, size_max_y, size_incr_y, size_wiggle_y)
    GM.part_type_size_y(self, size_min_y, size_max_y, size_incr_y, size_wiggle_y)
end

-- [GameMaker particle type docs](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm)
---@param xscale number
---@param yscale number
methods.set_scale = function(self, xscale, yscale)
    GM.part_type_scale(self, xscale, yscale)
end

-- [GameMaker particle type docs](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm)
---@param speed_min number
---@param speed_max number
---@param speed_incr number
---@param speed_wiggle number
methods.set_speed = function(self, speed_min, speed_max, speed_incr, speed_wiggle)
    GM.part_type_speed(self, speed_min, speed_max, speed_incr, speed_wiggle)
end

-- [GameMaker particle type docs](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm)
---@param dir_min number
---@param dir_max number
---@param dir_incr number
---@param dir_wiggle number
methods.set_direction = function(self, dir_min, dir_max, dir_incr, dir_wiggle)
    GM.part_type_direction(self, dir_min, dir_max, dir_incr, dir_wiggle)
end

-- [GameMaker particle type docs](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm)
---@param grav_amount number
---@param grav_direction number
methods.set_gravity = function(self, grav_amount, grav_direction)
    GM.part_type_gravity(self, grav_amount, grav_direction)
end

-- [GameMaker particle type docs](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm)
---@param ang_min number
---@param ang_max number
---@param ang_incr number
---@param ang_wiggle number
---@param ang_relative number
methods.set_orientation = function(self, ang_min, ang_max, ang_incr, ang_wiggle, ang_relative)
    GM.part_type_orientation(self, ang_min, ang_max, ang_incr, ang_wiggle, ang_relative)
end

-- [GameMaker particle type docs](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm)
---@param color1 number
---@param color2 number
methods.set_color_mix = function(self, color1, color2)
    GM.part_type_color_mix(self, color1, color2)
end

-- [GameMaker particle type docs](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm)
---@param color1 number
---@param color2 number
methods.set_colour_mix = function(self, color1, color2)
    GM.part_type_color_mix(self, color1, color2)
end

-- [GameMaker particle type docs](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm)
---@param rmin number
---@param rmax number
---@param gmin number
---@param gmax number
---@param bmin number
---@param bmax number
methods.set_color_rgb = function(self, rmin, rmax, gmin, gmax, bmin, bmax)
    GM.part_type_color_rgb(self, rmin, rmax, gmin, gmax, bmin, bmax)
end

-- [GameMaker particle type docs](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm)
---@param rmin number
---@param rmax number
---@param gmin number
---@param gmax number
---@param bmin number
---@param bmax number
methods.set_colour_rgb = function(self, rmin, rmax, gmin, gmax, bmin, bmax)
    GM.part_type_color_rgb(self, rmin, rmax, gmin, gmax, bmin, bmax)
end

-- [GameMaker particle type docs](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm)
---@param hmin number
---@param hmax number
---@param smin number
---@param smax number
---@param vmin number
---@param vmax number
methods.set_color_hsv = function(self, hmin, hmax, smin, smax, vmin, vmax)
    GM.part_type_color_hsv(self, hmin, hmax, smin, smax, vmin, vmax)
end

-- [GameMaker particle type docs](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm)
---@param hmin number
---@param hmax number
---@param smin number
---@param smax number
---@param vmin number
---@param vmax number
methods.set_colour_hsv = function(self, hmin, hmax, smin, smax, vmin, vmax)
    GM.part_type_color_hsv(self, hmin, hmax, smin, smax, vmin, vmax)
end

-- [GameMaker particle type docs](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm)
---@param color1 number
methods.set_color1 = function(self, color1)
    GM.part_type_color1(self, color1)
end

-- [GameMaker particle type docs](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm)
---@param color1 number
methods.set_colour1 = function(self, color1)
    GM.part_type_color1(self, color1)
end

-- [GameMaker particle type docs](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm)
---@param color1 number
---@param color2 number
methods.set_color2 = function(self, color1, color2)
    GM.part_type_color2(self, color1, color2)
end

-- [GameMaker particle type docs](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm)
---@param color1 number
---@param color2 number
methods.set_colour2 = function(self, color1, color2)
    GM.part_type_color2(self, color1, color2)
end

-- [GameMaker particle type docs](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm)
---@param color1 number
---@param color2 number
---@param color3 number
methods.set_color3 = function(self, color1, color2, color3)
    GM.part_type_color3(self, color1, color2, color3)
end

-- [GameMaker particle type docs](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm)
---@param color1 number
---@param color2 number
---@param color3 number
methods.set_colour3 = function(self, color1, color2, color3)
    GM.part_type_color3(self, color1, color2, color3)
end

-- [GameMaker particle type docs](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm)
---@param alpha1 number
methods.set_alpha1 = function(self, alpha1)
    GM.part_type_alpha1(self, alpha1)
end

-- [GameMaker particle type docs](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm)
---@param alpha1 number
---@param alpha2 number
methods.set_alpha2 = function(self, alpha1, alpha2)
    GM.part_type_alpha2(self, alpha1, alpha2)
end

-- [GameMaker particle type docs](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm)
---@param alpha1 number
---@param alpha2 number
---@param alpha3 number
methods.set_alpha3 = function(self, alpha1, alpha2, alpha3)
    GM.part_type_alpha3(self, alpha1, alpha2, alpha3)
end

-- [GameMaker particle type docs](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm)
---@param additive boolean
methods.set_blend = function(self, additive)
    GM.part_type_blend(self, additive)
end

-- [GameMaker particle type docs](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm)
---@param life_min number
---@param life_max number
methods.set_life = function(self, life_min, life_max)
    GM.part_type_life(self, life_min, life_max)
end

-- [GameMaker particle type docs](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm)
---@param step_number number
---@param step_type number
methods.set_step = function(self, step_number, step_type)
    GM.part_type_step(self, step_number, step_type)
end

-- [GameMaker particle type docs](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm)
---@param death_number number
---@param death_type number
methods.set_death = function(self, death_number, death_type)
    GM.part_type_death(self, death_number, death_type)
end


-- ========== Metatables ==========

---@class Particle
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field namespace string The namespace of the particle type.
---@field identifier string The identifier of the particle type.

local mt_name = "Particle"

W.Particle = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return proxy[t] end
        if k == "RAPI" then return mt_name end

        -- Methods
        local method = methods[k]
        if method then return method end

        -- Getter
        return part_find_table[proxy[t]][k]
    end,

    __newindex = function(t, k, v)
        log.error(mt_name.." has no properties to set", 2)
    end,

    __metatable = mt_wrapper_name(mt_name),
}
metatable = W.Particle


-- ========== Hooks ==========

-- Add new particles to find table
gm.post_script_hook(gm.constants.part_type_create_w, function(self, other, result, args)
    local id = result.value
    if id == -1 then return end

    part_find_table:set(
        Particle.wrap(id),
        args[2].value,  -- identifier
        args[1].value,  -- namespace
        id
    )
end)