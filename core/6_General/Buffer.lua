-- Buffer

--[[
Buffer wrappers are used internally by @link {Packet | Packet}.
]]

-- The class table is private, but the wrappers are publicly accessible

Buffer = new_class()



-- ========== Static Methods ==========

Buffer.net_message_begin = function()
    return Buffer.wrap(gm._mod_net_message_begin())
end


-- Returns a Buffer wrapper; buffer ID is a number
Buffer.wrap = function(buffer_id)
    -- Input:   number
    -- Wraps:   number
    if not gm.buffer_exists(buffer_id) then
        log.error("Buffer.wrap: buffer '"..tostring(buffer_id).."' does not exist", 2)
    end
    return make_proxy(buffer_id, metatable_buffer)
end



-- ========== Instance Methods ==========

methods_buffer = {

    write_instance = function(self, instance)
        gm.write_instance_direct(self.value, Wrap.unwrap(instance, true))
    end,


    read_instance = function(self)
        return Instance.wrap(gm.read_instance_direct(self.value))
    end

}


-- Add instance methods for primitive types to `methods_buffer`
local primitive_types = {
    "byte",
    "int",
    "uint",
    "uint_packed",
    "short",
    "ushort",
    "half",
    "float",
    "double",
    "string",
    "_color",
}

for _, type_name in ipairs(primitive_types) do
    do -- writes
        local method_name = "write_"..type_name
        local gm_name = "write"..type_name.."_direct"

        methods_buffer[method_name] = function(self, value)
            gm[gm_name](self.value, Wrap.unwrap(value, true))
        end
    end

    do -- reads
        local method_name = "read_"..type_name
        local gm_name = "read"..type_name.."_direct"

        methods_buffer[method_name] = function(self)
            return Wrap.wrap(gm[gm_name](self.value))
        end
    end
end



-- ========== Metatables ==========

local wrapper_name = "Buffer"

make_table_once("metatable_buffer", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return __proxy[proxy] end
        if k == "RAPI" then return wrapper_name end

        -- Methods
        if methods_buffer[k] then
            return methods_buffer[k]
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
        log.error("Buffer has no properties to set", 2)
    end,


    __metatable = "RAPI.Wrapper."..wrapper_name
})