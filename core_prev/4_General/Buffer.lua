-- Buffer

-- TODO read comments below and figure out
if true then return end

-- TODO test if everything still works

Buffer = new_class()



-- ========== Static Methods ==========

Buffer.internal.wrap = function(buffer)
    local holder = RValue.new_holder(1)
    holder[0] = RValue.new(buffer)  -- TODO figure out what type RValue type to wrap `buffer` as
    local out = RValue.new(0)
    gmf.buffer_exists(out, nil, nil, 1, holder)
    local exists = RValue.to_wrapper(out)
    if not exists then
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
        local holder = RValue.new_holder_scr(2)
        holder[0] = RValue.new(self.value)  -- TODO figure out what type RValue type to wrap `self.value` as
        holder[1] = RValue.from_wrapper(instance)
        gmf.write_instance_direct(nil, nil, RValue.new(0), 2, holder)
    end,

    read_instance = function(self)
        -- TODO test if read_instance_direct is an instance ID here (or RValue.Type.REF)
        -- if not, will have to get .id
        local holder = RValue.new_holder_scr(1)
        holder[0] = RValue.new(self.value)  -- TODO figure out what type RValue type to wrap `self.value` as
        local out = RValue.new(0)
        gmf.read_instance_direct(nil, nil, out, 1, holder)
        RValue.peek(out)    -- TODO get the result of this
        local inst = RValue.to_wrapper(out)
        return Instance.wrap(inst)
    end,
}

for _, type_name in ipairs(primitive_types) do
    do -- writes
        local method_name = "write_"..type_name

        methods_buffer[method_name] = function(self, value)
            local holder = RValue.new_holder_scr(2)
            holder[0] = RValue.new(self.value)  -- TODO figure out what type RValue type to wrap `self.value` as
            holder[1] = RValue.new(value)
            gmf[method_name](nil, nil, RValue.new(0), 2, holder)
        end
    end

    do -- reads
        local method_name = "read_"..type_name

        methods_buffer[method_name] = function(self)
            local holder = RValue.new_holder_scr(1)
            holder[0] = RValue.new(self.value)  -- TODO figure out what type RValue type to wrap `self.value` as
            local out = RValue.new(0)
            gmf[method_name](nil, nil, out, 1, holder)
            return RValue.to_wrapper(out)
        end
    end
end

metatable_buffer = {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(proxy) end
        if k == "RAPI" then return getmetatable(proxy):sub(14, -1) end

        -- Methods
        if methods_buffer[k] then
            return methods_buffer[k]
        end

        return nil
    end,


    __newindex = function(proxy, k, v)
        log.error("Buffer has nothing to set", 2)
    end,


    __metatable = "RAPI.Wrapper.Buffer"
}



-- No reason to export this since there are zero static methods the user can call (if .wrap is in `internal`)
-- __class.Buffer = Buffer