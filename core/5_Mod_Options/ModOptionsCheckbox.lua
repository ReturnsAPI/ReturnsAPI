-- ModOptionsCheckbox

-- The class table is private, but the wrappers are publicly accessible

ModOptionsCheckbox = new_class()



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`RAPI`          | string    | *Read-only.* The wrapper name.
`namespace`     | string    | *Read-only.* The namespace of the ModOptions the element is in.
`identifier`    | string    | *Read-only.* The identifier of the element.
]]



-- ========== Static Methods ==========

ModOptionsCheckbox.new = function(namespace, identifier)
    local callbacks_get = {}
    local callbacks_set = {}

    local element_data_table = {
        namespace       = namespace,
        identifier      = identifier,
        callbacks_get   = callbacks_get,
        callbacks_set   = callbacks_set,
        constructor     = function()
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


ModOptionsCheckbox.wrap = function(element)
    -- Input:   ModOptionsCheckbox Lua table
    -- Wraps:   ModOptionsCheckbox Lua table
    return make_proxy(element, metatable_modoptionscheckbox)
end



-- ========== Instance Methods ==========

--@section Instance Methods

methods_modoptionscheckbox = {

    --@instance
    --@param        ...         | function(s)   | A variable amount of functions to call. <br>Alternatively, a table may be provided.
    --[[
    Add a function(s) that is called by the game to
    load the default value when opening the options menu.
    The function **should return a bool value.**
    ]]
    add_getter = function(self, ...)
        local fns = {...}
        if type(fns[1]) == "table" then fns = fns[1] end

        for _, fn in ipairs(fns) do
            if type(fn) == "function" then
                table.insert(__proxy[self].callbacks_get, fn)
            end
        end
    end,


    --@instance
    --@param        ...         | function(s)   | A variable amount of functions to call. <br>Alternatively, a table may be provided.
    --[[
    Add a function(s) to call when the checkbox is toggled.
    The parameters for it are `value` (bool).
    ]]
    add_setter = function(self, ...)
        local fns = {...}
        if type(fns[1]) == "table" then fns = fns[1] end

        for _, fn in ipairs(fns) do
            if type(fn) == "function" then
                table.insert(__proxy[self].callbacks_set, fn)
            end
        end
    end

}



-- ========== Metatables ==========

local wrapper_name = "ModOptionsCheckbox"

make_table_once("metatable_modoptionscheckbox", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return log.error("Cannot access "..wrapper_name.." internal table", 2) end
        if k == "RAPI" then return wrapper_name end

        -- Get certain values
        if k == "namespace" then return __proxy[proxy].namespace end
        if k == "identifier" then return __proxy[proxy].identifier end

        -- Methods
        if methods_modoptionscheckbox[k] then
            return methods_modoptionscheckbox[k]
        end
    end,


    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        log.error(wrapper_name.." has no properties to set", 2)
    end,


    __metatable = "RAPI.Wrapper."..wrapper_name
})