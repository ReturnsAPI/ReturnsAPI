-- Packet

Packet = new_class()

local callbacks_onSerialize = {}
local callbacks_onDeserialize = {}

-- ========== Static Methods ==========

Packet.new = function()
    local id = gm._mod_net_message_getUniqueID()
    return Packet.wrap(id)
end

Packet.wrap = function(value)
    return Proxy.new(value, metatable_packet)
end

-- ========== Instance Methods ==========

methods_packet = {

    -- Callbacks
    set_serializers = function(self, serializer, deserializer)
        callbacks_onSerialize[self.value] = serializer
        callbacks_onDeserialize[self.value] = deserializer
    end,

    send_to_all = function(self, ...)
        if gm._mod_net_isClient() then log.error("send_to_all: Must be called from host", 2) end

        local fn = callbacks_onSerialize[self.value]

        if fn then
            local buffer = Buffer.wrap(gm.._mod_net_message_begin())
            fn(buffer, ...)
            gm._mod_net_message_send(self.value, 0)
        end
    end,

    send_direct = function(self, target, ...)
        if gm._mod_net_isClient() then log.error("send_direct: Must be called from host", 2) end

        local fn = callbacks_onSerialize[self.value]

        if fn then
            local buffer = Buffer.wrap(gm.._mod_net_message_begin())
            fn(buffer, ...)
            gm._mod_net_message_send(self.value, 1, Wrap.unwrap(target))
        end
    end,

    send_exclude = function(self, target, ...)
        if gm._mod_net_isClient() then log.error("send_exclude: Must be called from host", 2) end

        local fn = callbacks_onSerialize[self.value]

        if fn then
            local buffer = Buffer.wrap(gm.._mod_net_message_begin())
            fn(buffer, ...)
            gm._mod_net_message_send(self.value, 2, Wrap.unwrap(target))
        end
    end,

    send_to_host = function(self, ...)
        if gm._mod_net_isHost() then log.error("send_to_host: Must be called from client", 2) end

        local fn = callbacks_onSerialize[self.value]

        if fn then
            local buffer = Buffer.wrap(gm.._mod_net_message_begin())
            fn(buffer, ...)
            gm._mod_net_message_send(self.value, 3)
        end
    end,

}

-- ========== Metatables ==========

metatable_packet = {
    __index = function(table, key)
        if k == "value" then return Proxy.get(t) end
        if k == "RAPI" then return getmetatable(t):sub(14, -1) end

        -- Methods
        if methods_packet[key] then
            return methods_packet[key]
        end

        return nil
    end,


    __newindex = function(table, key, value)
        log.error("Packet has no properties to set")
    end,


    __metatable = "RAPI.Wrapper.Packet"
}

-- ========== Internal ==========

local function packet_onReceived(id, buffer_id, buffer_tell, player)
    local fn = callbacks_onDeserialize[id]

    if fn then
        fn(Buffer.wrap(buffer_id), Instance.wrap(player))
    end
end

Callback.add(_ENV["!guid"], Callback.NET_MESSAGE_ON_RECEIVED, packet_onReceived)

_CLASS["Packet"] = Packet
