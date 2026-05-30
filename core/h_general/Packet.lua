-- Packet

-- TODO: Don't pass tables in `make_proxy` since they will be user-accessible via Wrap.unwrap

---@class PacketClass
Packet = new_class()
C.Packet = Packet

run_on_initial_load(function()
    P.packet_find_table = FindTable.new()

    P.packet_functions_onSerialize   = {}  ---@type table<string, function> Stores functions to run on serialization
    P.packet_functions_onDeserialize = {}  ---@type table<string, function> Stores functions to run on deserialization
end)

local packet_find_table     = P.packet_find_table
local serialize_functions   = P.packet_functions_onSerialize
local deserialize_functions = P.packet_functions_onDeserialize

local proxy = P.proxy
local metatable

local gm                 = gm  ---@type table<string, function>
local new_proxy          = new_proxy
local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap

local SendType = {
    ALL     = 0,
    DIRECT  = 1,
    EXCLUDE = 2,
    HOST    = 3
}

local packet_syncPackets  ---@type Packet


-- ========== Internal ==========

---@return Packet
local function new_packet(namespace, identifier, nsid, id)
    return new_proxy({
        namespace  = namespace,
        identifier = identifier,
        nsid       = nsid,
        id         = id
    }, metatable)
end

local function make_sync_packet()
    -- This packet will sync client packet IDs with
    -- the host's based on nsid when they join the lobby
    packet_syncPackets = Packet.new(RAPI_NAMESPACE, "syncPackets")
    packet_syncPackets:set_serializers(
        function(buffer)
            local count = 0
            local _pairs = {}  ---@type table<number, table>

            -- Loop through `packet_find_table` and add nsid <-> packet ID pairs
            packet_find_table:map(function(value)
                if not _pairs[value.id] then
                    _pairs[value.id] = {
                        namespace  = value.namespace,
                        identifier = value.identifier,
                    }
                    count = count + 1
                end
            end)

            buffer:write_uint_packed(count)

            -- Loop through `_pairs` and write
            for id, t in pairs(_pairs) do
                print("Syncing packet with ID "..id.." (nsid "..t.namespace.."-"..t.identifier..")")
                buffer:write_uint_packed(id)
                buffer:write_string(t.namespace)
                buffer:write_string(t.identifier)
            end

            print("Sync write count is "..count)
        end,

        function(buffer, player)
            local count = buffer:read_uint_packed()
            
            print("Sync read count is "..math.floor(count))

            for i = 1, count do
                -- Read host nsid <-> packet ID pair
                local new_id     = buffer:read_uint_packed()
                local namespace  = buffer:read_string()
                local identifier = buffer:read_string()
                
                print("Syncing packet to new ID "..math.floor(new_id).." (nsid "..namespace.."-"..identifier..")")

                ---@type Packet
                local wrapper = packet_find_table:get(identifier, namespace, true)

                if wrapper then
                    -- Remove wrapper from current find table location
                    packet_find_table:set(nil, identifier, namespace, wrapper.id)

                    -- Modify wrapper to use new ID
                    proxy[wrapper].id = new_id

                    -- Increment `Global.mod_message_counter` if it is lower than `new_id`
                    -- This is to make `_mod_net_message_getUniqueID` not return an ID already in use
                    Global.mod_message_counter = math.max(Global.mod_message_counter, new_id)

                    -- Check if there is already an existing wrapper at the new ID
                    -- If so, move that to a new position
                    ---@type Packet
                    local existing = packet_find_table[new_id].value
                    if existing then
                        local existing_new_id = gm._mod_net_message_getUniqueID()
                        proxy[existing].id = existing_new_id
                        packet_find_table:set(existing, existing.identifier, existing.namespace, existing_new_id)
                    end

                    -- Add wrapper to new find table location
                    packet_find_table:set(wrapper, identifier, namespace, new_id)
                end
            end
        end
    )
end
run_on_initialize(make_sync_packet)


-- ========== Static Methods ==========

--@section Static Methods

--[[
Creates a new packet with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the packet.
---@return Packet
Packet.new = function(NAMESPACE, identifier)
    check_init_started("new")
    if not identifier then throw("No identifier provided", "new") end

    -- Return existing packet if found
    local packet = Packet.find(identifier, NAMESPACE, true)
    if packet then return packet end

    -- Get next usable packet ID
    local id = gm._mod_net_message_getUniqueID()

    local nsid = NAMESPACE.."-"..identifier
    local packet = new_packet(NAMESPACE, identifier, nsid, id)
    packet_find_table:set(packet, identifier, NAMESPACE, id)
    print("Created Packet with ID "..math.floor(id).." (nsid '"..nsid.."')")
    return packet
end

--[[
Searches for the specified packet and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return Packet | nil
Packet.find = function(identifier, namespace, namespace_is_specified)
    return packet_find_table:get(identifier, namespace, namespace_is_specified)
end

--[[
Returns a table of all packets in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param namespace? string The namespace to search in.
---@return table<number, Packet>
Packet.find_all = function(namespace, namespace_is_specified)
    return packet_find_table:get_all(namespace, namespace_is_specified)
end

--[[
Returns a Packet wrapper containing the provided packet ID, <br>
or `nil` if the packet ID is not in use.
]]
---@param id number | Packet The packet to wrap.
---@return Packet | nil
Packet.wrap = function(id)
    return packet_find_table[unwrap(id)].value
end


-- ========== Wrapper Methods ==========

---@class Packet
local methods = {}

--[[
Set the serialization and deserialization functions for the packet.
]]
---@param serializer fun(buffer: Buffer, ...) The serialization function. <br>The parameters for it are `buffer, <variable number of arguments>`.
---@param deserializer fun(buffer: Buffer, player: Player) The deserialization function. <br>The parameters for it are `buffer, player` (i.e., the game client who sent the packet).
methods.set_serializers = function(self, serializer, deserializer)
    serialize_functions[self.nsid]   = serializer
    deserialize_functions[self.nsid] = deserializer
end

--[[
Sends a packet message to all clients.

**Can be called as host or client.**
]]
---@param ... any A variable number of arguments to pass to the serialization function.
methods.send_to_all = function(self, ...)
    if Net.host then
        local fn = serialize_functions[self.nsid]
        if fn then
            local buffer = Buffer.net_message_begin()
            buffer:write_ushort(SendType.ALL)
            fn(buffer, ...)
            gm._mod_net_message_send(self.id, SendType.ALL)
        end

    elseif Net.client then
        local fn = serialize_functions[self.nsid]
        if fn then
            local buffer = Buffer.net_message_begin()
            buffer:write_ushort(SendType.ALL)
            fn(buffer, ...)
            gm._mod_net_message_send(self.id, SendType.HOST)
        end
    end
end

--[[
Sends a packet message to a specific client.

**Must be called as host.**
]]
---@param target Player The target player to send to.
---@param ... any A variable number of arguments to pass to the serialization function.
methods.send_direct = function(self, target, ...)
    if Net.client then throw("Must be called from host") end

    -- Call serialization function linked to packet ID
    local fn = serialize_functions[self.nsid]
    if fn then
        local buffer = Buffer.net_message_begin()
        buffer:write_ushort(SendType.DIRECT)
        fn(buffer, ...)
        gm._mod_net_message_send(self.id, SendType.DIRECT, target)
    end
end

--[[
Sends a packet message all clients *except* a specific one. <br>
Usually called by the host in the deserializer by passing `player` as `target`.

**Must be called as host.**
]]
---@param target Player The target player to exclude.
---@param ... any A variable number of arguments to pass to the serialization function.
methods.send_exclude = function(self, target, ...)
    if Net.client then throw("Must be called from host") end

    -- Call serialization function linked to packet ID
    local fn = serialize_functions[self.nsid]
    if fn then
        local buffer = Buffer.net_message_begin()
        buffer:write_ushort(SendType.EXCLUDE)
        fn(buffer, ...)
        gm._mod_net_message_send(self.id, SendType.EXCLUDE, target)
    end
end

--[[
Sends a packet message to the host.

**Must be called as client.**
]]
---@param ... any A variable number of arguments to pass to the serialization function.
methods.send_to_host = function(self, ...)
    if Net.host then throw("Must be called from client") end

    -- Call serialization function linked to packet ID
    local fn = serialize_functions[self.nsid]
    if fn then
        local buffer = Buffer.net_message_begin()
        buffer:write_ushort(SendType.HOST)
        fn(buffer, ...)
        gm._mod_net_message_send(self.id, SendType.HOST)
    end
end


-- ========== Metatables ==========

---@class Packet
---@field value string The value being wrapped (`"<namespace>-<identifier>"`).
---@field nsid string Alias for `.value`.
---@field RAPI string The name of this wrapper.
---@field namespace string The namespace of the packet.
---@field identifier string The identifier of the packet.
---@field id number The ID of the packet.

local mt_name = "Packet"

W.Packet = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return proxy[t].nsid end
        if k == "RAPI" then return mt_name end

        -- Methods
        local method = methods[k]
        if method then return method end

        -- Getter
        return proxy[t][k]
    end,

    __newindex = function(t, k, v)
        log.error(mt_name.." has no properties to set", 2)
    end,

    __metatable = mt_wrapper_name(mt_name),
}
metatable = W.Packet


-- ========== Hooks ==========

Callback.add(RAPI_NAMESPACE, Callback.NET_MESSAGE_ON_RECEIVED, Callback.internal.FIRST, function(packet, buffer, buffer_tell, player)
    if not packet then return end

    -- Check if packet has a deserialization function
    local fn = deserialize_functions[packet.nsid]
    if not fn then return end

    -- Get send type
    local send_type = buffer:read_ushort()

    -- Client calling `send_to_all`
    if  Net.host
    and send_type == SendType.ALL then
        -- Copy buffer and send to other clients
        local relay_buffer = Buffer.net_message_begin()

        -- When the game sends a buffer, the receiver gets a version of it with X bytes
        -- prepended (which is why `buffer_tell` is X), so subtract X to get the actual size
        -- `buffer_tell` seems to usually be 2
        local buffer_actual_size = gm.buffer_get_size(buffer.value) - buffer_tell

        -- When copying, skip the first X bytes
        gm.buffer_copy(buffer.value, buffer_tell, buffer_actual_size, relay_buffer.value, 0)

        -- When sending, the game uses `gm.buffer_tell()` to determine the size of the write buffer,
        -- so must move seek position to `buffer`'s actual size
        gm.buffer_seek(relay_buffer.value, 0, buffer_actual_size)

        gm._mod_net_message_send(packet.id, SendType.EXCLUDE, player)
    end

    -- Call deserialization function
    fn(buffer, player)
end)

-- Send identifier <-> packet ID table to new clients on lobby join
gm.post_script_hook(gm.constants.server_new_player, function(self, other, result, args)
    local sock = args[1].value

    local player
    local ps = Instance.find_all(gm.constants.oPrePlayer)
    for _, p in ipairs(ps) do
        if p.sock == sock then
            player = p
            break
        end
    end

    if not player then
        log.warning("Packet: Sync error - cannot find player for socket ID '"..sock.."'")
        return
    end

    packet_syncPackets:send_direct(player)
end)