-- Sound

Sound = new_class()

local find_cache = {}



-- ========== Static Methods ==========

Sound.new = function(namespace, identifier, path, image_number, x_origin, y_origin)
    Initialize.internal.check_if_done()
    if not identifier then log.error("No identifier provided", 2) end
    if not path then log.error("No image path provided", 2) end

    path = path:gsub("~", __namespace_path[namespace])

    -- Search for existing sound
    local sound
    local namespace_struct = Global.ResourceManager_audio.__namespacedAssetLookup[namespace]
    if namespace_struct then sound = namespace_struct[identifier] end

    if sound then return sound end

    -- Create sound
    sound = GM.sound_add_w(
        namespace,
        identifier,
        path
    )

    if sound == -1 then
        log.error("Could not load sound at "..path, 2)
    end

    return Sound.wrap(sound)
end


Sound.find = function(identifier, namespace, default_namespace)
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

    -- Look in mod namespace
    local sound
    local resource_manager = Global.ResourceManager_audio.__namespacedAssetLookup
    local namespace_struct = resource_manager[namespace]
    if namespace_struct then sound = namespace_struct[identifier] end

    if sound then
        sound = Sound.wrap(sound)
        find_cache[nsid] = sound
        return sound
    end

    -- Also look in "ror" namespace if user passed no `namespace` arg
    if not is_specified then
        local sound
        local namespace_struct = resource_manager["ror"]
        if namespace_struct then sound = namespace_struct[identifier] end
        
        if sound then
            sound = Sound.wrap(sound)
            find_cache[ror_nsid] = sound
            return sound
        end
    end

    return nil
end


Sound.wrap = function(sound)
    return Proxy.new(Wrap.unwrap(sound), metatable_sound)
end



-- ========== Instance Methods ==========

methods_sound = {

    

}



-- ========== Metatables ==========

metatable_sound = {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(proxy) end
        if k == "RAPI" then return getmetatable(proxy):sub(14, -1) end
        
        -- Methods
        if methods_sound[k] then
            return methods_sound[k]
        end

        return nil
    end,
    

    __newindex = function(proxy, k, v)
        -- Setter
        log.error("Sound has no properties to set")
    end,


    __metatable = "RAPI.Wrapper.Sound"
}



__class.Sound = Sound