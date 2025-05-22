-- Buffer

--[[
Buffer wrappers are used internally by @link {Packet | Packet}.
]]

-- The class table is private, but the wrappers are publicly accessible

Buffer = new_class()



-- ========== Static Methods ==========

Buffer.net_message_begin = function()
    local out = RValue.new(0)
    gmf._mod_net_message_begin(nil, nil, out, 0, nil)
    return Buffer.wrap(out.value)
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
        local holder = RValue.new_holder_scr(2)
        holder[0] = RValue.new(self.value)
        holder[1] = RValue.from_wrapper(instance)
        gmf.write_instance_direct(nil, nil, RValue.new(0), 2, holder)
    end,


    read_instance = function(self)
        local holder = RValue.new_holder_scr(1)
        holder[0] = RValue.new(self.value)
        local out = RValue.new(0)
        gmf.read_instance_direct(nil, nil, out, 1, holder)  -- `out` is RValue.Type.REF
        return RValue.to_wrapper(out)
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
            local holder = RValue.new_holder_scr(2)
            holder[0] = RValue.new(self.value)
            holder[1] = RValue.new(Wrap.unwrap(value))
            gmf[gm_name](nil, nil, RValue.new(0), 2, holder)
        end
    end

    do -- reads
        local method_name = "read_"..type_name
        local gm_name = "read"..type_name.."_direct"

        methods_buffer[method_name] = function(self)
            local holder = RValue.new_holder_scr(1)
            holder[0] = RValue.new(self.value)
            local out = RValue.new(0)
            gmf[gm_name](nil, nil, out, 1, holder)
            return RValue.to_wrapper(out)
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