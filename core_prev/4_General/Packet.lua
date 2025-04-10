-- Packet

-- TODO test if everything still works

Packet = new_class()

if not __callbacks_onSerialize then __callbacks_onSerialize = {} end    -- Preserve on hotload
if not __callbacks_onDeserialize then __callbacks_onDeserialize = {} end



-- ========== Static Methods ==========

Packet.new = function()
    local id = GM._mod_net_message_getUniqueID()
    return Packet.wrap(id)
end

Packet.wrap = function(value)
    return Proxy.new(value, metatable_packet)
end



-- ========== Instance Methods ==========

methods_packet = {

    -- Callbacks
    set_serializers = function(self, serializer, deserializer)
        __callbacks_onSerialize[self.value] = serializer
        __callbacks_onDeserialize[self.value] = deserializer
    end,

    send_to_all = function(self, ...)
        if Net.is_client() then log.error("send_to_all: Must be called from host", 2) end

        local fn = __callbacks_onSerialize[self.value]

        if fn then
            local buffer = Buffer.wrap(GM._mod_net_message_begin())
            fn(buffer, ...)
            GM._mod_net_message_send(self.value, 0)
        end
    end,

    send_direct = function(self, target, ...)
        if Net.is_client() then log.error("send_direct: Must be called from host", 2) end

        local fn = __callbacks_onSerialize[self.value]

        if fn then
            local buffer = Buffer.wrap(GM._mod_net_message_begin())
            fn(buffer, ...)
            GM._mod_net_message_send(self.value, 1, Wrap.unwrap(target))
        end
    end,

    send_exclude = function(self, target, ...)
        if Net.is_client() then log.error("send_exclude: Must be called from host", 2) end

        local fn = __callbacks_onSerialize[self.value]

        if fn then
            local buffer = Buffer.wrap(GM._mod_net_message_begin())
            fn(buffer, ...)
            GM._mod_net_message_send(self.value, 2, Wrap.unwrap(target))
        end
    end,

    send_to_host = function(self, ...)
        if Net.is_host() then log.error("send_to_host: Must be called from client", 2) end

        local fn = __callbacks_onSerialize[self.value]

        if fn then
            local buffer = Buffer.wrap(GM._mod_net_message_begin())
            fn(buffer, ...)
            GM._mod_net_message_send(self.value, 3)
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
    local fn = __callbacks_onDeserialize[id]

    if fn then
        fn(Buffer.wrap(buffer_id), player)
    end
end

Callback.add(_ENV["!guid"], Callback.NET_MESSAGE_ON_RECEIVED, packet_onReceived)



__class.Packet = Packet