-- Packet

-- TODO: Don't pass tables in `make_proxy` since they will be user-accessible via Wrap.unwrap

Packet = new_class()

run_once(function()
    __packet_find_table = FindCache.new()

    __callbacks_onSerialize     = {}    -- Stores callback functions to run on serialization/deserialization
    __callbacks_onDeserialize   = {}
end)

local SendType = {
    ALL     = 0,
    DIRECT  = 1,
    EXCLUDE = 2,
    HOST    = 3
}

local packet_syncPackets



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`/`nsid`  | string    | *Read-only.* The namespace-identifier of the packet.
`RAPI`          | string    | *Read-only.* The wrapper name.
`namespace`     | string    | *Read-only.* The namespace the packet is in.
`identifier`    | string    | *Read-only.* The identifier for the packet within the namespace.
`id`            | number    | *Read-only.* The numerical ID of the packet.
]]



-- ========== Internal ==========

Packet.internal.wrap = function(namespace, identifier, nsid, id)
    return make_proxy({
        namespace   = namespace,
        identifier  = identifier,
        nsid        = nsid,
        id          = id
    }, metatable_packet)
end


Packet.internal.net_message_send = function(packet_id, send_type, target)
    gm._mod_net_message_send(packet_id, send_type, Wrap.unwrap(target))
end


Packet.internal.initialize = function()
    packet_syncPackets = Packet.new(RAPI_NAMESPACE, "syncPackets")
    packet_syncPackets:set_serializers(
        function(buffer)
            local count = 0
            local _pairs = {}

            -- Loop through `__packet_find_table` and add nsid <-> packet ID pairs
            __packet_find_table:loop_and_update_values(function(value)
                if not _pairs[value.id] then
                    _pairs[value.id] = {namespace = value.namespace, identifier = value.identifier}
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
            
            print("Sync read count is "..count)

            for i = 1, count do
                -- Read host nsid <-> packet ID pair
                local new_id        = buffer:read_uint_packed()
                local namespace     = buffer:read_string()
                local identifier    = buffer:read_string()
                
                print("Syncing packet to new ID "..new_id.." (nsid "..namespace.."-"..identifier..")")

                -- Get wrapper
                local wrapper = __packet_find_table:get(identifier, namespace, true)

                if wrapper then
                    -- Remove wrapper from current cache location
                    __packet_find_table:set(nil, identifier, namespace, wrapper.id)

                    -- Modify wrapper to use new ID
                    __proxy[wrapper].id = new_id

                    -- Increment `Global.mod_message_counter` if it is lower than `new_id`
                    -- This is to make `_mod_net_message_getUniqueID` not return an ID already in use
                    Global.mod_message_counter = math.max(Global.mod_message_counter, new_id)

                    -- Check if there is already an existing wrapper at the new ID
                    -- If so, move that to a new position
                    local existing = __packet_find_table:get(new_id)
                    if existing then
                        local existing_new_id = gm._mod_net_message_getUniqueID()
                        __proxy[existing].id = existing_new_id
                        __packet_find_table:set(existing, existing.identifier, existing.namespace, existing_new_id)
                    end

                    -- Add wrapper to new cache location
                    __packet_find_table:set(wrapper, identifier, namespace, new_id)
                end
            end
        end
    )
end
table.insert(_rapi_initialize, Packet.internal.initialize)



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       Packet
--@param        identifier  | string    | The identifier for the packet.
--[[
Creates a new Packet and returns it.
]]
Packet.new = function(NAMESPACE, identifier)
    Initialize.internal.check_if_started("Packet.new")
    if not identifier then log.error("Packet.new: No identifier provided", 2) end

    -- Return existing packet if found
    local packet = Packet.find(identifier, NAMESPACE, true)
    if packet then return packet end

    -- Get next usable packet ID
    local id = gm._mod_net_message_getUniqueID()

    local nsid = NAMESPACE.."-"..identifier
    local packet = Packet.internal.wrap(NAMESPACE, identifier, nsid, id)

    -- Add to find table
    __packet_find_table:set(packet, identifier, NAMESPACE, id)

    print("Created Packet with ID "..id.." (nsid "..nsid..")")

    return packet
end


--@static
--@return       Packet or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified packet and returns it.
If no namespace is provided, searches in your mod's namespace first, and vanilla tiers second.
]]
Packet.find = function(identifier, namespace, namespace_is_specified)
    -- Check in find table
    local cached = __packet_find_table:get(identifier, namespace, namespace_is_specified)
    return cached
end


--@static
--@return       Packet or nil
--@param        packet_id   | number    | The packet ID to wrap.
--[[
Returns a Packet wrapper containing the provided packet ID,
or `nil` if the packet ID is not in use.
]]
Packet.wrap = function(packet_id)
    -- Input:   number
    -- Wraps:   N/A; returns existing wrapper if it exists
    local packet = __packet_find_table:get(packet_id)
    return packet
end



-- ========== Instance Methods ==========

--@section Instance Methods

methods_packet = {

    --@instance
    --@param        serializer      | function  | The serialization function.
    --@param        deserializer    | function  | The deserialization function.
    --[[
    Set the serialization and deserialization functions for the packet.
    The arguments for the serializer are `buffer, <variable number of arguments>`.
    The arguments for the deserializer are `buffer, player` (i.e., the game client who sent the packet).
    ]]
    set_serializers = function(self, serializer, deserializer)
        __callbacks_onSerialize[self.value] = serializer
        __callbacks_onDeserialize[self.value] = deserializer
    end,


    --@instance
    --@optional     ...         |           | A variable number of arguments to pass to the serialization function.
    --[[
    Sends a packet message to all clients.
    
    **Can be called as host or client.**
    ]]
    send_to_all = function(self, ...)
        if Net.host then
            -- Call serialization function linked to packet ID
            local fn = __callbacks_onSerialize[self.value]
            if fn then
                local buffer = Buffer.net_message_begin()
                buffer:write_ushort(SendType.ALL)
                fn(buffer, ...)
                Packet.internal.net_message_send(self.id, SendType.ALL)
            end

        elseif Net.client then
            -- Call serialization function linked to packet ID
            local fn = __callbacks_onSerialize[self.value]
            if fn then
                local buffer = Buffer.net_message_begin()
                buffer:write_ushort(SendType.ALL)
                fn(buffer, ...)
                Packet.internal.net_message_send(self.id, SendType.HOST)
            end

        end
    end,


    --@instance
    --@param        target      |           | The target player to send to.
    --@optional     ...         |           | A variable number of arguments to pass to the serialization function.
    --[[
    Sends a packet message to a specific client.

    **Must be called as host.**
    ]]
    send_direct = function(self, target, ...)
        if Net.client then log.error("send_direct: Must be called from host", 2) end

        -- Call serialization function linked to packet ID
        local fn = __callbacks_onSerialize[self.value]
        if fn then
            local buffer = Buffer.net_message_begin()
            buffer:write_ushort(SendType.DIRECT)
            fn(buffer, ...)
            Packet.internal.net_message_send(self.id, SendType.DIRECT, target)
        end
    end,


    --@instance
    --@param        target      |           | The target player to exclude.
    --@optional     ...         |           | A variable number of arguments to pass to the serialization function.
    --[[
    Sends a packet message all clients *except* a specific one.
    Usually called by the host in the deserializer by passing `player` as `target`.

    **Must be called as host.**
    ]]
    send_exclude = function(self, target, ...)
        if Net.client then log.error("send_exclude: Must be called from host", 2) end

        -- Call serialization function linked to packet ID
        local fn = __callbacks_onSerialize[self.value]
        if fn then
            local buffer = Buffer.net_message_begin()
            buffer:write_ushort(SendType.EXCLUDE)
            fn(buffer, ...)
            Packet.internal.net_message_send(self.id, SendType.EXCLUDE, target)
        end
    end,


    --@instance
    --@optional     ...         |           | A variable number of arguments to pass to the serialization function.
    --[[
    Sends a packet message to the host.

    **Must be called as client.**
    ]]
    send_to_host = function(self, ...)
        if Net.host then log.error("send_to_host: Must be called from client", 2) end

        -- Call serialization function linked to packet ID
        local fn = __callbacks_onSerialize[self.value]
        if fn then
            local buffer = Buffer.net_message_begin()
            buffer:write_ushort(SendType.HOST)
            fn(buffer, ...)
            Packet.internal.net_message_send(self.id, SendType.HOST)
        end
    end

}



-- ========== Metatables ==========

local wrapper_name = "Packet"

make_table_once("metatable_packet", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then k = "nsid" end
        if k == "RAPI" then return wrapper_name end

        -- Methods
        if methods_packet[k] then
            return methods_packet[k]
        end

        return __proxy[proxy][k]
    end,


    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI"
        or k == "namespace"
        or k == "identifier"
        or k == "nsid"
        or k == "id" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        log.error("Packet has no properties to set", 2)
    end,


    __metatable = "RAPI.Wrapper."..wrapper_name
})



-- ========== Hooks ==========

Callback.add(RAPI_NAMESPACE, Callback.NET_MESSAGE_ON_RECEIVED, function(packet, buffer, buffer_tell, player)
    if not packet then return end

    -- Check if packet has a deserialization function
    local fn = __callbacks_onDeserialize[packet.nsid]
    if not fn then return end

    -- Get send type
    local send_type = buffer:read_ushort()

    -- Client calling `send_to_all`
    if  (Net.host)
    and (send_type == SendType.ALL) then
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

        Packet.internal.net_message_send(packet.id, SendType.EXCLUDE, player)
    end

    -- Call deserialization function
    fn(buffer, player)
end)


-- Send identifier <-> packet ID table to new clients

Hook.add_post(RAPI_NAMESPACE, gm.constants.server_new_player, Callback.Priority.BEFORE, function(self, other, result, args)
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



-- Public export
__class.Packet = Packet