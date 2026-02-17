-- Particle

Particle = new_class()

run_once(function()
    __particle_find_cache = FindCache.new()
end)



-- ========== Enums ==========

--@section Enums

--@enum
Particle.System = {
    ABOVE           = 0,
    BELOW           = 1,
    MIDDLE          = 2,
    BACKGROUND      = 3,
    VERYABOVE       = 4,
    DAMAGE          = 5,
    DAMAGE_ABOVE    = 6
}


--@enum
Particle.Shape = {
    PIXEL       = 0,
    DISK        = 1,
    SQUARE      = 2,
    LINE        = 3,
    STAR        = 4,
    CIRCLE      = 5,
    RING        = 6,
    SPHERE      = 7,
    FLARE       = 8,
    SPARK       = 9,
    EXPLOSION   = 10,
    CLOUD       = 11,
    SMOKE       = 12,
    SNOW        = 13
}



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The particle ID being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.
`namespace`     | string    | *Read-only.* The namespace the particle is in.
`identifier`    | string    | *Read-only.* The identifier for the particle within the namespace.
]]



-- ========== Internal ==========

Particle.internal.initialize = function()
    -- Populate cache with vanilla particles
    local resource_manager = Map.wrap(Global.ResourceManager_particleTypes.__namespacedAssetLookup)
    
    for identifier, part in pairs(Map.wrap(resource_manager["ror"])) do
        local wrapper = Particle.wrap(part)

        __particle_find_cache:set(
            {
                wrapper = wrapper,
            },
            identifier,
            "ror",
            part
        )
    end
end
table.insert(_rapi_initialize, Particle.internal.initialize)



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       Particle
--@param        identifier  | string    | The identifier for the particle type.
--[[
Creates a new particle type with the given identifier if it does not already exist,
or returns the existing one if it does.
]]
Particle.new = function(NAMESPACE, identifier)
    -- Return existing particle if found
    local part = Particle.find(identifier, NAMESPACE, true)
    if part then return part end

    -- Create new particle
    local part = gm.part_type_create_w(NAMESPACE, identifier)

    -- Adding to find table is done in the hook at the bottom

    return Particle.wrap(part)
end


--@static
--@return       Particle or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified particle and returns it.

--@findinfo
]]
Particle.find = function(identifier, namespace, namespace_is_specified)
    local cached = __particle_find_cache:get(identifier, namespace, namespace_is_specified)
    if cached then return cached.wrapper end
end


--@static
--@return       table
--@optional     namespace   | string    | The namespace to check.
--[[
Returns a table of all particles in the specified namespace.

--@findinfo
]]
Particle.find_all = function(namespace, namespace_is_specified)
    return __particle_find_cache:get_all(namespace, namespace_is_specified, "wrapper")
end


--@static
--@return       Particle
--@param        particle    | number    | The particle type to wrap.
--[[
Returns a Particle wrapper containing the provided particle type.
]]
Particle.wrap = function(particle)
    -- Input:   number or Particle wrapper
    -- Wraps:   number
    return make_proxy(Wrap.unwrap(particle), metatable_particle)
end



-- ========== Instance Methods ==========

--@section Instance Methods

methods_particle = {

    --@instance
    --@param        x           | number    | The x coordinate to spawn at.
    --@param        y           | number    | The y coordinate to spawn at.
    --@optional     count       | number    | The number of particles to spawn. <br>`1` by default.
    --@optional     system      | number    | The @link {particle system | Particle#System} to use. <br>`Particle.System.ABOVE` by default.
    --[[
    Spawns particles at the specified location.
    ]]
    create = function(self, x, y, count, system)
        x = Wrap.unwrap(x)
        y = Wrap.unwrap(y)
        if not x then log.error("create: x is not valid", 2) end
        if not y then log.error("create: y is not valid", 2) end

        gm.part_particles_create(
            system or Particle.System.ABOVE,
            x,
            y,
            self.value,
            count or 1
        )
    end,


    --@instance
    --@param        x           | number    | The x coordinate to spawn at.
    --@param        y           | number    | The y coordinate to spawn at.
    --@optional     color       | color     | The color to blend. <br>`Color.WHITE` by default.
    --@optional     count       | number    | The number of particles to spawn. <br>`1` by default.
    --@optional     system      | number    | The @link {particle system | Particle#System} to use. <br>`Particle.System.ABOVE` by default.
    --@overload
    --@name         create_colour
    --@param        x           | number    | The x coordinate to spawn at.
    --@param        y           | number    | The y coordinate to spawn at.
    --@optional     color       | color     | The color to blend. <br>`Color.WHITE` by default.
    --@optional     count       | number    | The number of particles to spawn. <br>`1` by default.
    --@optional     system      | number    | The @link {particle system | Particle#System} to use. <br>`Particle.System.ABOVE` by default.
    --[[
    Spawns colored particles at the specified location.
    ]]
    create_color = function(self, x, y, color, count, system)
        x = Wrap.unwrap(x)
        y = Wrap.unwrap(y)
        if not x then log.error("create_color: x is not valid", 2) end
        if not y then log.error("create_color: y is not valid", 2) end

        gm.part_particles_create_color(
            system or Particle.System.ABOVE, 
            x,
            y,
            self.value,
            color or Color.WHITE,
            count or 1
        )
    end,

    create_colour = function(self, x, y, color, count, system)
        x = Wrap.unwrap(x)
        y = Wrap.unwrap(y)
        if not x then log.error("create_colour: x is not valid", 2) end
        if not y then log.error("create_colour: y is not valid", 2) end
        
        self:create_color(x, y, color, count, system)
    end

}



-- ========== Metatables ==========

--@section Particle Property Setters

--[[
See the relevant [GameMaker documentation page](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Particles/Particle_Types/Particle_Types.htm) for more info.

```lua
particle:set_shape
particle:set_sprite
particle:set_subimage

particle:set_size
particle:set_size_x
particle:set_size_y
particle:set_scale

particle:set_speed
particle:set_direction
particle:set_gravity
particle:set_orientation

particle:set_color_mix
particle:set_color_rgb
particle:set_color_hsv
particle:set_color1
particle:set_color2
particle:set_color3
particle:set_alpha1
particle:set_alpha2
particle:set_alpha3
particle:set_blend

particle:set_life
particle:set_step
particle:set_death
```
]]

local wrapper_name = "Particle"

make_table_once("metatable_particle", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return __proxy[proxy] end
        if k == "RAPI" then return wrapper_name end

        -- Methods
        if methods_particle[k] then
            return methods_particle[k]
        end

        -- GML `part_type_` methods
        if k:sub(1, 4) == "set_" then
            local fn = k:sub(5, #k)
            return GM["part_type_"..fn]
        end

        -- Getter
        return __particle_find_cache:get(__proxy[proxy])[k]
    end,


    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end
        
        log.error("Particle has no properties to set; use methods instead", 2)
    end,


    __metatable = "RAPI.Wrapper."..wrapper_name
})



-- ========== Hooks ==========

-- Add new particles to find table
Hook.add_post(RAPI_NAMESPACE, gm.constants.part_type_create_w, Callback.internal.FIRST, function(self, other, result, args)
    local id = result.value
    if id == -1 then return end

    __particle_find_cache:set(
        {
            wrapper = Particle.wrap(id),
        },
        args[2].value,
        args[1].value,
        id
    )
end)



-- Public export
__class.Particle = Particle