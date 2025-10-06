-- ModOptionsDropdown

-- The class table is private, but the wrappers are publicly accessible

ModOptionsDropdown = new_class()



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


ModOptionsDropdown.wrap = function(element)
    -- Input:   ModOptionsDropdown Lua table
    -- Wraps:   ModOptionsDropdown Lua table
    return make_proxy(element, metatable_modoptionsdropdown)
end



-- ========== Instance Methods ==========

--@section Instance Methods

methods_modoptionsdropdown = {

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
    Add a choice(s) to the dropdown.
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

local wrapper_name = "ModOptionsDropdown"

make_table_once("metatable_modoptionsdropdown", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return log.error("Cannot access "..wrapper_name.." internal table", 2) end
        if k == "RAPI" then return wrapper_name end

        -- Get certain values
        if k == "namespace" then return __proxy[proxy].namespace end
        if k == "identifier" then return __proxy[proxy].identifier end

        -- Methods
        if methods_modoptionsdropdown[k] then
            return methods_modoptionsdropdown[k]
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