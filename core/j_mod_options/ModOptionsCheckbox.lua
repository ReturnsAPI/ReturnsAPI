-- ModOptionsCheckbox

-- The class table is private, but the wrappers are publicly accessible

---@class ModOptionsCheckboxClass
ModOptionsCheckbox = new_class()

local proxy = P.proxy
local metatable

local type      = type
local table     = table
local gm        = gm
local new_proxy = new_proxy
local unwrap    = Wrap.unwrap
local Struct    = Struct
local Script    = Script


-- ========== Static Methods ==========

---@param namespace string
---@param identifier string
---@return ModOptionsCheckbox
ModOptionsCheckbox.new = function(namespace, identifier)
    local callbacks_get = {}
    local callbacks_set = {}

    local element_data_table = {
        namespace     = namespace,
        identifier    = identifier,
        callbacks_get = callbacks_get,
        callbacks_set = callbacks_set,
        constructor   = function()
            return Struct.new(
                gm.constants.UIOptionsButtonToggle,
                namespace.."."..identifier,

                -- Getter(s)
                Script.bind(function()
                    local ret
                    for _, fn in ipairs(callbacks_get) do
                        ret = fn()
                    end
                    return ret
                end),

                -- Setter(s)
                Script.bind(function(value)
                    for _, fn in ipairs(callbacks_set) do
                        fn(value)
                    end
                end)
            ).value
        end
    }

    return ModOptionsCheckbox.wrap(element_data_table)
end

--[[
Returns a ModOptionsCheckbox wrapper containing the provided element table.
]]
---@param element table The element table to wrap.
---@return ModOptionsCheckbox
ModOptionsCheckbox.wrap = function(element)
    return new_proxy(unwrap(element), metatable)
end


-- ========== Wrapper Methods ==========

---@class ModOptionsCheckbox
local methods = {}

--[[
Add a function(s) that is called by the game to <br>
load the default value when opening the options menu. <br>
The function **should return a bool value.**
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
Add a function(s) to call when the checkbox is toggled. <br>
The parameters for it are `value` (boolean).
]]
---@param ... fun(value: boolean) A variable amount of functions to call. <br>Alternatively, a table may be provided.
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

---@class ModOptionsCheckbox
---@field value table The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field namespace string The namespace of the ModOptionsCheckbox.
---@field identifier string The identifier of the ModOptionsCheckbox.

local mt_name = "ModOptionsCheckbox"

W.ModOptionsCheckbox = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return log.error("Cannot access "..mt_name.." internal table", 2) end
        if k == "RAPI" then return mt_name end

        -- Get certain values
        if k == "namespace"  then return proxy[t].namespace end
        if k == "identifier" then return proxy[t].identifier end

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
metatable = W.ModOptionsCheckbox