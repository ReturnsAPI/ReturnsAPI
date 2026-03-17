-- ModOptionsKeybind

-- The class table is private, but the wrappers are publicly accessible

-- TODO:
-- * Disable no-duplicates check for custom binds

--[[
**Input Checking**
Function | Description
| - | -
`gm.input_check( verb )`            | Returns `true` if the verb input is being held.
`gm.input_check_pressed( verb )`    | Returns `true` if the verb input was just pressed.
`gm.input_check_released( verb )`   | Returns `true` if the verb input was just released.

Player also has a @link {`control` | Player#control} instance method, which is more restrictive.
]]

ModOptionsKeybind = new_class()

if not __custom_verbs_key then
    __custom_verbs_key = {}
    __custom_verbs_mouse_button = {}
    __custom_verbs_gamepad = {}

    -- Load saved custom verbs
    local file = TOML.new(RAPI_NAMESPACE)
    settings = file:read() or {}

    if settings.keybinds then
        for verb, keycode in pairs(settings.keybinds) do
            __custom_verbs_key[verb] = keycode
        end
    end
    if settings.keybinds_mouse_button then
        for verb, keycode in pairs(settings.keybinds_mouse_button) do
            __custom_verbs_mouse_button[verb] = keycode
        end
    end
    if settings.keybinds_gamepad then
        for verb, keycode in pairs(settings.keybinds_gamepad) do
            __custom_verbs_gamepad[verb] = keycode
        end    
    end

    __add_verb_queue = {}
end

vanilla_player_verbs = Util.enum({
    "left", "right", "up", "down", "jump",
    "skill1", "skill2", "skill3", "skill4",
    "equipment", "interact", "swap",
    "aim_left", "aim_right",
    "emote", "ping",
    "emote_1", "emote_2", "emote_3", "emote_4", 
    "tab", "pause"
}, 0)

-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`RAPI`          | string    | *Read-only.* The wrapper name.
`namespace`     | string    | *Read-only.* The namespace of the ModOptions the element is in.
`identifier`    | string    | *Read-only.* The identifier of the element.
`verb`          | string    | *Read-only.* The verb name for the keybind. <br>Equal to `"<namespace>.<identifier>"`.
]]



-- ========== Internal ==========

is_inside_add_verb = false

ModOptionsKeybind.internal.add_verb = function(verb, default, default_gamepad, default_mouse_button)
    if is_inside_add_verb then
        return
    end
    is_inside_add_verb = true

    -- Not sure how much of this is necessary
    -- Works though so don't touch anything

    if Global.__input_profile_dict["keyboard_and_mouse"][verb] then
        print("verb already here, bailing!", verb, Global.__input_profile_dict["keyboard_and_mouse"][verb])
        is_inside_add_verb = false
        return
    end

    print("adding verb", verb, default, default_gamepad, default_mouse_button)

    local bind = nil
    if     __custom_verbs_key[verb]     then bind = gm.input_binding_key(__custom_verbs_key[verb])
    elseif default and default > 0  then bind = gm.input_binding_key(default)
    end
    __custom_verbs_key[verb] = bind.value

    if __custom_verbs_mouse_button[verb] or (default_mouse_button and default_mouse_button > 0) then
        bind = gm.input_binding_mouse_button(__custom_verbs_mouse_button[verb])
        __custom_verbs_mouse_button[verb] = bind.value
    else
        if     __custom_verbs_key[verb]     then bind = gm.input_binding_key(__custom_verbs_key[verb])
        elseif default and default > 0  then bind = gm.input_binding_key(default)
        end
        __custom_verbs_key[verb] = bind.value
    end

    -- Create controller bind
    local bind_gamepad = gm.input_binding_empty()
    if     __custom_verbs_gamepad[verb]             then bind_gamepad = ModOptionsKeybind.internal.input_binding_gamepad(__custom_verbs_gamepad[verb])
    elseif default_gamepad and default_gamepad > 0  then bind_gamepad = ModOptionsKeybind.internal.input_binding_gamepad(default_gamepad)
    end
    __custom_verbs_gamepad[verb] = bind_gamepad.value

    Global.__input_profile_dict["keyboard_and_mouse"][verb] = bind
    Global.__input_profile_dict["gamepad"][verb]            = bind_gamepad
    local verb_data         = Global.__input_profile_dict["keyboard_and_mouse"][verb]
    local verb_data_gamepad = Global.__input_profile_dict["gamepad"][verb]

    -- Global.__input_basic_verb_array:push(verb)   -- Adding these will result in duplicate custom verbs in menus
    -- Global.__input_basic_verb_dict[verb] = true
    can_add = true
    for i = 1, #Global.__input_all_verb_array do
        if Global.__input_all_verb_array[i] == verb then
            can_add = false
            break
        end
    end
    if can_add then
        Global.__input_all_verb_array:push(verb)
    end
    Global.__input_all_verb_dict[verb] = true

    local ticking_verbs = Global.__input_ticking_verbs_array

    can_add = true
    for i = 1, #ticking_verbs do
        if ticking_verbs[i] == verb then
            can_add = false
            break
        end
    end
    if can_add then
        ticking_verbs:push(verb)
    end

    local ticking_verbs_count = #ticking_verbs

    local __input_class_players = {
        Global.__input_default_player,
        Global.__input_players[1],
        Global.__input_players[2],
        Global.__input_players[3],
        Global.__input_players[4],
    }

    for _, struct in ipairs(__input_class_players) do
        struct.__verb_ensure("keyboard_and_mouse", verb)
        struct.__binding_set("keyboard_and_mouse", verb, 0, verb_data)
        struct.__verb_ensure("gamepad", verb)
        struct.__binding_set("gamepad", verb, 0, verb_data_gamepad)

        struct.__verb_state_array = gm.array_create(ticking_verbs_count, 0);
        for j = 1, ticking_verbs_count do
            struct.__verb_state_array[j] = struct.__verb_state_dict[ticking_verbs[j]];
        end
        struct.__profile_choice_updated()
    end

    is_inside_add_verb = false
end


ModOptionsKeybind.internal.input_binding_gamepad = function(input_code)
    -- Button
    local axis_lh = 32785
    if input_code < axis_lh then
        return gm.input_binding_gamepad_button(input_code)

    -- Axis
    else
        return gm.input_binding_gamepad_axis(input_code)

    end
end


table.insert(_rapi_initialize, function()
    print("executing queue!")
    -- Add verbs in queue
    for _, v in ipairs(__add_verb_queue) do
        print("adding verb from queue", v.verb)
        ModOptionsKeybind.internal.add_verb(v.verb, __custom_verbs_key[verb] or v.default, __custom_verbs_gamepad[verb] or v.default_gamepad)
    end
    __add_verb_queue = {}
end)


-- ========== Static Methods ==========

ModOptionsKeybind.new = function(namespace, identifier, default, default_gamepad)
    default = default or -1

    local verb = namespace.."."..identifier

    -- Add verb immediately post-Initialize;
    -- otherwise add to queue
    if Initialize.has_started() then
        ModOptionsKeybind.internal.add_verb(verb, __custom_verbs_key[verb] or default, __custom_verbs_gamepad[verb] or default_gamepad)
    else 
        table.insert(__add_verb_queue, {
            verb = verb,
            default = default,
            default_gamepad = default_gamepad
        })
    end

    local element_data_table = {
        namespace       = namespace,
        identifier      = identifier,
        verb            = verb,
        constructor     = function()
            local control_remap_profile = gm.input_profile_get(0)
            -- ^ actual is `input_player_index = (oPauseMenu.pause_player == -1) ? 0 : oPauseMenu.pause_player`

            local struct = Struct.new(
                gm.constants.UIOptionsButtonControlRemapKey,
                namespace.."."..identifier,
                verb,
                control_remap_profile   -- "keyboard_and_mouse"
            )
            return struct.value
        end
    }

    return ModOptionsKeybind.wrap(element_data_table)
end


ModOptionsKeybind.wrap = function(element)
    -- Input:   ModOptionsKeybind Lua table
    -- Wraps:   ModOptionsKeybind Lua table
    element = Wrap.unwrap(element)
    return make_proxy(element, metatable_modoptionskeybind)
end



-- ========== Instance Methods ==========

--@section Instance Methods

methods_modoptionskeybind = {

    

}



-- ========== Metatables ==========

local wrapper_name = "ModOptionsKeybind"

make_table_once("metatable_modoptionskeybind", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return log.error("Cannot access "..wrapper_name.." internal table", 2) end
        if k == "RAPI" then return wrapper_name end

        -- Get certain values
        if k == "namespace"     then return __proxy[proxy].namespace end
        if k == "identifier"    then return __proxy[proxy].identifier end
        if k == "verb"          then return __proxy[proxy].verb end

        -- Methods
        if methods_modoptionskeybind[k] then
            return methods_modoptionskeybind[k]
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

input_instance = nil

gm.pre_script_hook(gm.constants["__binding_reset@anon@21596@__input_class_player@__input_class_player"], function(self, other, result, args)
    local verb = args[2].value
    if __custom_verbs_key[verb] or __custom_verbs_gamepad[verb] or __custom_verbs_mouse_button[verb] then
        print("binding reset, canceling for ", verb)
        return false
    end
end)

gm.pre_script_hook(gm.constants["__profile_choice_updated@anon@3823@__input_class_player@__input_class_player"], function(self, other, result, args)
    for k,v in pairs(__custom_verbs_key) do
        ModOptionsKeybind.internal.add_verb(k, v, __custom_verbs_gamepad[k])
    end
    for k,v in pairs(__custom_verbs_mouse_button) do
        ModOptionsKeybind.internal.add_verb(k, v, __custom_verbs_gamepad[k])
    end

    self.__current_profile_dict = gm.variable_struct_get(self.__profiles_dict, self.__profile_name);

    local ticking_verbs = gm.variable_global_get("__input_ticking_verbs_array")

    local name_num = gm.array_length(ticking_verbs);

    if name_num == 29 then
        local t = {}
        for verb, _ in pairs(__custom_verbs_key) do
            table.insert(t, verb)
        end
        gm.array_push(ticking_verbs, table.unpack(t))
    end
    
    name_num = gm.array_length(ticking_verbs);

    self.__binding_current_array = gm.array_create(name_num, nil);

    if self.__current_profile_dict then
        print("adding verb to profile dict")
        verb_data = gm.variable_struct_get(self.__current_profile_dict, verb)
        if verb_data == nil then
            verb_data = gm.array_create(2, 0)
            gm.variable_struct_set(self.__current_profile_dict, verb, verb_data)
        end
        if __custom_verbs_key[verb] then
            gm.array_set(verb_data, false, __custom_verbs_key[verb]);
        else
            gm.array_set(verb_data, false, default);
        end
    end
    
    if self.__current_profile_dict then
        for i = 0, name_num - 1 do
            local a = gm.array_get(ticking_verbs, i)
            local b = gm.variable_struct_get(self.__current_profile_dict, a)
            local c = nil
            if b then
                c = gm.array_get(b, 0)
            end
            if c then
                gm.array_set(self.__binding_current_array, i, c)
            else
                if __custom_verbs_key[a] then
                    print("got a custom verb!", a, __custom_verbs_key[a])
                    gm.array_set(self.__binding_current_array, i, __custom_verbs_key[a])
                else
                    -- print("no custom verb for", a)
                    gm.array_set(self.__binding_current_array, i, gm.input_binding_empty())
                end
            end
        end
    else
        for i = 0, name_num - 1 do
            local a = gm.array_get(ticking_verbs, i)
            if __custom_verbs_key[a] then
                print("got a custom verb2!", a, __custom_verbs_key[a])
                gm.array_set(self.__binding_current_array, i, __custom_verbs_key[a])
            else
                -- print("no custom verb for2", a)
                gm.array_set(self.__binding_current_array, i, gm.input_binding_empty())
            end
        end
    end

    return false
end)

Hook.add_post(RAPI_NAMESPACE, gm.constants.input_binding_set, Callback.internal.FIRST, function(self, other, result, args)
    -- Check if bind is custom verb
    local verb = args[1].value

    if not __custom_verbs_key[verb] and not __custom_verbs_gamepad[verb] and not __custom_verbs_mouse_button[verb] then return end

    -- Store keycode of custom verb
    local binding_struct = args[2].value
    local keycode = binding_struct.value.value

    if gm.variable_struct_get(binding_struct.value, "type") == "mouse button" then
        __custom_verbs_mouse_button[verb] = keycode
        __custom_verbs_key[verb] = nil
    elseif gm.variable_struct_get(binding_struct.value, "type") == "key" then
        __custom_verbs_key[verb] = keycode
        __custom_verbs_mouse_button[verb] = nil
    else
        __custom_verbs_gamepad[verb] = keycode
    end

    -- Save keybinds to file
    local file = TOML.new(RAPI_NAMESPACE)
    local settings = file:read() or {}
    settings.keybinds = {}
    settings.keybinds_mouse_button = {}
    settings.keybinds_gamepad = {}
    for verb, keycode in pairs(__custom_verbs_key) do
        settings.keybinds[verb] = keycode
    end
    for verb, keycode in pairs(__custom_verbs_mouse_button) do
        settings.keybinds_mouse_button[verb] = keycode
    end
    for verb, keycode in pairs(__custom_verbs_gamepad) do
        settings.keybinds_gamepad[verb] = keycode
    end
    file:write(settings)
end)
