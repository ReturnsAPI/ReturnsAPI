-- Sound

Sound = new_class()

local find_cache = {}



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       Sound
--@param        identifier  | string    | The identifier for the sound.
--@param        path        | string    | The file path to the sound. <br>`~` expands to your mod folder (without a trailing slash).
--[[
Creates a new sound with the given identifier if it does not already exist,
or returns the existing one if it does.
]]
Sound.new = function(namespace, identifier, path)
    Initialize.internal.check_if_started()
    if not identifier then log.error("No identifier provided", 2) end
    if not path then log.error("No image path provided", 2) end

    -- Expand `~` to mod folder
    path = path:gsub("~/", __namespace_path[namespace].."/")
    path = path:gsub("~", __namespace_path[namespace].."/")

    -- Return existing sound if found
    local sound = Sound.find(identifier, namespace, namespace)
    if sound then return sound end

    -- Create new sound
    sound = gm.sound_add_w(
        namespace,
        identifier,
        path
    )

    if sound == -1 then
        log.error("Could not load sound at '"..path.."'", 2)
    end

    -- Add to cache and return
    local wrapper = Sound.wrap(sound)
    find_cache[namespace.."-"..identifier] = wrapper
    return wrapper
end


--@static
--@return       Sound or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified sound and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]
Sound.find = function(identifier, namespace, default_namespace)
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
    local sound
    local resource_manager = Map.wrap(Global.ResourceManager_audio.__namespacedAssetLookup)
    local namespace_struct = Map.wrap(resource_manager[namespace])
    if namespace_struct then sound = namespace_struct[identifier] end

    if sound then
        sound = Sound.wrap(sound)
        find_cache[nsid] = sound
        return sound
    end

    -- Also search in "ror" namespace if passed no `namespace` arg
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


--@static
--@return       table
--@optional     namespace   | string    | The namespace to check.
--[[
Returns a table of all sounds in the specified namespace.
If no namespace is provided, retrieves from both your mod's namespace and "ror".
]]
Sound.find_all = function(namespace, _namespace)
    local namespace, is_specified = parse_optional_namespace(_namespace, namespace)
    
    local sounds = {}
    local resource_manager = Map.wrap(Global.ResourceManager_audio.__namespacedAssetLookup)

    -- Search in namespace
    if resource_manager[namespace] then
        for _, sound in pairs(resource_manager[namespace]) do
            table.insert(sounds, sound.wrap(sound))
        end
    end

    -- Also search in "ror" namespace if passed no `namespace` arg
    if not is_specified then
        for _, sound in pairs(resource_manager["ror"]) do
            table.insert(sounds, sound.wrap(sound))
        end
    end
    
    return sounds
end


--@static
--@return       Sound
--@param        sound       | number    | The sound ID to wrap.
--[[
Returns a Sound wrapper containing the provided sound ID.
]]
Sound.wrap = function(sound)
    -- Input:   number or Sound wrapper
    -- Wraps:   number
    return make_proxy(Wrap.unwrap(sound), metatable_sound)
end



-- ========== Instance Methods ==========

--@section Instance Methods

methods_sound = {

    --@instance
    --@param        x           | number    | The x coordinate to play at.
    --@param        y           | number    | The y coordinate to play at.
    --@optional     volume      | number    | The volume of the sound. <br>`1` by default.
    --@optional     pitch       | number    | The pitch of the sound. <br>`1` by default.
    --[[
    Plays the sound at the specified location.
    ]]
    play = function(self, x, y, volume, pitch)
        gm.sound_play_at(
            self.value,
            volume  or 1,
            pitch   or 1,
            x,
            y
        )
    end

}



-- ========== Metatables ==========

local wrapper_name = "Sound"

make_table_once("metatable_sound", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return __proxy[proxy] end
        if k == "RAPI" then return wrapper_name end
        
        -- Methods
        if methods_sound[k] then
            return methods_sound[k]
        end

        return nil
    end,
    

    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        log.error("Sound has no properties to set", 2)
    end,


    __metatable = "RAPI.Wrapper."..wrapper_name
})



-- Public export
__class.Sound = Sound