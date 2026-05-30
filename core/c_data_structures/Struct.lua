-- Struct

--[[
Allows for manipulation of GameMaker structs.

Struct wrappers can be get/set to using dot syntax <br>
(e.g., `struct.my_key = 123`).
]]
---@class StructClass
Struct = new_class()
C.Struct = Struct

local type             = type
local getmetatable     = debug.getmetatable
local gm_struct_create = gm.struct_create       ---@type function
local gm_struct_set    = gm.variable_struct_set ---@type function
local gm_struct_get    = gm.variable_struct_get ---@type function
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
        return gm_struct_create()
    end

    -- Create from Lua table
    if type(constructor) == "table" then
        local struct = gm_struct_create()
        for k, v in pairs(constructor) do
            gm_struct_set(struct, k, unwrap(v))
        end
        return struct
    end

    -- From constructor
    return gm["@@NewGMLObject@@"](constructor, ...)
end

--[[
**[!] DEPRECATED**

Returns a Struct wrapper containing the provided struct.
]]
---@deprecated
---@param struct Struct | sol.YYObjectBaseLuaWrapper | sol.YYObject* The struct to wrap.
---@return Struct
Struct.wrap = function(struct)
    return struct
end


-- ========== Wrapper Methods ==========

---@class Struct
local methods = {}

--[[
Returns a table of keys in use by the struct.
]]
---@return table keys
methods.get_keys = function(self)
    local arr = gm.variable_struct_get_names(self)
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
            tostring(self[key])
        )
    end
    print(str)
end


-- ========== Metatables ==========

---@class Struct
---@field value Struct *Legacy.* The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field [any] any

local mt_name = "Struct"

W.Struct = {
    __index = function(t, k)
        if k == "value" then return t end
        if k == "RAPI" then return mt_name end

        -- Methods
        local method = methods[k]
        if method then return method end

        -- Getter
        local ret = gm_struct_get(t, k)

        -- If Script, set its `self`/`other`
        local mt = getmetatable(ret)
        if mt and mt.__name == "sol.CScriptRef*" then
            ret.self  = t
            ret.other = t
        end
        
        return ret
    end,

    __newindex = function(t, k, v)
        -- Throw read-only error
        if k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        gm_struct_set(t, k, unwrap(v))
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

    __tostring = function(t)
        return mt_name..": "..get_usertype_pointer(t)
    end,
}

-- YYObjectBaseLuaWrapper
local s = gm.struct_create()
local mt = getmetatable(s)
table.merge(mt, W.Struct)

-- YYObjectBase*
local s = gm.new_struct()
local mt = getmetatable(s)
table.merge(mt, W.Struct)