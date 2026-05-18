-- ModOptions


--[[
Each ModOptions has it's own header, but you can create subheaders by naming your field `mysubheader.option`.
This will automatically create a `mysubheader.header` element and put the option under it.
Using more dots lets you create subsubheaders.

Here is an example of what this looks like in the language file

```lua
test = {
header = "TEST",
mysubheader = {
    header = "SUBHEADER",
    ["header.desc"] = "sub description",
    mysubsubheader = {
        header = "SUBSUBHEADER",
        ["header.desc"] = "sub sub description"
    }
}
```

]]

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


ModOptions.internal.initialize = function()
    local filepath = path.combine(PATH, "core/sprites/ui/sUIModOptionsButtonHeader.png")
    sUIModOptionsButtonHeader = Sprite.new(RAPI_NAMESPACE, "sUIModOptionsButtonHeader", filepath, 2)
end
table.insert(_rapi_initialize, ModOptions.internal.initialize)

ModOptions.internal.validate_identifier = function(self, identifier, fn_name)
    if not identifier then
        log.error(fn_name..": No identifier provided", 2)
    end
    if identifier == "header" or identifier == "ordered"
    or identifier:sub(-7) == ".header" then
        log.error(fn_name..": identifier '"..identifier.."' is reserved", 2)
    end
    if self:find(identifier) then
        log.error(fn_name..": identifier '"..identifier.."' already in use", 2)
    end
end

ModOptions.internal.get_insert_index = function(ordered, identifier)
    local parent = identifier:match("^(.*)%.[^%.]+$")
    local insert_index = #ordered + 1
    if not parent then
        return insert_index
    end
    for i = #ordered, 1, -1 do
        local id = ordered[i].identifier

        if id == parent
        or id:sub(1, #parent + 1) == parent .. "." then
            insert_index = i + 1
            break
        end
    end
    return insert_index
end

ModOptions.internal.header_insert_options = function(tab, options, arr_i, first, last, header_name)
    -- ModOptionsKeybind styling
    local first_key
    local is_odd = false

    local subheaders = {}
    
    if header_name then
        local before = string.match(header_name, "^(.*)%.")
        subheaders[before] = true
    end

    first = first or 1
    last = last or #options

    local slice = {}
    for i = first, last do
        table.insert(slice, options[i])
    end

    for _, element in ipairs(slice) do
        local struct = __proxy[element].constructor()

        -- add subheaders
        local _, depth = string.gsub(struct.name, "%.", "")
        if depth > 1 then
            local before = string.match(struct.name, "^(.*)%.")
            if not subheaders[before] then
                local subheader = Struct.new(gm.constants.UIOptionsGroupHeader, before..".header")
                subheader.title = string.rep("   ", depth -1)..subheader.title
                gm.array_insert(tab, arr_i, subheader.value)
                arr_i = arr_i + 1
                subheaders[before] = true
            end
        end
        
        if element.RAPI == "ModOptionsKeybind" then
            if not first_key then first_key = struct end
            first_key.background_height = first_key.background_height + 38
            
            struct.is_odd = is_odd
            is_odd = not is_odd
        elseif element.RAPI == "ModOptionsTextField" then 
            -- Sync the ui_text_field value with the ModOptionsTextField
            gm.variable_struct_set(
                gm.variable_global_get("_ui_shared_state").named_element_value,
                struct.name,
                struct.value
            )
        else
            first_key = nil
            is_odd = false
        end
        gm.array_insert(tab, arr_i, struct)
        arr_i = arr_i + 1
        if tab[arr_i].refresh then tab[arr_i]:refresh(nil, nil) end
    end
    return arr_i
end

ModOptions.internal.toggle_header_options = function(options, i, header_name)
    if header_name == "mods_rom_group_header" then return end

    local prefix = string.match(header_name,"^(.-)%.header$")

    if i == #options or (options[i+1].name):sub(1, #prefix) ~= prefix then 
        -- unfold
        local ns = header_name:match("^[^.]+")
        local o = __mod_options_headers[ns].elements.ordered
        local k = 1
        local _, count = string.gsub(header_name, "%.", "")
        if count > 1 then
            repeat k = k + 1
            until k >= #o or (__proxy[o[k]].constructor().name):sub(1, #prefix) == prefix
        end
        local j = k
        repeat j = j + 1
        until j > #o or (__proxy[o[j]].constructor().name):sub(1, #prefix) ~= prefix

        Alarm.add("options_restore", 1, function()
            ModOptions.internal.header_insert_options(options, o, i, k, j-1, header_name)
        end)
    else 
        -- fold
        local j = 1
        repeat j = j + 1
        until i+j > #options or (options[i+ j].name):sub(1, #prefix) ~= prefix

        Alarm.add("options_delete", 1, function()
            gm.array_delete(options, i, j - 1)
        end)
    end 
end

run_once(function()
    __textfields = {}
end)

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
        ModOptions.internal.validate_identifier(self, identifier, "add_button")

        local self_table = __proxy[self]

        local element = ModOptionsButton.new(__proxy[self].namespace, identifier)
        
        self_table.elements[identifier] = element
        
        local insert_index = ModOptions.internal.get_insert_index(self_table.elements.ordered, identifier)
        table.insert(self_table.elements.ordered, insert_index, element)

        return element
    end,


    --@instance
    --@return       ModOptionsCheckbox
    --@param        identifier  | string    | The identifier for the element.
    --[[
    Adds a @link {checkbox | ModOptionsCheckbox} to the ModOptions.
    ]]
    add_checkbox = function(self, identifier)
        ModOptions.internal.validate_identifier(self, identifier, "add_checkbox")

        local self_table = __proxy[self]

        local element = ModOptionsCheckbox.new(__proxy[self].namespace, identifier)
        
        self_table.elements[identifier] = element
        
        local insert_index = ModOptions.internal.get_insert_index(self_table.elements.ordered, identifier)
        table.insert(self_table.elements.ordered, insert_index, element)

        return element
    end,


    --@instance
    --@return       ModOptionsDropdown
    --@param        identifier  | string    | The identifier for the element.
    --[[
    Adds a @link {dropdown | ModOptionsDropdown} to the ModOptions.
    ]]
    add_dropdown = function(self, identifier)
        ModOptions.internal.validate_identifier(self, identifier, "add_dropdown")

        local self_table = __proxy[self]

        local element = ModOptionsDropdown.new(__proxy[self].namespace, identifier)
        
        self_table.elements[identifier] = element
        
        local insert_index = ModOptions.internal.get_insert_index(self_table.elements.ordered, identifier)
        table.insert(self_table.elements.ordered, insert_index, element)

        return element
    end,


    --@instance
    --@return       ModOptionsSlider
    --@param        identifier  | string    | The identifier for the element.
    --@optional     display_type| number    | The display_type of the slider (percentage by default).
    --@optional     value_min   | number    | The minimum value of the slider (0 by default).
    --@optional     value_max   | number    | The maximum value of the slider (1 by default).
    --@optional     value_int   | bool      | Whether the value is limited to integers (false by default).
    --[[
    Adds a @link {slider | ModOptionsSlider} to the ModOptions.
    ]]
    add_slider = function(self, identifier, display_type, value_min, value_max, value_int)
        ModOptions.internal.validate_identifier(self, identifier, "add_slider")

        local self_table = __proxy[self]

        local element = ModOptionsSlider.new(__proxy[self].namespace, identifier, display_type, value_min, value_max, value_int or false)
        
        self_table.elements[identifier] = element
        
        local insert_index = ModOptions.internal.get_insert_index(self_table.elements.ordered, identifier)
        table.insert(self_table.elements.ordered, insert_index, element)

        return element
    end,


    --@instance
    --@return       ModOptionsKeybind
    --@param        identifier      | string    | The identifier for the element.
    --@param        default         | number    | The [keycode](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Game_Input/Keyboard_Input/Keyboard_Input.htm) of the default bind. <br>If not provided, will be unbinded by default.
    --@optional     default_gamepad | number    | The [input code](https://manual.gamemaker.io/beta/en/GameMaker_Language/GML_Reference/Game_Input/GamePad_Input/Gamepad_Input.htm) of the default bind. <br>If not provided, will be unbinded by default.
    --[[
    Adds a @link {keybind | ModOptionsKeybind} to the ModOptions.
    ]]
    add_keybind = function(self, identifier, default, default_gamepad)
        ModOptions.internal.validate_identifier(self, identifier, "add_keybind")

        local _type = type(default)
        if _type ~= "number" then log.error("add_keybind: default is invalid", 2) end
        _type = type(default_gamepad)
        if _type ~= "nil" and _type ~= "number" then log.error("add_keybind: default_gamepad is invalid", 2) end

        local self_table = __proxy[self]

        local element = ModOptionsKeybind.new(__proxy[self].namespace, identifier, default, default_gamepad)
        
        self_table.elements[identifier] = element
        
        local insert_index = ModOptions.internal.get_insert_index(self_table.elements.ordered, identifier)
        table.insert(self_table.elements.ordered, insert_index, element)

        return element
    end,


    --@instance
    --@return       ModOptionsTextField
    --@param        identifier   | string | The identifier for the element.
    --@optional     max_length   | number | The maximum number of characters allowed in the text field (250 by default).
    --@optional     numeric_only | bool   | *Disabled* Whether the text field only accepts numeric input (false by default).
    --[[
    Adds a @link {textfield | ModOptionsTextField} to the ModOptions.
    ]]
    add_textfield = function(self, identifier, max_length, numeric_only)
        ModOptions.internal.validate_identifier(self, identifier, "add_textfield")

        local self_table = __proxy[self]

        local element, textfield = ModOptionsTextField.new(__proxy[self].namespace, identifier, max_length, numeric_only)
        
        self_table.elements[identifier] = element
        
        local insert_index = ModOptions.internal.get_insert_index(self_table.elements.ordered, identifier)
        table.insert(self_table.elements.ordered, insert_index, element)
        __textfields[__proxy[self].namespace.."."..identifier] =  textfield

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
    local index = 2

    -- Loop through sorted headers and add elements
    for _, data_table in ipairs(ordered) do
        -- Header
        local header = Struct.new(gm.constants.UIOptionsGroupHeader, data_table.namespace..".header").value
        gm.array_push(tab, header)
        index = index + 1

        index = ModOptions.internal.header_insert_options(tab, data_table.elements.ordered, index)
    end
end)

-- hook used to draw on top of the ui

gm.post_script_hook(gm.constants.ui_options_draw_tooltip, function(self, other, result, args)
    if self.menu_level ~= 2 then return end
    
    local scroll = gm.ui_get_element_value("options_scroll")
    local style = gm.variable_global_get("_ui_style_default")
    local shared_state = gm.variable_global_get("_ui_shared_state")

    local header_height = 114
    local middle_sep = 12
    local opt_margin = 10

    local opt_x_start = gm.ui_margin_left()
    local opt_y_start = gm.ui_margin_top() + header_height

    local opt_height_total = gm.ui_content_height() - header_height - 24
    local opt_width = (gm.ui_content_width() // 2) - middle_sep

    local opt_x = opt_x_start + opt_margin
    local opt_y = opt_y_start + opt_margin - scroll
    local opt_width_margin = opt_width - (opt_margin * 2)

    local y = 0
    local ii = 0
    local options = self.menu_pages[3].options

    gm.ui_draw_clip_set(opt_x_start + 2, opt_y_start + 8, opt_width_margin + 2, opt_height_total - 16)
    for i = 1, #options do
        local option_y = y + opt_y
        local opt = options[i]
        local t = gm.struct_get(opt, "type")
        
        -- draw header button
        if t == 3 then
            local value = gm.ui_button_sprite(opt_x_start + 60, option_y + 2, sUIModOptionsButtonHeader.value, 0, nil, style)
            
            if value ~= opt.title_trimmed then
                opt.title_trimmed = value
                if value == 1 then -- click release
                    ModOptions.internal.toggle_header_options(options, i, opt.name)
                end
            end
        else
            ii = ii + 1
        end
        -- draw text field
        local field = __textfields[opt.name]
        if field then
            --opt.pressed = false
            local option_y = y + opt_y
            --gm.ui_gp_pos(0, ii-1, nil, nil)
            local tf_state = gm.ui_text_field(opt.name, opt_width_margin-160, option_y, 200, 0, style, field.max_length, nil, false)
            local state = gm._ui_get_element_state(opt.name)

            -- figure out exactly how to make it work for keyboard/gamepad

            -- if tf_state > -2 then
            --     if  __last_scroll ~= opt.name then
            --         gm.ui_set_element_value("options_scroll", option_y + 100)
            --         __last_scroll = opt.name
            --     end
            --     if gm.input_check_pressed("confirm") or __last_textfield == opt.name then
            --         state.text_field_typing = true
            --         __last_textfield = opt.name
            --     elseif gm.keyboard_check_pressed(27) > 0 then --vk_escape
            --         state.text_field_typing = false
            --         __last_textfield = nil
            --     end
            -- elseif __last_scroll == opt.name then
            --     __last_scroll = nil
            -- end
            local value = gm.variable_struct_get(shared_state.named_element_value, opt.name)
            if field.last_value ~= value then
                field.last_value = value
                field.set(value)
            end
        end
        y = y + 48
    end
    gm.ui_draw_clip_reset()
end)



-- Public export
__class.ModOptions = ModOptions