-- ModOptionsDropdown

-- The class table is private, but the wrappers are publicly accessible

---@class ModOptionsDropdownClass
ModOptionsDropdown = new_class()

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
---@return ModOptionsDropdown
ModOptionsDropdown.new = function(namespace, identifier)
    local callbacks_get = {}
    local callbacks_set = {}
    local choices       = {}
    
    local element_data_table = {
        namespace       = namespace,
        identifier      = identifier,
        callbacks_get   = callbacks_get,
        callbacks_set   = callbacks_set,
        choices         = choices,
        constructor     = function()
            local choices_array = Array.new()
            for i, token in ipairs(choices) do
                choices_array:push(Array.new{gm.translate(token), i - 1})
            end

            return Struct.new(
                gm.constants.UIOptionsButtonDropdown,
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
                
                -- Choices
                choices_array
            ).value
        end
    }

    return ModOptionsDropdown.wrap(element_data_table)
end

--[[
Returns a ModOptionsDropdown wrapper containing the provided element table.
]]
---@param element table The element table to wrap.
---@return ModOptionsDropdown
ModOptionsDropdown.wrap = function(element)
    return new_proxy(unwrap(element), metatable)
end


-- ========== Wrapper Methods ==========

---@class ModOptionsDropdown
local methods = {}

--[[
Add a function(s) that is called by the game to <br>
load the default choice when opening the options menu. <br>
The function **should return a number value between `0` and `number of choices - 1`.**
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
Add a function(s) to call when a choice is toggled. <br>
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

--[[
Add a choice(s) to the dropdown.
]]
---@param ... string A variable amount of localization tokens for each choice. <br>Alternatively, a table may be provided.
methods.add_choice = function(self, ...)
    local choices = {...}
    if type(choices[1]) == "table" then choices = choices[1] end

    for _, token in ipairs(choices) do
        if type(token) == "string" then
            table.insert(proxy[self].choices, token)
        end
    end
end


-- ========== Metatables ==========

---@class ModOptionsDropdown
---@field value table The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field namespace string The namespace of the ModOptionsDropdown.
---@field identifier string The identifier of the ModOptionsDropdown.

local mt_name = "ModOptionsDropdown"

W.ModOptionsDropdown = {
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
metatable = W.ModOptionsDropdown