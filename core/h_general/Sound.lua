-- Sound

---@class SoundClass
Sound = new_class()
C.Sound = Sound

run_on_initial_load(function()
    P.sound_find_table = FindTable.new()
end)

local sound_find_table = P.sound_find_table

local proxy = P.proxy
local metatable

local gm                 = gm  ---@type table<string, function>
local new_proxy          = new_proxy
local unwrap             = Wrap.unwrap
local check_init_started = Initialize.internal.check_if_started

local packet_syncSound  ---@type Packet


-- ========== Internal ==========

local function sound_initialize()
    -- Populate cache with vanilla sounds
    local resource_manager = Map.wrap(Global.ResourceManager_audio.__namespacedAssetLookup)
    
    for identifier, sound in pairs(Map.wrap(resource_manager["ror"])) do
        local wrapper = Sound.wrap(sound)
        sound_find_table:set(wrapper, identifier, "ror", sound)
    end
    
    -- Packet for `play_synced`
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
run_on_initialize(sound_initialize)


-- ========== Static Methods ==========

--[[
Creates a new sound with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the sound.
---@param path string The file path to the sound. <br>`~` expands to your mod folder.
---@return Sound
Sound.new = function(NAMESPACE, identifier, path)
    check_init_started("new")
    if not identifier then throw("No identifier provided", "new") end
    if not path then throw("No image path provided", "new") end

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
        throw("Could not load sound at '"..path.."'", "new")
    end

    -- Adding to find table is done in the hook at the bottom

    return Sound.wrap(sound)
end

--[[
Searches for the specified sound and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return Sound | nil
Sound.find = function(identifier, namespace, namespace_is_specified)
    return sound_find_table:get(identifier, namespace, namespace_is_specified)
end

--[[
Returns a table of all sounds in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param namespace? string The namespace to search in.
---@return table<number, Sound>
Sound.find_all = function(namespace, namespace_is_specified)
    return sound_find_table:get_all(namespace, namespace_is_specified)
end

--[[
Returns a Sound wrapper containing the provided sound ID.
]]
---@param sound number | Sound The sound to wrap.
---@return Sound
Sound.wrap = function(sound)
    return new_proxy(unwrap(sound), metatable)
end


-- ========== Wrapper Methods ==========

---@class Sound
local methods = {}

--[[
Plays the sound at the specified location.

This does not sync with other players online.
]]
---@param x number The x coordinate to play at.
---@param y number The y coordinate to play at.
---@param volume? number The volume of the sound. <br>`1` by default.
---@param pitch? number The pitch of the sound. <br>`1` by default.
methods.play = function(self, x, y, volume, pitch)
    if not x then throw("x is nil", 2) end
    if not y then throw("y is nil", 2) end

    gm.sound_play_at(
        proxy[self],
        volume or 1,
        pitch  or 1,
        x,
        y
    )
end

--[[
Plays the sound at the specified location.

This syncs with other players online, however <br>
having every client call {`sound:play` | Sound#play} themselves <br>
is preferable since that has no packet latency.
]]
---@param x number The x coordinate to play at.
---@param y number The y coordinate to play at.
---@param volume? number The volume of the sound. <br>`1` by default.
---@param pitch? number The pitch of the sound. <br>`1` by default.
methods.play_synced = function(self, x, y, volume, pitch)
    if not x then throw("x is nil", 2) end
    if not y then throw("y is nil", 2) end

    gm.sound_play_at(
        proxy[self],
        volume or 1,
        pitch  or 1,
        x,
        y
    )
    packet_syncSound:send_to_all(self.identifier, self.namespace, x, y, volume or 1, pitch or 1)
end


-- ========== Metatables ==========

---@class Sound
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field namespace string The namespace of the sound.
---@field identifier string The identifier of the sound.

local mt_name = "Sound"

W.Sound = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return proxy[t] end
        if k == "RAPI" then return mt_name end
        
        -- Methods
        local method = methods[k]
        if method then return method end

        -- Getter
        return sound_find_table[proxy[t]][k]
    end,
    
    __newindex = function(t, k, v)
        log.error(mt_name.." has no properties to set", 2)
    end,

    __metatable = mt_wrapper_name(mt_name),
}
metatable = W.Sound


-- ========== Hooks ==========

-- Add new sounds to find table
gm.post_script_hook(gm.constants.sound_add_w, function(self, other, result, args)
    local id = result.value
    if id == -1 then return end

    sound_find_table:set(
        Sound.wrap(id),
        args[2].value,  -- identifier
        args[1].value,  -- namespace
        id
    )
end)