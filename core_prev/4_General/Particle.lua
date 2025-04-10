-- Particle

Particle = new_class()

local find_cache = {}



-- ========== Enums ==========

Particle.System = ReadOnly.new({
    ABOVE           = 0,
    BELOW           = 1,
    MIDDLE          = 2,
    BACKGROUND      = 3,
    VERYABOVE       = 4,
    DAMAGE          = 5,
    DAMAGE_ABOVE    = 6
})


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

Particle.new = function(namespace, identifier)
    local part = Particle.find(identifier, namespace)
    if part then return part end

    local part = GM.part_type_create_w(namespace, identifier)
    return Particle.wrap(part)
end


Particle.find = function(identifier, namespace, default_namespace)
    local namespace, is_specified = parse_optional_namespace(namespace, default_namespace)
    
    local nsid = namespace.."-"..identifier
    local ror_nsid = "ror-"..identifier

    -- Check in cache (both mod namespace and "ror")
    local cached = find_cache[nsid]
    if cached then return cached end
    if not is_specified then
        local cached = find_cache[ror_nsid]
        if cached then return cached end
    end
    
    -- Search in namespace
    local lookup_struct = Global.ResourceManager_particleTypes.__namespacedAssetLookup
    if lookup_struct[namespace] then
        if lookup_struct[namespace][identifier] then
            local part = Particle.wrap(lookup_struct[namespace][identifier])
            find_cache[nsid] = part
            return part
        end
    end

    -- Search in "ror" as well if no namespace provided
    if not is_specified then
        if lookup_struct["ror"] then
            if lookup_struct["ror"][identifier] then
                local part = Particle.wrap(lookup_struct["ror"][identifier])
                find_cache[ror_nsid] = part
                return part
            end
        end
    end

    return nil
end


Particle.find_all = function(namespace, _namespace)
    local namespace, is_specified = parse_optional_namespace(_namespace, namespace)
    
    local parts = {}
    local lookup_struct = Global.ResourceManager_particleTypes.__namespacedAssetLookup

    if lookup_struct[namespace] then
        for _, part in pairs(lookup_struct[namespace]) do
            table.insert(parts, Particle.wrap(part))
        end
    end

    -- Check mod namespace and "ror" by default if unspecified
    if not is_specified then
        for _, part in pairs(lookup_struct["ror"]) do
            table.insert(parts, Particle.wrap(part))
        end
    end
    
    return parts, #parts > 0
end


Particle.wrap = function(particle)
    return Proxy.new(Wrap.unwrap(particle), metatable_particle)
end



-- ========== Instance Methods ==========

methods_particle = {

    create = function(self, x, y, count, system)
        local holder = RValue.new_holder(5)
        holder[0] = RValue.new(system or Particle.System.ABOVE)
        holder[1] = RValue.new(x)
        holder[2] = RValue.new(y)
        holder[3] = RValue.new(self.value)
        holder[4] = RValue.new(count or 1)
        gmf.part_particles_create(RValue.new(0), nil, nil, 5, holder)
    end,


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


    get_identifier = function(self)
        local lookup_struct = Global.ResourceManager_particleTypes.__assetName
        return lookup_struct[self.value]
    end

}



-- ========== Metatables ==========

metatable_particle = {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(proxy) end
        if k == "RAPI" then return getmetatable(proxy):sub(14, -1) end

        -- Methods
        if methods_particle[k] then
            return methods_particle[k]
        end

        -- GML part_type_ methods
        if k:sub(1, 4) == "set_" then
            local fn = k:sub(5, #k)
            return GM["part_type_"..fn]
        end

        return nil
    end,


    __newindex = function(proxy, k, v)
        log.error("Particle has no settable properties; use methods instead", 2)
    end,


    __metatable = "RAPI.Wrapper.Particle"
}



__class.Particle = Particle