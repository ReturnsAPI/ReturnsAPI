-- ModOptionsTextField

-- The class table is private, but the wrappers are publicly accessible

---@class ModOptionsTextFieldClass
ModOptionsTextField = new_class()

local proxy = P.proxy
local metatable

local type      = type
local table     = table
local gm        = gm
local new_proxy = new_proxy
local unwrap    = Wrap.unwrap
local Struct    = Struct
local Script    = Script

-- todo gamepad navigation id and numeric mode option


-- ========== Static Methods ==========

---@param namespace string
---@param identifier string
---@param max_length number
---@param numeric_only boolean
---@return ModOptionsTextField
ModOptionsTextField.new = function(namespace, identifier, max_length, numeric_only)
    local callbacks_get = {}
    local callbacks_set = {}
    local choices       = {}
    
    local element_data_table = {
        namespace       = namespace,
        identifier      = identifier,
        callbacks_get   = callbacks_get,
        callbacks_set   = callbacks_set,
        
        max_length      = max_length or 250,
        numeric_only    = numeric_only or false,

        constructor = function()
            local struct = Struct.new(
                gm.constants.UIOptionsButtonBase,
                namespace.."."..identifier,

                Script.bind(function()
                    local ret
                    for _, fn in ipairs(callbacks_get) do
                        ret = fn()
                    end
                    return ret
                end),

                Script.bind(function(value)
                    for _, fn in ipairs(callbacks_set) do
                        fn(value)
                    end
                end)
            ).value
            return struct
        end
    }

    local tf = {
        max_length   = max_length or 250,
        numeric_only = numeric_only or false,
        set          = function(value)
            for _, fn in ipairs(callbacks_set) do
                fn(value)
            end
        end,
        last_value = nil
    }
    return ModOptionsTextField.wrap(element_data_table), tf
end

--[[
Returns a ModOptionsTextField wrapper containing the provided element table.
]]
---@param element table The element table to wrap.
---@return ModOptionsTextField
ModOptionsTextField.wrap = function(element)
    return new_proxy(unwrap(element), metatable)
end


-- ========== Wrapper Methods ==========

---@class ModOptionsTextField
local methods = {}

--[[
TODO
]]
---@param ... function A variable amount of functions to call. <br>Alternatively, a table may be provided.
methods.add_getter = function(self, ...)
    local fns = {...}
    if type(fns[1]) == "table" then fns = fns[1] end

    for _, fn in ipairs(fns) do
        if type(fn) == "function" then
            table.insert(proxy[self].callbacks_get, fn)
        end
    end
end

--[[
TODO
]]
---@param ... fun() A variable amount of functions to call. <br>Alternatively, a table may be provided.
methods.add_setter = function(self, ...)
    local fns = {...}
    if type(fns[1]) == "table" then fns = fns[1] end

    for _, fn in ipairs(fns) do
        if type(fn) == "function" then
            table.insert(proxy[self].callbacks_set, fn)
        end
    end
end


-- ========== Metatables ==========

---@class ModOptionsButton
---@field value table The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field namespace string The namespace of the ModOptionsButton.
---@field identifier string The identifier of the ModOptionsButton.
---@field max_length number The maximum number of characters allowed in the text field (default 250).
---@field numeric_only boolean *Disabled* Whether the text field only accepts numeric input (false by default).

local mt_name = "ModOptionsTextField"

W.ModOptionsTextField = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return log.error("Cannot access "..mt_name.." internal table", 2) end
        if k == "RAPI" then return mt_name end

        -- Get certain values
        if k == "namespace"    then return proxy[t].namespace end
        if k == "identifier"   then return proxy[t].identifier end
        if k == "max_length"   then return proxy[t].max_length end
        if k == "numeric_only" then return proxy[t].numeric_only end

        -- Methods
        local method = methods[k]
        if method then return method end

        log.error(mt_name.." has no method '"..k.."'", 2)
    end,

    __newindex = function(t, k, v)
        log.error(mt_name.." has no properties to set", 2)
    end,

    __tostring = function(t)
        return mt_name..": "..get_table_pointer(t)
    end,

    __metatable = mt_wrapper_name(mt_name),
}
metatable = W.ModOptionsTextField