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
`RAPI`          | string    | *Read-only.* The wrapper name.
`namespace`     | string    | *Read-only.* The namespace of the ModOptions the element is in.
`identifier`    | string    | *Read-only.* The identifier of the element.
]]

-- ========== Internal ==========

local function get_option_y_offset(target_id, options)
    local y = 0

    for i = 1, #options do
        local opt = options[i]

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


-- ========== Hooks ==========

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

    for _, field in ipairs(field_containers) do
        local option_y, field_index = get_option_y_offset(field.name, self.menu_pages[3].options)
        if option_y == nil then return end
        option_y = option_y + opt_y

        gm.ui_draw_clip_set(opt_x_start + 2, opt_y_start + 8, opt_width - 8, opt_height_total - 16);
        -- ui_text_field(name,       x,   y,         width, flags, ui_style,                                    max_characters,  gamepad_navigation_id, numeric-only)
        gm.ui_text_field(field.name, 400, option_y , 200,   0,     gm.variable_global_get("_ui_style_default"), field.max_length, index,                false)
        gm.ui_draw_clip_reset()

        local state = gm._ui_get_element_state(field.name)
        if self.hover_last_index == field_index then state.text_field_typing = true
        else state.text_field_typing = false end

        local value = gm.variable_struct_get(gm.variable_global_get("_ui_shared_state").named_element_value,field.name)
        if field.last_value ~= value then
            field.last_value = value
            field.set(value)
        end
    end
end)