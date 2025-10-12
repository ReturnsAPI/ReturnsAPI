-- ModOptionsKeybind

-- The class table is private, but the wrappers are publicly accessible

-- TODO:
-- * Firstly, see if you can actually check bind press or not
-- * `add_verb` should be called in Initialize actually
--      * Currently you have to open settings menu to create the binds (dumb)
-- * Disable no-duplicates check for custom binds

ModOptionsKeybind = new_class()

run_once(function()
    __custom_verbs = {}
end)



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`RAPI`          | string    | *Read-only.* The wrapper name.
`namespace`     | string    | *Read-only.* The namespace of the ModOptions the element is in.
`identifier`    | string    | *Read-only.* The identifier of the element.
`verb`          | string    | *Read-only.* The verb name for the keybind.
]]



-- ========== Internal ==========

ModOptionsKeybind.internal.add_verb = function(verb, default)
    -- Not sure how much of this is necessary
    -- Works though so don't touch anything

    if Global.__input_profile_dict["keyboard_and_mouse"][verb] then return end

    local bind = gm.input_binding_empty()
    if      __custom_verbs[verb]   then bind = gm.input_binding_key(__custom_verbs[verb])
    elseif  default > 0                 then bind = gm.input_binding_key(default)
    end
    __custom_verbs[verb] = bind.value

    Global.__input_profile_dict["keyboard_and_mouse"][verb] = bind
    local verb_data = Global.__input_profile_dict["keyboard_and_mouse"][verb]

    Global.__input_basic_verb_array:push(verb)
    Global.__input_basic_verb_dict[verb] = true
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

        struct.__verb_state_array = gm.array_create(ticking_verbs_count, 0);
        for j = 1, ticking_verbs_count do
            struct.__verb_state_array[j] = struct.__verb_state_dict[ticking_verbs[j]];
        end
        struct.__profile_choice_updated()
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
end)



-- ========== Static Methods ==========

ModOptionsKeybind.new = function(namespace, identifier, default)
    default = default or -1

    local verb = namespace.."."..identifier

    local element_data_table = {
        namespace       = namespace,
        identifier      = identifier,
        verb            = verb,
        constructor     = function()
            ModOptionsKeybind.internal.add_verb(verb, default)

            local struct = Struct.new(
                gm.constants.UIOptionsButtonControlRemapKey,
                namespace.."."..identifier,
                verb,
                "keyboard_and_mouse"
            )
            struct.background_height = struct.background_height + 38
            struct.is_odd = true
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

gm.post_script_hook(gm.constants.input_binding_set, function(self, other, result, args)
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
    for verb, keycode in pairs(__custom_verbs) do
        settings.keybinds[verb] = keycode
    end
    file:write(settings)
end)