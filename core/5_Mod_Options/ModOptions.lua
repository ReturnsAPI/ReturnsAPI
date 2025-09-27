-- ModOptions

ModOptions = new_class()

run_once(function()
    __mod_options_headers = {}
end)



-- ========== Constants ==========

-- --@section Constants

-- --[[
-- These constants are used internally
-- and have no general uses.
-- ]]

-- --@constants
-- --[[
-- BUTTON  0
-- ]]

-- local element_constants = {
--     BUTTON  = 0
-- }

-- -- Add to ModOptions directly (e.g., ModOptions.BUTTON)
-- for k, v in pairs(element_constants) do
--     ModOptions[k] = v
-- end



-- ========== Internal ==========

ModOptions.internal.wrap = function(modoptions)
    -- Input:   ModOptions Lua table
    -- Wraps:   ModOptions Lua table
    return make_proxy(modoptions, metatable_modoptions)
end



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       ModOptions
--[[
Creates a new ModOptions for your mod if it does not already exist,
or returns the existing one if it does.
]]
ModOptions.new = function(NAMESPACE)
    print(NAMESPACE..".header")

    -- Create new ModOptions if existn't
    if not __mod_options_headers[NAMESPACE] then
        __mod_options_headers[NAMESPACE] = {
            namespace   = NAMESPACE,
            elements    = { ordered = {} }
        }
    end

    return ModOptions.internal.wrap(__mod_options_headers[NAMESPACE])
end


--@static
--@return       ModOptions or nil
--@param        namespace   | string    | 
--[[
Returns the ModOptions belonging the
specified namespace if it exists.
]]
ModOptions.find = function(namespace, namespace_is_specified)
    if not namespace then log.error("ModOptions.find: namespace not provided", 2) end

    if __mod_options_headers[namespace] then
        return ModOptions.internal.wrap(__mod_options_headers[namespace])
    end
end


--@static
--[[
Removes the ModOptions for your mod.

Automatically called when you hotload your mod.
]]
ModOptions.remove = function(NAMESPACE)
    __mod_options_headers[NAMESPACE] = nil
end
table.insert(_clear_namespace_functions, ModOptions.remove)



-- ========== Instance Methods ==========

--@section Instance Methods

methods_modoptions = {

    find_element = function(self, identifier)
        return self.elements[identifier]
    end,
    

    --@instance
    --@param        identifier  | string    | The identifier for the element.
    --@optional     ...         | function  | A variable amount of functions to call when the button is pressed.
    --[[
    Adds a button to the ModOptions.
    ]]
    add_button = function(self, identifier, ...)
        if not identifier                   then log.error("add_element: No identifier provided", 2) end
        if self:find_element(identifier)    then log.error("add_element: identifier '"..identifier.."' already in use", 2) end

        local callbacks = {}

        local fns = {...}
        for _, fn in ipairs(fns) do
            if type(fn) == "function" then
                table.insert(callbacks, fn)
            end
        end

        local constructor = function()
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

        local element_data_table = {
            identifier      = identifier,
            constructor     = constructor,
            callbacks       = callbacks
        }

        self.elements[identifier] = element_data_table
        table.insert(self.elements.ordered, element_data_table)
    end

}



-- ========== Metatables ==========

local wrapper_name = "ModOptions"

make_table_once("metatable_modoptions", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return log.error("Cannot access ModOptions internal table", 2) end
        if k == "RAPI" then return wrapper_name end

        -- Methods
        if methods_modoptions[k] then
            return methods_modoptions[k]
        end

        -- Getter
        return __proxy[proxy][k]
    end,


    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        log.error("ModOptions has no properties to set", 2)
    end,


    __metatable = "RAPI.Wrapper."..wrapper_name
})



-- ========== Hooks ==========

gm.post_code_execute("gml_Object_oOptionsMenu_Other_11", function(self, other)
    -- Get "MODS" tab added by RoM
    local tab = gm.array_get(other.menu_pages, 2).options

    -- TODO sort headers alphabetically first

    -- Loop through stored headers and add elements
    for namespace, data_table in pairs(__mod_options_headers) do
        -- Header
        local header = Struct.new(gm.constants.UIOptionsGroupHeader, "header").value
        gm.array_push(tab, header)

        -- Elements
        for _, element in ipairs(data_table.elements.ordered) do
            gm.array_push(tab, element.constructor())
        end
    end
end)



-- Public export
__class.ModOptions = ModOptions