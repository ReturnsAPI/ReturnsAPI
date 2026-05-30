-- Buffer

-- The class table is private, but the wrappers are publicly accessible

--[[
Buffer wrappers are used internally by @link {Packet | Packet}.
]]
---@class BufferClass
Buffer = new_class()

local proxy = P.proxy
local metatable

local gm               = gm                         ---@type table<string, function>
local gm_buffer_exists = gm.buffer_exists           ---@type function
local gm_msg_begin     = gm._mod_net_message_begin  ---@type function
local new_proxy        = new_proxy
local to_bool          = Util.bool
local unwrap           = Wrap.unwrap


-- ========== Static Methods ==========

Buffer.net_message_begin = function()
    return Buffer.wrap(gm_msg_begin())
end

--[[
Returns a Buffer wrapper containing the provided buffer ID.
]]
---@param buffer_id number The buffer to wrap.
---@return Buffer
Buffer.wrap = function(buffer_id)
    if not gm_buffer_exists(buffer_id) then
        throw("buffer '"..tostring(buffer_id).."' does not exist")
    end
    return new_proxy(buffer_id, metatable)
end


-- ========== Wrapper Methods ==========

---@class Buffer
local methods = {}

---@param value Instance
methods.write_instance = function(self, value)
    gm.write_instance_direct(proxy[self], value)
end

---@param value boolean
methods.write_bool = function(self, value)
    self:write_byte(value and 1 or 0)
end

---@param value number `u8`
methods.write_byte = function(self, value)
    gm.writebyte_direct(proxy[self], unwrap(value))
end

---@param value number `s32`
methods.write_int = function(self, value)
    gm.writeint_direct(proxy[self], unwrap(value))
end

---@param value number `u32`
methods.write_uint = function(self, value)
    gm.writeuint_direct(proxy[self], unwrap(value))
end

---@param value number
methods.write_uint_packed = function(self, value)
    gm.writeuint_packed_direct(proxy[self], unwrap(value))
end

---@param value number `s16`
methods.write_short = function(self, value)
    gm.writeshort_direct(proxy[self], unwrap(value))
end

---@param value number `u16`
methods.write_ushort = function(self, value)
    gm.writeushort_direct(proxy[self], unwrap(value))
end

---@param value number `f16`
methods.write_half = function(self, value)
    gm.writehalf_direct(proxy[self], unwrap(value))
end

---@param value number `f32`
methods.write_float = function(self, value)
    gm.writefloat_direct(proxy[self], unwrap(value))
end

---@param value number `f64`
methods.write_double = function(self, value)
    gm.writedouble_direct(proxy[self], unwrap(value))
end

---@param value string
methods.write_string = function(self, value)
    gm.writestring_direct(proxy[self], unwrap(value))
end

---@param value number
methods.write_color = function(self, value)
    gm.write_color_direct(proxy[self], unwrap(value))
end

---@return Instance
methods.read_instance = function(self)
    return gm.read_instance_direct(proxy[self])
end

---@return boolean
methods.read_bool = function(self)
    return to_bool(self:read_byte())
end

---@return number `u8`
methods.read_byte = function(self)
    return gm.readbyte_direct(proxy[self])
end

---@return number `s32`
methods.read_int = function(self)
    return gm.readint_direct(proxy[self])
end

---@return number `u32`
methods.read_uint = function(self)
    return gm.readuint_direct(proxy[self])
end

---@return number
methods.read_uint_packed = function(self)
    return gm.readuint_packed_direct(proxy[self])
end

---@return number `s16`
methods.read_short = function(self)
    return gm.readshort_direct(proxy[self])
end

---@return number `u16`
methods.read_ushort = function(self)
    return gm.readushort_direct(proxy[self])
end

---@return number `f16`
methods.read_half = function(self)
    return gm.readhalf_direct(proxy[self])
end

---@return number `f32`
methods.read_float = function(self)
    return gm.readfloat_direct(proxy[self])
end

---@return number `f64`
methods.read_double = function(self)
    return gm.readdouble_direct(proxy[self])
end

---@return string
methods.read_string = function(self)
    return gm.readstring_direct(proxy[self])
end

---@return number
methods.read_color = function(self)
    return gm.read_color_direct(proxy[self])
end


-- ========== Metatables ==========

---@class Buffer
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.

local mt_name = "Buffer"

W.Buffer = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return proxy[t] end
        if k == "RAPI" then return mt_name end

        -- Methods
        local method = methods[k]
        if method then return method end
    end,

    __newindex = function(t, k, v)
        log.error(mt_name.." has no properties to set", 2)
    end,

    __metatable = mt_wrapper_name(mt_name),
}
metatable = W.Buffer