-- Sound

Sound = new_class()

run_once(function()
    __sound_find_cache = FindCache.new()
end)

local packet_syncSound



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The sound ID being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.
`namespace`     | string    | *Read-only.* The namespace the sound is in.
`identifier`    | string    | *Read-only.* The identifier for the sound within the namespace.
]]



-- ========== Internal ==========

Sound.internal.initialize = function()
    -- Populate cache with vanilla sounds
    local resource_manager = Map.wrap(Global.ResourceManager_audio.__namespacedAssetLookup)
    
    for identifier, sound in pairs(Map.wrap(resource_manager["ror"])) do
        local wrapper = Sound.wrap(sound)

        __sound_find_cache:set(
            {
                wrapper = wrapper,
            },
            identifier,
            "ror",
            sound
        )
    end
    
    -- `play_synced`
    packet_syncSound = Packet.new(RAPI_NAMESPACE, "syncSound")
    packet_syncSound:set_serializers(
        function(buffer, identifier, namespace, x, y, volume, pitch)
            buffer:write_string(identifier)
            buffer:write_string(namespace)
            buffer:write_int(x)
            buffer:write_int(y)
            buffer:write_half(volume)
            buffer:write_half(pitch)
        end,

        function(buffer, player)
            local sound = Sound.find(buffer:read_string(), buffer:read_string(), true)
            if sound then
                sound:play(
                    buffer:read_int(),
                    buffer:read_int(),
                    buffer:read_half(),
                    buffer:read_half()
                )
            end
        end
    )
end
table.insert(_rapi_initialize, Sound.internal.initialize)



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       Sound
--@param        identifier  | string    | The identifier for the sound.
--@param        path        | string    | The file path to the sound. <br>`~` expands to your mod folder.
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

    -- Adding to find table is done in the hook at the bottom

    return Sound.wrap(sound)
end


--@static
--@return       Sound or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified sound and returns it.

--@findinfo
]]
Sound.find = function(identifier, namespace, namespace_is_specified)
    local cached = __sound_find_cache:get(identifier, namespace, namespace_is_specified)
    if cached then return cached.wrapper end
end


--@static
--@return       table
--@optional     namespace   | string    | The namespace to search in.
--[[
Returns a table of all sounds in the specified namespace.

--@findinfo
]]
Sound.find_all = function(namespace, namespace_is_specified)
    return __sound_find_cache:get_all(namespace, namespace_is_specified, "wrapper")
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

    This does not sync with other players online.
    ]]
    play = function(self, x, y, volume, pitch)
        if not x then log.error("play: x coordinate is not provided", 2) end
        if not y then log.error("play: y coordinate is not provided", 2) end

        gm.sound_play_at(
            self.value,
            volume  or 1,
            pitch   or 1,
            x,
            y
        )
    end,


    --@instance
    --@param        x           | number    | The x coordinate to play at.
    --@param        y           | number    | The y coordinate to play at.
    --@optional     volume      | number    | The volume of the sound. <br>`1` by default.
    --@optional     pitch       | number    | The pitch of the sound. <br>`1` by default.
    --[[
    Plays the sound at the specified location.

    This syncs with other players online, but
    having every client call {`sound:play` | Sound#play} themselves
    is preferable since that has no packet latency.
    ]]
    play_synced = function(self, x, y, volume, pitch)
        if not x then log.error("play: x coordinate is not provided", 2) end
        if not y then log.error("play: y coordinate is not provided", 2) end

        gm.sound_play_at(
            self.value,
            volume  or 1,
            pitch   or 1,
            x,
            y
        )

        packet_syncSound:send_to_all(self.identifier, self.namespace, x, y, volume or 1, pitch or 1)
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
        return __sound_find_cache:get(__proxy[proxy])[k]
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



-- ========== Hooks ==========

-- Add new sounds to find table
Hook.add_post(RAPI_NAMESPACE, gm.constants.sound_add_w, Callback.internal.FIRST, function(self, other, result, args)
    local id = result.value
    if id == -1 then return end

    __sound_find_cache:set(
        {
            wrapper = Sound.wrap(id),
        },
        args[2].value,
        args[1].value,
        id
    )
end)



-- Public export
__class.Sound = Sound