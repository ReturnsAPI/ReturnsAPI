-- ModOptionsButton

-- The class table is private, but the wrappers are publicly accessible

---@class ModOptionsButtonClass
ModOptionsButton = new_class()

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
---@return ModOptionsButton
ModOptionsButton.new = function(namespace, identifier)
    local callbacks = {}
    
    local element_data_table = {
        namespace   = namespace,
        identifier  = identifier,
        callbacks   = callbacks,
        constructor = function()
            return Struct.new(
                gm.constants.UIOptionsButton2,
                namespace.."."..identifier,

                -- Bind function to button that calls
                -- all functions in `callbacks` table
                Script.bind(function()
                    for _, fn in ipairs(callbacks) do
                        fn()
                    end
                end)
            ).value
        end
    }

    return ModOptionsButton.wrap(element_data_table)
end

--[[
Returns a ModOptionsButton wrapper containing the provided element table.
]]
---@param element table The element table to wrap.
---@return ModOptionsButton
ModOptionsButton.wrap = function(element)
    return new_proxy(unwrap(element), metatable)
end


-- ========== Wrapper Methods ==========

---@class ModOptionsButton
local methods = {}

--[[
Add a function(s) to call when the button is pressed.
]]
---@param ... function A variable amount of functions to call. <br>Alternatively, a table may be provided.
methods.add_callback = function(self, ...)
    local fns = {...}
    if type(fns[1]) == "table" then fns = fns[1] end

    for _, fn in ipairs(fns) do
        if type(fn) == "function" then
            table.insert(proxy[self].callbacks, fn)
        end
    end
end


-- ========== Metatables ==========

---@class ModOptionsButton
---@field value table The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field namespace string The namespace of the ModOptionsButton.
---@field identifier string The identifier of the ModOptionsButton.

local mt_name = "ModOptionsButton"

W.ModOptionsButton = {
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
metatable = W.ModOptionsButton