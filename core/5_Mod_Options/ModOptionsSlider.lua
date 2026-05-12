-- ModOptionsSlider

-- The class table is private, but the wrappers are publicly accessible

ModOptionsSlider = new_class()

-- ========== Enums ==========

--@section Enums

--@enum
--@name display_type
--[[
TODO display_type enum
]]

-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`RAPI`          | string    | *Read-only.* The wrapper name.
`namespace`     | string    | *Read-only.* The namespace of the ModOptions the element is in.
`identifier`    | string    | *Read-only.* The identifier of the element.
`display_type`  | number    | *Read-only.* The display_type of the slider (percentage by default).
`value_min`     | number    | *Read-Only.* The minimum value of the slider (0 by default).
`value_max`     | number    | *Read-Only.* The maximum value of the slider (1 by default).
`value_int`     | bool      | *Read-Only.* Whether the value is limited to integers (false by default).
]]



-- ========== Static Methods ==========

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


ModOptionsSlider.wrap = function(element)
    -- Input:   ModOptionsCheckbox Lua table
    -- Wraps:   ModOptionsCheckbox Lua table
    element = Wrap.unwrap(element)
    return make_proxy(element, metatable_modoptionsslider)
end



-- ========== Instance Methods ==========

--@section Instance Methods

methods_modoptionsslider = {

    --@instance
    --@param        ...         | function(s)   | A variable amount of functions to call. <br>Alternatively, a table may be provided.
    --[[
    Add a function(s) that is called by the game to
    load the default value when opening the options menu.
    The function **should return a number between the min_value and max_value, as well as respecting the value_int boolean**
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
    Add a function(s) to call when the slider value is changed.
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

local wrapper_name = "ModOptionsSlider"

make_table_once("metatable_modoptionsslider", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return log.error("Cannot access "..wrapper_name.." internal table", 2) end
        if k == "RAPI" then return wrapper_name end

        -- Get certain values
        if k == "namespace" then return __proxy[proxy].namespace end
        if k == "identifier" then return __proxy[proxy].identifier end

        -- Methods
        if methods_modoptionsslider[k] then
            return methods_modoptionsslider[k]
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