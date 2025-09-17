-- Packet

Packet = new_class()

run_once(function()
    -- Stores callback functions to run on serialization/deserialization
    __callbacks_onSerialize = {}
    __callbacks_onDeserialize = {}
end)



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
    The arguments for each are `buffer, player`.
    ]]
    set_serializers = function(self, serializer, deserializer)
        __callbacks_onSerialize[self.value] = serializer
        __callbacks_onDeserialize[self.value] = deserializer
    end,


    --@instance
    --@optional     ...         |           | A variable number of arguments to pass to the serialization function.
    --[[
    Sends a packet message to all clients.
    Must be called as host.
    ]]
    send_to_all = function(self, ...)
        if Net.client then log.error("send_to_all: Must be called from host", 2) end

        -- Call serialization function linked to packet ID
        local fn = __callbacks_onSerialize[self.value]
        if fn then
            local buffer = Buffer.net_message_begin()
            fn(buffer, ...)
            Packet.internal.net_message_send(self.value, 0)
        end
    end,


    --@instance
    --@param        target      |           | The target player to send to.
    --@optional     ...         |           | A variable number of arguments to pass to the serialization function.
    --[[
    Sends a packet message to a specific client.
    Must be called as host.
    ]]
    send_direct = function(self, target, ...)
        if Net.client then log.error("send_direct: Must be called from host", 2) end

        -- Call serialization function linked to packet ID
        local fn = __callbacks_onSerialize[self.value]
        if fn then
            local buffer = Buffer.net_message_begin()
            fn(buffer, ...)
            Packet.internal.net_message_send(self.value, 1, target)
        end
    end,


    --@instance
    --@param        target      |           | The target player to exclude.
    --@optional     ...         |           | A variable number of arguments to pass to the serialization function.
    --[[
    Sends a packet message all clients *except* a specific one.
    Must be called as host.
    ]]
    send_exclude = function(self, target, ...)
        if Net.client then log.error("send_exclude: Must be called from host", 2) end

        -- Call serialization function linked to packet ID
        local fn = __callbacks_onSerialize[self.value]
        if fn then
            local buffer = Buffer.net_message_begin()
            fn(buffer, ...)
            Packet.internal.net_message_send(self.value, 2, target)
        end
    end,


    --@instance
    --@optional     ...         |           | A variable number of arguments to pass to the serialization function.
    --[[
    Sends a packet message to the host.
    Must be called as client.
    ]]
    send_to_host = function(self, ...)
        if Net.host then log.error("send_to_host: Must be called from client", 2) end

        -- Call serialization function linked to packet ID
        local fn = __callbacks_onSerialize[self.value]
        if fn then
            local buffer = Buffer.net_message_begin()
            fn(buffer, ...)
            Packet.internal.net_message_send(self.value, 3)
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