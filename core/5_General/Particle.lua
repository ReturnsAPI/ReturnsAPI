-- Particle

Particle = new_class()

local find_cache = {}



-- ========== Enums ==========

--$enum
Particle.System = ReadOnly.new({
    ABOVE           = 0,
    BELOW           = 1,
    MIDDLE          = 2,
    BACKGROUND      = 3,
    VERYABOVE       = 4,
    DAMAGE          = 5,
    DAMAGE_ABOVE    = 6
})


--$enum
Particle.Shape = ReadOnly.new({
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
})



-- ========== Static Methods ==========

--$static
--$return       Particle
--$param        identifier  | string    | The identifier for the particle type.
--[[
Creates a new particle type with the given identifier if it does not already exist,
or returns the existing one if it does.
]]
Particle.new = function(namespace, identifier)
    -- Return existing particle if found
    local part = Particle.find(identifier, namespace)
    if part then return part end

    -- Create new particle
    local part = GM.part_type_create_w(namespace, identifier)

    -- Add to cache and return
    local wrapper = Particle.wrap(part)
    find_cache[namespace.."-"..identifier] = wrapper
    return wrapper
end


--$static
--$return       Particle or nil
--$param        identifier  | string    | The identifier to search for.
--$optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified particle and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]
Particle.find = function(identifier, namespace, default_namespace)
    local namespace, is_specified = parse_optional_namespace(namespace, default_namespace)
    
    local nsid = namespace.."-"..identifier
    local ror_nsid = "ror-"..identifier

    -- Check in cache (both in namespace and in "ror" if no `namespace` arg)
    local cached = find_cache[nsid]
    if cached then return cached end
    if not is_specified then
        local cached = find_cache[ror_nsid]
        if cached then return cached end
    end

    -- Search in namespace
    local particle
    local resource_manager = Global.ResourceManager_particleTypes.__namespacedAssetLookup
    local namespace_struct = resource_manager[namespace]
    if namespace_struct then particle = namespace_struct[identifier] end

    if particle then
        particle = Particle.wrap(particle)
        find_cache[nsid] = particle
        return particle
    end

    -- Also search in "ror" namespace if passed no `namespace` arg
    if not is_specified then
        local particle
        local namespace_struct = resource_manager["ror"]
        if namespace_struct then particle = namespace_struct[identifier] end
        
        if particle then
            particle = Particle.wrap(particle)
            find_cache[ror_nsid] = particle
            return particle
        end
    end

    return nil
end


--$static
--$return       table
--$optional     namespace   | string    | The namespace to check.
--[[
Returns a table of all particles in the specified namespace.
If no namespace is provided, retrieves from both your mod's namespace and "ror".
]]
Particle.find_all = function(namespace, _namespace)
    local namespace, is_specified = parse_optional_namespace(_namespace, namespace)
    
    local parts = {}
    local resource_manager = Global.ResourceManager_particleTypes.__namespacedAssetLookup

    -- Search in namespace
    if resource_manager[namespace] then
        for _, part in pairs(resource_manager[namespace]) do
            table.insert(parts, Particle.wrap(part))
        end
    end

    -- Also search in "ror" namespace if passed no `namespace` arg
    if not is_specified then
        for _, part in pairs(resource_manager["ror"]) do
            table.insert(parts, Particle.wrap(part))
        end
    end
    
    return parts
end


--$static
--$return       Particle
--$param        particle    | number    | The particle type to wrap.
--[[
Returns a Particle wrapper containing the provided particle type.
]]
Particle.wrap = function(particle)
    return Proxy.new(Wrap.unwrap(particle), metatable_particle)
end



-- ========== Instance Methods ==========

methods_particle = {

    --$instance
    --$param        x           | number    | The x coordinate to spawn at.
    --$param        y           | number    | The y coordinate to spawn at.
    --$optional     count       | number    | The number of particles to spawn. <br>`1` by default.
    --$optional     system      | number    | The $particle system, Particle#System$ to use. <br>`Particle.System.ABOVE` by default.
    --[[
    Spawns particles at the specified location.
    ]]
    create = function(self, x, y, count, system)
        local holder = RValue.new_holder(5)
        holder[0] = RValue.new(system or Particle.System.ABOVE)
        holder[1] = RValue.new(x)
        holder[2] = RValue.new(y)
        holder[3] = RValue.new(self.value)
        holder[4] = RValue.new(count or 1)
        gmf.part_particles_create(RValue.new(0), nil, nil, 5, holder)
    end,


    --$instance
    --$param        x           | number    | The x coordinate to spawn at.
    --$param        y           | number    | The y coordinate to spawn at.
    --$optional     color       | color     | The color to blend. <br>`Color.WHITE` by default.
    --$optional     count       | number    | The number of particles to spawn. <br>`1` by default.
    --$optional     system      | number    | The $particle system, Particle#System$ to use. <br>`Particle.System.ABOVE` by default.
    --[[
    Spawns colored particles at the specified location.
    ]]
    create_color = function(self, x, y, color, count, system)
        local holder = RValue.new_holder(6)
        holder[0] = RValue.new(system or Particle.System.ABOVE)
        holder[1] = RValue.new(x)
        holder[2] = RValue.new(y)
        holder[3] = RValue.new(self.value)
        holder[4] = RValue.new(color or Color.WHITE)
        holder[5] = RValue.new(count or 1)
        gmf.part_particles_create_color(RValue.new(0), nil, nil, 6, holder)
    end,
    create_colour = function(self, x, y, color, count, system)
        self:create_color(x, y, color, count, system)
    end,


    --$instance
    --$return       string
    --[[
    Returns the identifier of the particle.
    ]]
    get_identifier = function(self)
        local lookup_struct = Global.ResourceManager_particleTypes.__assetName
        return lookup_struct[self.value]
    end

}



-- ========== Metatables ==========

make_table_once("metatable_particle", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(proxy) end
        if k == "RAPI" then return getmetatable(proxy):sub(14, -1) end

        -- Methods
        if methods_particle[k] then
            return methods_particle[k]
        end

        -- GML `part_type_` methods
        if k:sub(1, 4) == "set_" then
            local fn = k:sub(5, #k)
            return GM["part_type_"..fn]
        end

        return nil
    end,


    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end
        
        log.error("Particle has no properties to set; use methods instead", 2)
    end,


    __metatable = "RAPI.Wrapper.Particle"
})



-- Public export
__class.Particle = Particle