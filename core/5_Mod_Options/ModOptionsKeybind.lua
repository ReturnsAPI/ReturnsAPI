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

run_once(function()
    __custom_verbs = {}
    __custom_verbs_gamepad = {}
    __add_verb_queue = {}
end)

vanilla_player_verbs = {
    "left", "right", "up", "down", "jump",
    "skill1", "skill2", "skill3", "skill4",
    "equipment", "interact", "swap",
    "aim_left", "aim_right",
    "emote", "ping",
    "emote_1", "emote_2", "emote_3", "emote_4", 
    "tab", "pause"
}



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

ModOptionsKeybind.internal.add_verb = function(verb, default, default_gamepad)
    -- Not sure how much of this is necessary
    -- Works though so don't touch anything

    if Global.__input_profile_dict["keyboard_and_mouse"][verb] then return end

    -- Create keyboard bind
    local bind = gm.input_binding_empty()
    if     __custom_verbs[verb]     then bind = gm.input_binding_key(__custom_verbs[verb])
    elseif default and default > 0  then bind = gm.input_binding_key(default)
    end
    __custom_verbs[verb] = bind.value

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
    Global.__input_all_verb_array:push(verb)
    Global.__input_all_verb_dict[verb] = true

    local ticking_verbs = Global.__input_ticking_verbs_array
    ticking_verbs:push(verb)
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
    local file = TOML.new(RAPI_NAMESPACE)
    settings = file:read() or {}

    if not settings.keybinds then return end

    -- Load saved custom verbs
    for verb, keycode in pairs(settings.keybinds) do
        __custom_verbs[verb] = keycode
    end

    -- Add verbs in queue
    for _, verb_table in ipairs(__add_verb_queue) do
        ModOptionsKeybind.internal.add_verb(table.unpack(verb_table))
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
        ModOptionsKeybind.internal.add_verb(verb, default, default_gamepad)
    else table.insert(__add_verb_queue, {verb, default, default_gamepad})
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

Hook.add_post(RAPI_NAMESPACE, gm.constants.input_binding_set, Callback.Priority.BEFORE, function(self, other, result, args)
    -- Check if bind is custom verb
    local verb = args[1].value
    if not __custom_verbs[verb] then return end

    -- Store keycode of custom verb
    local binding_struct = args[2].value
    local keycode = binding_struct.value
    __custom_verbs[verb] = keycode

    -- Save keybinds to file
    local file = TOML.new(RAPI_NAMESPACE)
    local settings = file:read() or {}
    settings.keybinds = {}
    settings.keybinds_gamepad = {}
    for verb, keycode in pairs(__custom_verbs) do
        settings.keybinds[verb] = keycode
    end
    for verb, keycode in pairs(__custom_verbs_gamepad) do
        settings.keybinds_gamepad[verb] = keycode
    end
    file:write(settings)
end)


local ptr = gm.get_script_function_address(gm.constants.__input_update_ticking_verbs)

-- Hooks line 26 (right after `var name_num = array_length(global.__input_ticking_verbs_array);`)
-- Look for a long series of Rvalue copies; that is the array being initialized
memory.dynamic_hook_mid("RAPI.ModOptionsKeybind.__input_update_ticking_verbs", {"rbp-D0h"}, {"RValue*"}, 0, ptr:add(0xC13), function(args)
    -- args[1].value is `Global.__input_ticking_verbs_array`
    -- (but will be a bool when paused for some reason)
    local ticking_verbs = args[1].value
    if type(ticking_verbs) == "boolean" then return end

    -- Add custom verbs to array
    local t = {}
    for verb, _ in pairs(__custom_verbs) do
        table.insert(t, verb)
    end
    gm.array_push(ticking_verbs, table.unpack(t))
end)