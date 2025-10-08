-- Packet

Packet = new_class()

run_once(function()
    -- Stores callback functions to run on serialization/deserialization
    __callbacks_onSerialize = {}
    __callbacks_onDeserialize = {}
end)

local SendType = {
    ALL     = 0,
    DIRECT  = 1,
    EXCLUDE = 2,
    HOST    = 3
}



-- ========== Internal ==========

Packet.internal.net_message_send = function(packet_id, send_type, target)
    gm._mod_net_message_send(packet_id, send_type, Wrap.unwrap(target))
end



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       Packet
--[[
Creates a new Packet and returns it.
]]
Packet.new = function()
    local id = gm._mod_net_message_getUniqueID()
    return Packet.wrap(id)
end


--@static
--@return       Packet
--@param        packet_id   | number    | The packet ID to wrap.
--[[
Returns a Packet wrapper containing the provided packet ID.
]]
Packet.wrap = function(packet_id)
    -- Input:   number
    -- Wraps:   number
    return make_proxy(packet_id, metatable_packet)
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
                Packet.internal.net_message_send(self.value, SendType.ALL)
            end

        elseif Net.client then
            -- Call serialization function linked to packet ID
            local fn = __callbacks_onSerialize[self.value]
            if fn then
                local buffer = Buffer.net_message_begin()
                buffer:write_ushort(SendType.ALL)
                fn(buffer, ...)
                Packet.internal.net_message_send(self.value, SendType.HOST)
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
            Packet.internal.net_message_send(self.value, SendType.DIRECT, target)
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
            Packet.internal.net_message_send(self.value, SendType.EXCLUDE, target)
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
            Packet.internal.net_message_send(self.value, SendType.HOST)
        end
    end

}



-- ========== Metatables ==========

local wrapper_name = "Packet"

make_table_once("metatable_packet", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return __proxy[proxy] end
        if k == "RAPI" then return wrapper_name end

        -- Methods
        if methods_packet[k] then
            return methods_packet[k]
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
        log.error("Packet has no properties to set", 2)
    end,


    __metatable = "RAPI.Wrapper."..wrapper_name
})



-- ========== Callback ==========

Callback.add(RAPI_NAMESPACE, Callback.NET_MESSAGE_ON_RECEIVED, function(packet, buffer, buffer_tell, player)
    -- Check if packet has a deserialization function
    local fn = __callbacks_onDeserialize[packet.value]
    if not fn then return end

    -- gm.buffer_seek(buffer.value, 0, 2)
    -- print("buffer tell", buffer_tell)

    -- Get send type
    local send_type = buffer:read_ushort()

    -- print("buffer seek", gm.buffer_tell(buffer.value))

    -- print("send type", send_type)
    -- print("string", buffer:read_string())

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

        Packet.internal.net_message_send(packet.value, SendType.EXCLUDE, player)
    end

    -- Call deserialization function
    fn(buffer, player)
end)



-- Public export
__class.Packet = Packet