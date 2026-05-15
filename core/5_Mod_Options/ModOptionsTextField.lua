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

-- ========== Internal ==========

local function get_option_y_offset(target_id, options)
    local y = 0

    for i = 1, #options do
        local opt = options[i]

        if opt.type == 3 then
            print("Header found:", opt.title)



        end

        if opt.name == target_id then
            return y, i-1
        end

        local t = opt.type
        if t == 4 or t == 8 then -- control-style row
            y = y + 38
            local next_opt = options[i + 1]
            if next_opt and not ( next_opt.type == 4 or next_opt.type == 8) then
                y = y + 8
            end
        else -- header or normal option
            y = y + 48
        end
    end
    return nil -- not found
end

local field_containers = {}

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
            table.insert(field_containers, {
                name         = namespace.."."..identifier,
                max_length   = max_length or 250,
                numeric_only = numeric_only or false,
                set          = function(value)
                    for _, fn in ipairs(callbacks_set) do
                        fn(value)
                    end
                end,
                last_value = nil
            })

            return struct
        end
    }
    return ModOptionsTextField.wrap(element_data_table)
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


function header_insert_options(tab, options, index)
    -- ModOptionsKeybind styling
    local first_key
    local is_odd = false

    for _, element in ipairs(options) do
        local struct = __proxy[element].constructor()

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
        gm.array_insert(tab, index, struct)
        index = index + 1
        if tab[index].refresh then tab[index]:refresh(nil, nil) end
    end
    return index
end

-- hook used to draw on top of the ui
function toggle_header_options(options, i, to_delete, header_name)
    if header_name == "mods_rom_group_header" then return end
    if to_delete > 0 then
        Alarm.add("options_delete", 1, function() 
            gm.array_delete(options, i - to_delete, to_delete) 
        end)
    else
        local ns = header_name:match("^[^.]+")
        if not ns then return end
        Alarm.add("options_restore", 1, function()
            header_insert_options(options, __mod_options_headers[ns].elements.ordered, i)
        end)
    end
end

gm.post_script_hook(gm.constants.ui_options_draw_tooltip, function(self, other, result, args)
    if self.menu_level ~= 2 then return end

    local scroll = gm.ui_get_element_value("options_scroll")

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

    local fields = {}
    for _, field in ipairs(field_containers) do
        fields[field.name] = field
    end

    local y = 0
    local options = self.menu_pages[3].options

    local deleting = false
    local to_delete = 0
    local header_to_delete = ""

    gm.ui_draw_clip_set(opt_x_start + 2, opt_y_start + 8, opt_width - 8, opt_height_total - 16)
    for i = 1, #options do
        local option_y = y + opt_y
        local opt = options[i]
        local t = gm.struct_get(opt, "type")
        
        if t == 3 then
            -- draw header button here
            if deleting then 
                toggle_header_options(options, i - 1, to_delete, header_to_delete)
                 deleting = false
            end
                
            local value = gm.ui_button_sprite(80, option_y, gm.constants.sUISubheader, 0, 0, gm.variable_global_get("_ui_style_default"))
            
            if value ~= opt.title_trimmed then
                opt.title_trimmed = value
                if value == 1 then -- click release
                    deleting = true
                    header_to_delete = opt.name
                end
            end
        else
            if deleting then to_delete = to_delete + 1 end 
        end

        local field = fields[opt.name]
        if field then
            local option_y = y + opt_y
            gm.ui_text_field(field.name, 400, option_y, 200, 0, gm.variable_global_get("_ui_style_default"), field.max_length, i - 1, false)
            

            local state = gm._ui_get_element_state(field.name)
            state.text_field_typing = (self.hover_last_index == i - 1)

            local value = gm.variable_struct_get(gm.variable_global_get("_ui_shared_state").named_element_value, field.name)
            if field.last_value ~= value then
                field.last_value = value
                field.set(value)
            end
        end
        y = y + 48
    end
    
    gm.ui_draw_clip_reset()
    if deleting then 
        toggle_header_options(options, #options, to_delete, header_to_delete) 
    end
end)