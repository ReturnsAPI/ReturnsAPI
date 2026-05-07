-- Struct

--[[
Allows for manipulation of GameMaker structs.

Struct wrappers can be get/set to using dot syntax <br>
(e.g., `struct.my_key = 123`).
]]
---@class Struct
Struct = new_class()
C.Struct = Struct

local proxy = P.proxy
local metatable

local type             = type
local table_pack       = table.pack
local table_unpack     = table.unpack
local gm_struct_create = gm.struct_create
local gm_struct_set    = gm.variable_struct_set
local gm_struct_get    = gm.variable_struct_get
local new_proxy        = new_proxy
local wrap             = Wrap.wrap
local unwrap           = Wrap.unwrap


-- ========== Static Methods ==========

--[[
Returns a newly created GameMaker struct. <br>
Can also create one from a constructor.
]]
---@param t? table A key-value pair table to convert into a struct.
---@return Struct
Struct.new = function(t) end

--[[
Returns a newly created GameMaker struct. <br>
Can also create one from a constructor.
]]
---@param constructor? any A constructor.
---@param ... any Arguments to pass to the constructor.
---@return Struct
Struct.new = function(constructor, ...)
    -- Blank struct
    if not constructor then
        return Struct.wrap(gm_struct_create())
    end

    -- Create from Lua table
    if type(constructor) == "table" then
        local struct = gm_struct_create()
        for k, v in pairs(constructor) do
            struct[k] = unwrap(v)
        end
        return Struct.wrap(struct)
    end

    -- From constructor
    local args = table_pack(...)
    for i = 1, args.n do
        args[i] = unwrap(args[i])
    end
    return Struct.wrap(gm["@@NewGMLObject@@"](constructor, table_unpack(args)))
end

--[[
Returns a Struct wrapper containing the provided struct.
]]
---@param struct Struct | sol.YYObjectBaseLuaWrapper | sol.YYObject* The struct to wrap.
---@return Struct
Struct.wrap = function(struct)
    return new_proxy(unwrap(struct), metatable)
end


-- ========== Wrapper Methods ==========

---@class Struct
local methods = {}

--[[
Returns a table of keys in use by the struct.
]]
---@return table
methods.get_keys = function(self)
    local arr = Array.wrap(gm.variable_struct_get_names(self.value))
    local keys = {}
    for i, v in ipairs(arr) do keys[i] = v end
    return keys
end

--[[
Prints the struct.
]]
methods.print = function(self)
    local str = ""
    local keys = self:get_keys()
    for _, key in ipairs(keys) do
        str = string.format(
            "%s\n%s = %s",
            str,
            String.pad_right(key, 32),
            Util.tostring(self[key])
        )
    end
    print(str)
end


-- ========== Metatables ==========

---@class Struct
---@field value sol.YYObjectBaseLuaWrapper | sol.YYObject*
---@field cinstance sol.YYObjectBaseLuaWrapper | sol.YYObject*
---@field RAPI string
---@field [any] any

local mt_name = "Struct"

W.Struct = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" or k == "cinstance" then return proxy[t] end
        if k == "RAPI" then return mt_name end

        -- Methods
        if methods[k] then return methods[k] end

        -- Getter
        local ret = wrap(gm_struct_get(proxy[t], k))

        -- If Script, set its `self`/`other`
        if type(ret) == "table"
        and ret.RAPI == "Script" then
            ret.self  = t  -- Will be unwrapped in Script set
            ret.other = t
        end
        
        return ret
    end,

    __newindex = function(t, k, v)
        -- Throw read-only error
        if k == "value"
        or k == "cinstance"
        or k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        gm_struct_set(proxy[t], k, unwrap(v))
    end,

    __len = function(t)
        return #t:get_keys()
    end,

    __pairs = function(t)
        local keys = t:get_keys()
        local i = 0
        return function()
            i = i + 1
            if i <= #keys then
                local k = keys[i]
                return k, t[k]
            end
        end
    end,

    __metatable = mt_wrapper_name(mt_name),
}
metatable = W.Struct