-- Sound

Sound = new_class()

run_once(function()
    __sound_find_table = FindCache.new()
end)



-- ========== Internal ==========

Sound.internal.add_to_find_table = function(wrapper, namespace, identifier, id)
    __sound_find_table:set(
        {
            wrapper     = wrapper,
            namespace   = namespace,
            identifier  = identifier
        },
        identifier, namespace, id
    )
end


Sound.internal.initialize = function()
    -- Update cached wrappers
    __sound_find_table:loop_and_update_values(function(value)
        return {
            wrapper     = Sound.wrap(value.wrapper),
            namespace   = value.namespace,
            identifier  = value.identifier
        }
    end)
end
table.insert(_rapi_initialize, Sound.internal.initialize)



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
Sound.new = function(NAMESPACE, identifier, path)
    Initialize.internal.check_if_started("Sound.new")
    if not identifier then log.error("Sound.new: No identifier provided", 2) end
    if not path then log.error("Sound.new: No image path provided", 2) end

    path = expand_path(NAMESPACE, path)

    -- Return existing sound if found
    local sound = Sound.find(identifier, NAMESPACE, true)
    if sound then return sound end

    -- Create new sound
    sound = gm.sound_add_w(
        NAMESPACE,
        identifier,
        path
    )

    if sound == -1 then
        log.error("Sound.new: Could not load sound at '"..path.."'", 2)
    end

    local wrapper = Sound.wrap(sound)

    -- Add to find table
    Sound.internal.add_to_find_table(wrapper, NAMESPACE, identifier, sound)

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
Sound.find = function(identifier, namespace, namespace_is_specified)
    -- Check in cache
    local cached = __sound_find_table:get(identifier, namespace, namespace_is_specified)
    if cached then return cached.wrapper end

    -- Search in namespace
    local sound
    local resource_manager = Map.wrap(Global.ResourceManager_audio.__namespacedAssetLookup)
    local namespace_map = resource_manager[namespace]
    if namespace_map then sound = Map.wrap(namespace_map)[identifier] end

    if sound then
        local wrapper = Sound.wrap(sound)
        Sound.internal.add_to_find_table(wrapper, namespace, identifier, sound)
        return wrapper
    end

    -- Also search in "ror" namespace if passed no `namespace` arg
    if not namespace_is_specified then
        local sound
        local namespace_map = resource_manager["ror"]
        if namespace_map then sound = Map.wrap(namespace_map)[identifier] end
        
        if sound then
            local wrapper = Sound.wrap(sound)
            Sound.internal.add_to_find_table(wrapper, "ror", identifier, sound)
            return wrapper
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
Sound.find_all = function(namespace, namespace_is_specified)
    local sounds = {}
    local resource_manager = Map.wrap(Global.ResourceManager_audio.__namespacedAssetLookup)

    -- Search in namespace
    if resource_manager[namespace] then
        for identifier, sound in pairs(Map.wrap(resource_manager[namespace])) do
            local wrapper = Sound.wrap(sound)
            table.insert(sounds, wrapper)
            Sound.internal.add_to_find_table(wrapper, namespace, identifier, sound)
        end
    end

    -- Also search in "ror" namespace if passed no `namespace` arg
    if not namespace_is_specified then
        for identifier, sound in pairs(Map.wrap(resource_manager["ror"])) do
            local wrapper = Sound.wrap(sound)
            table.insert(sounds, wrapper)
            Sound.internal.add_to_find_table(wrapper, "ror", identifier, sound)
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

        -- Getter
        return __sound_find_table:get(__proxy[proxy])[k]
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