-- Particle

Particle = new_class()

run_once(function()
    __particle_find_table = FindCache.new()
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

Particle.internal.add_to_find_table = function(wrapper, namespace, identifier, id)
    __particle_find_table:set(
        {
            wrapper     = wrapper,
            namespace   = namespace,
            identifier  = identifier
        },
        identifier, namespace, id
    )
end


Particle.internal.initialize = function()
    -- Update cached wrappers
    __particle_find_table:loop_and_update_values(function(value)
        return {
            wrapper     = Particle.wrap(value.wrapper),
            namespace   = value.namespace,
            identifier  = value.identifier
        }
    end)
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

    local wrapper = Particle.wrap(part)

    -- Add to find table
    Particle.internal.add_to_find_table(wrapper, NAMESPACE, identifier, part)

    return wrapper
end


--@static
--@return       Particle or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified particle and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]
Particle.find = function(identifier, namespace, namespace_is_specified)
    -- Check in cache
    local cached = __particle_find_table:get(identifier, namespace, namespace_is_specified)
    if cached then return cached.wrapper end

    -- Search in namespace
    local particle
    local resource_manager = Map.wrap(Global.ResourceManager_particleTypes.__namespacedAssetLookup)
    local namespace_map = resource_manager[namespace]
    if namespace_map then particle = Map.wrap(namespace_map)[identifier] end

    if particle then
        local wrapper = Particle.wrap(particle)
        Particle.internal.add_to_find_table(wrapper, namespace, identifier, particle)
        return wrapper
    end

    -- Also search in "ror" namespace if passed no `namespace` arg
    if not namespace_is_specified then
        local particle
        local namespace_map = resource_manager["ror"]
        if namespace_map then particle = Map.wrap(namespace_map)[identifier] end
        
        if particle then
            local wrapper = Particle.wrap(particle)
            Particle.internal.add_to_find_table(wrapper, "ror", identifier, particle)
            return wrapper
        end
    end

    return nil
end


--@static
--@return       table
--@optional     namespace   | string    | The namespace to check.
--[[
Returns a table of all particles in the specified namespace.
If no namespace is provided, retrieves from both your mod's namespace and "ror".
]]
Particle.find_all = function(namespace, namespace_is_specified)
    local parts = {}
    local resource_manager = Map.wrap(Global.ResourceManager_particleTypes.__namespacedAssetLookup)

    -- Search in namespace
    if resource_manager[namespace] then
        for identifier, part in pairs(Map.wrap(resource_manager[namespace])) do
            local wrapper = Particle.wrap(part)
            table.insert(parts, wrapper)
            Particle.internal.add_to_find_table(wrapper, namespace, identifier, part)
        end
    end

    -- Also search in "ror" namespace if passed no `namespace` arg
    if not namespace_is_specified then
        for identifier, part in pairs(Map.wrap(resource_manager["ror"])) do
            local wrapper = Particle.wrap(part)
            table.insert(parts, wrapper)
            Particle.internal.add_to_find_table(wrapper, "ror", identifier, part)
        end
    end
    
    return parts
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
        self:create_color(x, y, color, count, system)
    end,


    --@instance
    --@return       string
    --[[
    Returns the identifier of the particle.
    ]]
    get_identifier = function(self)
        local lookup_struct = Global.ResourceManager_particleTypes.__assetName
        return lookup_struct[self.value]
    end


    --@instance
    --@param        x           | number    | The x coordinate to spawn at.
    --@param        y           | number    | The y coordinate to spawn at.
    --@optional     count       | number    | The number of particles to spawn. <br>`1` by default.
    --@optional     system      | number    | The @link {particle system | Particle#System} to use. <br>`Particle.System.ABOVE` by default.
    --[[
    Spawns particles at the specified location.
    ]]

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
        return __particle_find_table:get(__proxy[proxy])[k]
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



-- Public export
__class.Particle = Particle