-- ModOptionsTextField

-- The class table is private, but the wrappers are publicly accessible

ModOptionsTextField = new_class()

-- todo gamepad navigation id and numeric mode option

-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`RAPI`          | string | *Read-only.* The wrapper name.
`namespace`     | string | *Read-only.* The namespace of the ModOptions the element is in.
`identifier`    | string | *Read-only.* The identifier of the element.
`max_length`    | number | *Read-only.* The maximum number of characters allowed in the text field (default 250).
`numeric_only`  | bool   | *Disabled* *Read-only.* Whether the text field only accepts numeric input (false by default).
]]

-- ========== Static Methods ==========

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


ModOptionsTextField.wrap = function(element)
    -- Input:   ModOptionsTextField Lua table
    -- Wraps:   ModOptionsTextField Lua table
    element = Wrap.unwrap(element)
    return make_proxy(element, metatable_modoptionsTextField)
end



-- ========== Instance Methods ==========

--@section Instance Methods

methods_modoptionsTextField = {

    --@instance
    --@param        ...         | function(s)   | A variable amount of functions to call. <br>Alternatively, a table may be provided.
    --[[
    Add a function(s) that is called by the game to
    load the default choice when opening the options menu.
    The function **should return a number value between `0` and `number of choices - 1`.**
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
    Add a function(s) to call when a choice is toggled.
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
    end,


    --@instance
    --@param        ...         | string        | A variable amount of localization tokens for each choice. <br>Alternatively, a table may be provided.
    --[[
    Add a choice(s) to the Field.
    ]]
    add_choice = function(self, ...)
        local choices = {...}
        if type(choices[1]) == "table" then choices = choices[1] end

        for _, token in ipairs(choices) do
            if type(token) == "string" then
                table.insert(__proxy[self].choices, token)
            end
        end
    end

}



-- ========== Metatables ==========

local wrapper_name = "ModOptionsTextField"

make_table_once("metatable_modoptionsTextField", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return log.error("Cannot access "..wrapper_name.." internal table", 2) end
        if k == "RAPI" then return wrapper_name end

        -- Get certain values
        if k == "namespace" then return __proxy[proxy].namespace end
        if k == "identifier" then return __proxy[proxy].identifier end

        -- Methods
        if methods_modoptionsTextField[k] then
            return methods_modoptionsTextField[k]
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


-- ========== Hooks =========
