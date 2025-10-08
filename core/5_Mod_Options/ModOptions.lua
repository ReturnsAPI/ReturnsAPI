-- ModOptions

ModOptions = new_class()

run_once(function()
    __mod_options_headers = {}
end)



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`RAPI`          | string    | *Read-only.* The wrapper name.
`namespace`     | string    | *Read-only.* The namespace of the ModOptions.
]]



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
Returns the ModOptions belonging to the specified namespace if it exists.
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

    --@instance
    --@return       ModOptionsButton
    --@param        identifier  | string    | The identifier for the element.
    --[[
    Adds a @link {button | ModOptionsButton} to the ModOptions.
    ]]
    add_button = function(self, identifier)
        if not identifier           then log.error("add_button: No identifier provided", 2) end
        if identifier == "header"
        or identifier == "ordered"  then log.error("add_button: identifier '"..identifier.."' is reserved", 2) end
        if self:find(identifier)    then log.error("add_button: identifier '"..identifier.."' already in use", 2) end

        local self_table = __proxy[self]

        local element = ModOptionsButton.new(__proxy[self].namespace, identifier)
        
        self_table.elements[identifier] = element
        table.insert(self_table.elements.ordered, element)

        return element
    end,


    --@instance
    --@return       ModOptionsCheckbox
    --@param        identifier  | string    | The identifier for the element.
    --[[
    Adds a @link {checkbox | ModOptionsCheckbox} to the ModOptions.
    ]]
    add_checkbox = function(self, identifier)
        if not identifier           then log.error("add_checkbox: No identifier provided", 2) end
        if identifier == "header"
        or identifier == "ordered"  then log.error("add_checkbox: identifier '"..identifier.."' is reserved", 2) end
        if self:find(identifier)    then log.error("add_checkbox: identifier '"..identifier.."' already in use", 2) end

        local self_table = __proxy[self]

        local element = ModOptionsCheckbox.new(__proxy[self].namespace, identifier)
        
        self_table.elements[identifier] = element
        table.insert(self_table.elements.ordered, element)

        return element
    end,


    --@instance
    --@return       ModOptionsDropdown
    --@param        identifier  | string    | The identifier for the element.
    --[[
    Adds a @link {dropdown | ModOptionsDropdown} to the ModOptions.
    ]]
    add_dropdown = function(self, identifier)
        if not identifier           then log.error("add_dropdown: No identifier provided", 2) end
        if identifier == "header"
        or identifier == "ordered"  then log.error("add_dropdown: identifier '"..identifier.."' is reserved", 2) end
        if self:find(identifier)    then log.error("add_dropdown: identifier '"..identifier.."' already in use", 2) end

        local self_table = __proxy[self]

        local element = ModOptionsDropdown.new(__proxy[self].namespace, identifier)
        
        self_table.elements[identifier] = element
        table.insert(self_table.elements.ordered, element)

        return element
    end,


    --@instance
    --@return       ModOptions<Element> or nil
    --@param        identifier  | string    | 
    --[[
    Returns the element with the specified identifier if it exists.
    ]]
    find = function(self, identifier)
        return __proxy[self].elements[identifier]
    end,

    
    --@instance
    --@return       table
    --[[
    Returns a table of all elements belonging
    to the ModOptions in display order.
    ]]
    find_all = function(self)
        local t = {}
        for i, v in ipairs(__proxy[self].elements.ordered) do
            t[i] = v
        end
        return t
    end,


    --@instance
    --@return       ModOptions<Element> or nil
    --@param        identifier  | string    | 
    --[[
    Removes and returns the element with the specified
    identifier from the ModOptions if it exists.
    ]]
    remove = function(self, identifier)
        local self_table = __proxy[self]

        local element = self_table.elements[identifier]
        self_table.elements[identifier] = nil
        Util.table_remove_value(self_table.elements.ordered, element)
        return element
    end,


    --@instance
    --[[
    Removes all elements from the ModOptions.
    ]]
    remove_all = function(self, identifier)
        __proxy[self].elements = { ordered = {} }
    end

}



-- ========== Metatables ==========

local wrapper_name = "ModOptions"

make_table_once("metatable_modoptions", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return log.error("Cannot access "..wrapper_name.." internal table", 2) end
        if k == "RAPI" then return wrapper_name end

        -- Get certain values
        if k == "namespace" then return __proxy[proxy].namespace end

        -- Methods
        if methods_modoptions[k] then
            return methods_modoptions[k]
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



-- ========== Hooks ==========

gm.post_code_execute("gml_Object_oOptionsMenu_Other_11", function(self, other)
    -- Get "MODS" tab added by RoM
    local tab = gm.array_get(other.menu_pages, 2).options

    -- Sort headers alphabetically
    local ordered = {}
    for namespace, data_table in pairs(__mod_options_headers) do
        if namespace ~= RAPI_NAMESPACE then
            table.insert(ordered, data_table)
        end
    end
    table.sort(ordered, function(a, b)
        return gm.translate(a.namespace..".header") < gm.translate(b.namespace..".header")
    end)

    -- Insert ReturnsAPI header at the front
    table.insert(ordered, 1, __mod_options_headers[RAPI_NAMESPACE])

    -- Loop through sorted headers and add elements
    for _, data_table in ipairs(ordered) do
        -- Header
        local header = Struct.new(gm.constants.UIOptionsGroupHeader, data_table.namespace..".header").value
        gm.array_push(tab, header)

        -- Elements
        for _, element in ipairs(data_table.elements.ordered) do
            gm.array_push(tab, __proxy[element].constructor())
        end
    end
end)



-- Public export
__class.ModOptions = ModOptions