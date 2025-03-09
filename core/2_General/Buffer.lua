-- Buffer

Buffer = new_class()



-- ========== Static Methods ==========

Buffer.internal.wrap = function(buffer)
    if not gm.buffer_exists(buffer) then
        log.error("Buffer does not exist", 2)
    end

    return Proxy.new(buffer, metatable_buffer)
end


-- ========== Instance Methods ==========

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

methods_buffer = {
    write_instance = function(self, instance)
        gm.write_instance_direct(self.value, Wrap.unwrap(instance))
    end,
    read_instance = function(self)
        return Instance.wrap(gm.read_instance_direct(self.value))
    end,
}

for _, type_name in ipairs(primitive_types) do
    do -- writes
        local method_name = "write_"..type_name
        local gm_function = gm["write"..type_name.."_direct"]

        methods_buffer[method_name] = function(self, value)
            gm_function(self.value, value)
        end
    end

    do -- reads
        local method_name = "read_"..type_name
        local gm_function = gm["read"..type_name.."_direct"]

        methods_buffer[method_name] = function(self)
            return gm_function(self.value)
        end
    end
end

metatable_buffer = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(t) end
        if k == "RAPI" then return getmetatable(t):sub(14, -1) end

        -- Methods
        if methods_buffer[k] then
            return methods_buffer[k]
        end

        return nil
    end,


    __newindex = function(t, k, v)
        -- Set instance variable
        gm.variable_instance_set(Proxy.get(t), k, Wrap.unwrap(v))
    end,


    __metatable = "RAPI.Wrapper.Buffer"
}

-- No reason to export this since there are zero static methods the user can call (if .wrap is in `internal`)
-- _CLASS["Buffer"] = Buffer
