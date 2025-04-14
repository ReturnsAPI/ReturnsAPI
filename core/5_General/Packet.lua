-- Packet

Packet = new_class()

run_once(function()
    -- Stores callback functions to run on serialization/deserialization
    __callbacks_onSerialize = {}
    __callbacks_onDeserialize = {}
end)



-- ========== Static Methods ==========

--$static
--$return       Packet
--[[
Creates a new Packet and returns it.
]]
Packet.new = function()
    local id = GM._mod_net_message_getUniqueID()
    return Packet.wrap(id)
end


--$static
--$return       Packet
--$param        packet_id   | number    | The packet ID to wrap.
--[[
Returns a Packet wrapper containing the provided packet ID.
]]
Packet.wrap = function(packet_id)
    return Proxy.new(packet_id, metatable_packet)
end


Packet.internal._mod_net_message_send = function(packet_id, send_type, target)
    local holder = RValue.new_holder_scr(3)
    holder[0] = RValue.new(packet_id)
    holder[1] = RValue.new(send_type)
    holder[2] = RValue.from_wrapper(target)
    gmf._mod_net_message_send(nil, nil, RValue.new(0), 3, holder)
end



-- ========== Instance Methods ==========

make_table_once("methods_packet", {

    --$instance
    --$param        serializer      | function  | The serialization function.
    --$param        deserializer    | function  | The deserialization function.
    --[[
    Set the serialization and deserialization functions for the packet.
    ]]
    set_serializers = function(self, serializer, deserializer)
        __callbacks_onSerialize[self.value] = serializer
        __callbacks_onDeserialize[self.value] = deserializer
    end,


    --$instance
    --$optional     ...         |           | A variable number of arguments to pass to the serialization function.
    --[[
    Sends a packet message to all clients.
    Must be called as host.
    ]]
    send_to_all = function(self, ...)
        if Net.is_client() then log.error("send_to_all: Must be called from host", 2) end

        -- Call serialization function linked to packet ID
        local fn = __callbacks_onSerialize[self.value]
        if fn then
            local buffer = Buffer._mod_net_message_begin()
            fn(buffer, ...)
            Packet.internal._mod_net_message_send(self.value, 0)
        end
    end,


    --$instance
    --$param        target      |           | The target player to send to.
    --$optional     ...         |           | A variable number of arguments to pass to the serialization function.
    --[[
    Sends a packet message to a specific client.
    Must be called as host.
    ]]
    send_direct = function(self, target, ...)
        if Net.is_client() then log.error("send_direct: Must be called from host", 2) end

        -- Call serialization function linked to packet ID
        local fn = __callbacks_onSerialize[self.value]
        if fn then
            local buffer = Buffer._mod_net_message_begin()
            fn(buffer, ...)
            Packet.internal._mod_net_message_send(self.value, 1, target)
        end
    end,


    --$instance
    --$param        target      |           | The target player to exclude.
    --$optional     ...         |           | A variable number of arguments to pass to the serialization function.
    --[[
    Sends a packet message all clients *except* a specific one.
    Must be called as host.
    ]]
    send_exclude = function(self, target, ...)
        if Net.is_client() then log.error("send_exclude: Must be called from host", 2) end

        -- Call serialization function linked to packet ID
        local fn = __callbacks_onSerialize[self.value]
        if fn then
            local buffer = Buffer._mod_net_message_begin()
            fn(buffer, ...)
            Packet.internal._mod_net_message_send(self.value, 2, target)
        end
    end,


    --$instance
    --$optional     ...         |           | A variable number of arguments to pass to the serialization function.
    --[[
    Sends a packet message to the host.
    Must be called as client.
    ]]
    send_to_host = function(self, ...)
        if Net.is_host() then log.error("send_to_host: Must be called from client", 2) end

        -- Call serialization function linked to packet ID
        local fn = __callbacks_onSerialize[self.value]
        if fn then
            local buffer = Buffer._mod_net_message_begin()
            fn(buffer, ...)
            Packet.internal._mod_net_message_send(self.value, 3)
        end
    end

})



-- ========== Metatables ==========

make_table_once("metatable_packet", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(proxy) end
        if k == "RAPI" then return getmetatable(proxy):sub(14, -1) end

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


    __metatable = "RAPI.Wrapper.Packet"
})



-- ========== Internal ==========

run_once(function()
    local function packet_onReceived(packet, buffer, buffer_tell, player)
        -- Call deserialization function linked to packet ID
        local fn = __callbacks_onDeserialize[packet.value]
        if fn then fn(buffer, player) end
    end

    Callback.add(_ENV["!guid"], Callback.NET_MESSAGE_ON_RECEIVED, packet_onReceived)
end)



-- Public export
__class.Packet = Packet