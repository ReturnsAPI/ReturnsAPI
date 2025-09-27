-- ModOptionsButton

-- The class table is private, but the wrappers are publicly accessible

ModOptionsButton = new_class()



-- ========== Static Methods ==========

ModOptionsButton.new = function(identifier)
    local callbacks = {}
    
    local element_data_table = {
        identifier      = identifier,
        callbacks       = callbacks,
        constructor     = function()
            return Struct.new(
                gm.constants.UIOptionsButton2,
                identifier,

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


ModOptionsButton.wrap = function(element)
    -- Input:   ModOptionsButton Lua table
    -- Wraps:   ModOptionsButton Lua table
    return make_proxy(element, metatable_modoptionsbutton)
end



-- ========== Instance Methods ==========

--@section Instance Methods

methods_modoptionsbutton = {

    --@instance
    --@param        ...         | function(s)   | A variable amount of functions to call. <br>Alternatively, a table may be provided.
    --[[
    Add a function(s) to call when the button is pressed.
    ]]
    add_callback = function(self, ...)
        local fns = {...}
        if type(fns[1]) == "table" then fns = fns[1] end

        for _, fn in ipairs(fns) do
            if type(fn) == "function" then
                table.insert(__proxy[self].callbacks, fn)
            end
        end
    end

}



-- ========== Metatables ==========

local wrapper_name = "ModOptionsButton"

make_table_once("metatable_modoptionsbutton", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return log.error("Cannot access "..wrapper_name.." internal table", 2) end
        if k == "RAPI" then return wrapper_name end

        -- Methods
        if methods_modoptionsbutton[k] then
            return methods_modoptionsbutton[k]
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