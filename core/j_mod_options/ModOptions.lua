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
---@class ModOptionsClass
ModOptions = new_class()
C.ModOptions = ModOptions

run_on_initial_load(function()
    P.mod_options_headers = {}  ---@type table<namespace, ModOptionsTable>
end)

local mod_options_headers = P.mod_options_headers

local proxy = P.proxy
local metatable

local type   = type
local table  = table
local string = string
local gm     = gm
local Struct = Struct

local sUIModOptionsButtonHeader  ---@type number Sprite ID


-- ========== Internal ==========

---@param modoptions table
---@return ModOptions
ModOptions.internal.wrap = function(modoptions)
    return new_proxy(modoptions, metatable)
end

ModOptions.internal.initialize = function()
    local filepath = path.combine(PATH, "data", "sprites", "ui", "sUIModOptionsButtonHeader.png")
    sUIModOptionsButtonHeader = Sprite.new(RAPI_NAMESPACE, "sUIModOptionsButtonHeader", filepath, 2)
end
run_on_initialize(ModOptions.internal.initialize)

ModOptions.internal.validate_identifier = function(self, identifier, fn_name)
    if not identifier then
        throw("No identifier provided", fn_name)
    end
    if identifier == "header" or identifier == "ordered"
    or identifier:sub(-7) == ".header" then
        throw("identifier '"..identifier.."' is reserved", fn_name)
    end
    if self:find(identifier) then
        throw("identifier '"..identifier.."' already in use", fn_name)
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
        local struct = proxy[element].constructor()

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
        local o = mod_options_headers[ns].elements.ordered
        local k = 1
        local _, count = string.gsub(header_name, "%.", "")
        if count > 1 then
            repeat k = k + 1
            until k >= #o or (proxy[o[k]].constructor().name):sub(1, #prefix) == prefix
        end
        local j = k
        repeat j = j + 1
        until j > #o or (proxy[o[j]].constructor().name):sub(1, #prefix) ~= prefix

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

run_on_initial_load(function()
    P.textfields = {}
end)


-- ========== Static Methods ==========

---@class ModOptionsTable
---@field namespace string The namespace of this ModOptionsTable.
---@field elements ModOptionsTableElements Stores elements added to this ModOptions.

---@class ModOptionsTableElements
---@field ordered table<number, ModOptionsElement> Stores elements in iteration order.
---@field [string] ModOptionsElement

---@alias ModOptionsElement
---| ModOptionsButton
---| ModOptionsCheckbox
---| ModOptionsDropdown
---| ModOptionsSlider
---| ModOptionsKeybind
---| ModOptionsTextField

--[[
Creates a new ModOptions for your mod if it does not already exist, <br>
or returns the existing one if it does.
]]
---@return ModOptions
ModOptions.new = function(NAMESPACE)
    -- Create new ModOptions if it does not exist
    if not mod_options_headers[NAMESPACE] then    
        mod_options_headers[NAMESPACE] = {
            namespace = NAMESPACE,
            elements  = { ordered = {} }
        }
    end

    return ModOptions.internal.wrap(mod_options_headers[NAMESPACE])
end

--[[
Returns the ModOptions belonging to the specified namespace if it exists.
]]
---@param namespace string The namespace to search for.
---@return ModOptions | nil
ModOptions.find = function(namespace, namespace_is_specified)
    if not namespace then log.error("ModOptions.find: namespace not provided", 2) end

    if mod_options_headers[namespace] then
        return ModOptions.internal.wrap(mod_options_headers[namespace])
    end
end

--[[
Removes the ModOptions for your mod.

Automatically called when you hotload your mod.
]]
ModOptions.remove = function(NAMESPACE)
    mod_options_headers[NAMESPACE] = nil
end
run_on_import(ModOptions.remove)


-- ========== Wrapper Methods ==========

---@class ModOptions
local methods = {}

--[[
Adds a @link {button | ModOptionsButton} to the ModOptions.
]]
---@param identifier string The identifier for the element.
---@return ModOptionsButton
methods.add_button = function(self, identifier)
    ModOptions.internal.validate_identifier(self, identifier, "add_button")

    ---@type ModOptionsTable
    local self_table = proxy[self]

    local element = ModOptionsButton.new(self_table.namespace, identifier)
    
    self_table.elements[identifier] = element
    
    local insert_index = ModOptions.internal.get_insert_index(self_table.elements.ordered, identifier)
    table.insert(self_table.elements.ordered, insert_index, element)

    return element
end

--[[
Adds a @link {checkbox | ModOptionsCheckbox} to the ModOptions.
]]
---@param identifier string The identifier for the element.
---@return ModOptionsCheckbox
methods.add_checkbox = function(self, identifier)
    ModOptions.internal.validate_identifier(self, identifier, "add_checkbox")

    ---@type ModOptionsTable
    local self_table = proxy[self]

    local element = ModOptionsCheckbox.new(self_table.namespace, identifier)
    
    self_table.elements[identifier] = element
    
    local insert_index = ModOptions.internal.get_insert_index(self_table.elements.ordered, identifier)
    table.insert(self_table.elements.ordered, insert_index, element)

    return element
end

--[[
Adds a @link {dropdown | ModOptionsDropdown} to the ModOptions.
]]
---@param identifier string The identifier for the element.
---@return ModOptionsDropdown
methods.add_dropdown = function(self, identifier)
    ModOptions.internal.validate_identifier(self, identifier, "add_dropdown")

    ---@type ModOptionsTable
    local self_table = proxy[self]

    local element = ModOptionsDropdown.new(self_table.namespace, identifier)
    
    self_table.elements[identifier] = element
    
    local insert_index = ModOptions.internal.get_insert_index(self_table.elements.ordered, identifier)
    table.insert(self_table.elements.ordered, insert_index, element)

    return element
end

--[[
Adds a @link {slider | ModOptionsSlider} to the ModOptions.
]]
---@param identifier string The identifier for the element.
---@param display_type? number The display_type of the slider. <br>`ModOptionsSlider.DisplayType.PERCENTAGE` by default.
---@param value_min? number The minimum value of the slider. <br>`0` by default.
---@param value_max? number The maximum value of the slider. <br>`1` by default.
---@param value_int? boolean Whether the value is limited to integers. <br>`false` by default.
---@return ModOptionsSlider
methods.add_slider = function(self, identifier, display_type, value_min, value_max, value_int)
    ModOptions.internal.validate_identifier(self, identifier, "add_slider")

    ---@type ModOptionsTable
    local self_table = proxy[self]

    local element = ModOptionsSlider.new(self_table.namespace, identifier, display_type, value_min, value_max, value_int or false)
    
    self_table.elements[identifier] = element
    
    local insert_index = ModOptions.internal.get_insert_index(self_table.elements.ordered, identifier)
    table.insert(self_table.elements.ordered, insert_index, element)

    return element
end

--[[
Adds a @link {keybind | ModOptionsKeybind} to the ModOptions.
]]
---@param identifier string The identifier for the element.
---@param default number The [keycode](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Game_Input/Keyboard_Input/Keyboard_Input.htm) of the default bind.
---@param default_gamepad? number The [input code](https://manual.gamemaker.io/beta/en/GameMaker_Language/GML_Reference/Game_Input/GamePad_Input/Gamepad_Input.htm) of the default bind. <br>If not provided, will be unbinded by default.
---@return ModOptionsKeybind
methods.add_keybind = function(self, identifier, default, default_gamepad)
    ModOptions.internal.validate_identifier(self, identifier, "add_keybind")

    local _type = type(default)
    if _type ~= "number" then throw("default is invalid") end
    _type = type(default_gamepad)
    if _type ~= "nil" and _type ~= "number" then throw("default_gamepad is invalid") end

    ---@type ModOptionsTable
    local self_table = proxy[self]

    local element = ModOptionsKeybind.new(self_table.namespace, identifier, default, default_gamepad)
    
    self_table.elements[identifier] = element
    
    local insert_index = ModOptions.internal.get_insert_index(self_table.elements.ordered, identifier)
    table.insert(self_table.elements.ordered, insert_index, element)

    return element
end

--[[
Adds a @link {textfield | ModOptionsTextField} to the ModOptions.
]]
---@param identifier string The identifier for the element.
---@param max_length? number The maximum number of characters allowed in the text field. <br>`250` by default.
---@param numeric_only? boolean *Disabled* Whether the text field only accepts numeric input. <br>`false` by default.
---@return ModOptionsTextField
methods.add_textfield = function(self, identifier, max_length, numeric_only)
    ModOptions.internal.validate_identifier(self, identifier, "add_textfield")

    ---@type ModOptionsTable
    local self_table = proxy[self]

    local element, textfield = ModOptionsTextField.new(self_table.namespace, identifier, max_length, numeric_only)
    
    self_table.elements[identifier] = element
    
    local insert_index = ModOptions.internal.get_insert_index(self_table.elements.ordered, identifier)
    table.insert(self_table.elements.ordered, insert_index, element)
    P.textfields[self_table.namespace.."."..identifier] =  textfield

    return element
end

--[[
Returns the element with the specified identifier if it exists.
]]
---@param identifier string The identifier to search for.
---@return ModOptionsElement | nil
methods.find = function(self, identifier)
    ---@type ModOptionsTable
    local self_table = proxy[self]
    return self_table.elements[identifier]
end

--[[
Returns a table of all elements belonging <br>
to the ModOptions in display order.
]]
---@return table<number, ModOptionsElement>
methods.find_all = function(self)
    ---@type ModOptionsTable
    local self_table = proxy[self]

    local t = {}
    for i, v in ipairs(self_table.elements.ordered) do
        t[i] = v
    end
    return t
end

--[[
Removes and returns the element with the specified <br>
identifier from the ModOptions if it exists.
]]
---@param identifier string The identifier to remove.
---@return ModOptionsElement | nil
methods.remove = function(self, identifier)
    ---@type ModOptionsTable
    local self_table = proxy[self]

    local element = self_table.elements[identifier]
    self_table.elements[identifier] = nil
    table.remove_value(self_table.elements.ordered, element)
    return element
end

--[[
Removes all elements from the ModOptions.
]]
methods.remove_all = function(self)
    proxy[self].elements = { ordered = {} }
end


-- ========== Metatables ==========

---@class ModOptions
---@field value ModOptionsTable The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field namespace string The namespace of the ModOptions.

local mt_name = "ModOptions"

W.ModOptions = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return log.error("Cannot access "..mt_name.." internal table", 2) end
        if k == "RAPI" then return mt_name end

        -- Get certain values
        if k == "namespace" then return proxy[t].namespace end

        -- Methods
        local method = methods[k]
        if method then return method end

        log.error(mt_name.." has no method '"..k.."'", 2)
    end,

    __newindex = function(t, k, v)
        log.error(mt_name.." has no properties to set", 2)
    end,

    __tostring = function(t)
        return mt_name..": "..get_table_pointer(t)
    end,

    __metatable = mt_wrapper_name(mt_name),
}
metatable = W.ModOptions


-- ========== Hooks ==========

gm.post_code_execute("gml_Object_oOptionsMenu_Other_11", function(self, other)
    -- Get "MODS" tab added by RoM
    local tab = gm.array_get(other.menu_pages, 2).options

    -- Sort headers alphabetically
    local ordered = {}
    for namespace, data_table in pairs(mod_options_headers) do
        if namespace ~= RAPI_NAMESPACE then
            table.insert(ordered, data_table)
        end
    end
    table.sort(ordered, function(a, b)
        return gm.translate(a.namespace..".header") < gm.translate(b.namespace..".header")
    end)
    
    -- Insert ReturnsAPI header at the front if it exists
    local index = 1
    local rapi_header = mod_options_headers[RAPI_NAMESPACE]
    if rapi_header then
        table.insert(ordered, 1, rapi_header)
        index = 2
    end

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
        local field = P.textfields[opt.name]
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