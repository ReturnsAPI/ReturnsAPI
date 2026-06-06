-- ModOptionsSlider

-- The class table is private, but the wrappers are publicly accessible

---@class ModOptionsSliderClass
ModOptionsSlider = new_class()

local proxy = P.proxy
local metatable

local type      = type
local table     = table
local gm        = gm
local new_proxy = new_proxy
local unwrap    = Wrap.unwrap
local Struct    = Struct
local Script    = Script


-- ========== Enums ==========

ModOptionsSlider.DisplayType = {
    NONE       = 0,
    PERCENTAGE = 1,
    MULTIPLIER = 2,
    RAW        = 3,
    QUALITY    = 4,
}


-- ========== Static Methods ==========

---@param namespace string
---@param identifier string
---@param display_type number
---@param value_min number
---@param value_max number
---@param value_int boolean
---@return ModOptionsSlider
ModOptionsSlider.new = function(namespace, identifier, display_type, value_min, value_max, value_int)
    local callbacks_get = {}
    local callbacks_set = {}

    local element_data_table = {
        namespace       = namespace,
        identifier      = identifier,
        callbacks_get   = callbacks_get,
        callbacks_set   = callbacks_set,
        constructor     = function()
            return Struct.new(
                gm.constants.UIOptionsButtonSlider,
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
                end),
                display_type,
                value_min, 
                value_max, 
                value_int
            ).value
        end
    }

    return ModOptionsSlider.wrap(element_data_table)
end

--[[
Returns a ModOptionsSlider wrapper containing the provided element table.
]]
---@param element table The element table to wrap.
---@return ModOptionsSlider
ModOptionsSlider.wrap = function(element)
    return new_proxy(unwrap(element), metatable)
end


-- ========== Wrapper Methods ==========

---@class ModOptionsSlider
local methods = {}

--[[
Add a function(s) that is called by the game to <br>
load the default value when opening the options menu. <br>
The function **should return a number between the min_value and max_value, as well as respecting the value_int boolean**
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
Add a function(s) to call when the slider value is changed. <br>
The parameters for it are `value` (number).
]]
---@param ... fun(value: number) A variable amount of functions to call. <br>Alternatively, a table may be provided.
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

---@class ModOptionsSlider
---@field value table The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field namespace string The namespace of the ModOptionsSlider.
---@field identifier string The identifier of the ModOptionsSlider.

local mt_name = "ModOptionsSlider"

W.ModOptionsSlider = {
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

    __metatable = mt_wrapper_name(mt_name),
}
metatable = W.ModOptionsSlider