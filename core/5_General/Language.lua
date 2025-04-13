-- Language

Language = new_class()

-- Contains env tables of all registered mods
if not __language_registered then __language_registered = {} end    -- Preserve on hotload



-- ========== Static Methods ==========

--$static
--$return       string
--$param        token       | string    | The localization token (e.g., `item.barbedWire.name`)
--[[
Returns the actual text of the localization token in the current language,
or `token` if none is found.
]]
Language.translate_token = function(token)
    local language_map = Global._language_map
    if type(language_map) == "number" then language_map = Map.wrap(language_map) end    -- If Global cache is not created
    local text = language_map:get(token)
    if text then return text end
    return token
end


--$static
--$return       string
--$param        env         | table     | The environment table of the mod to register.
--[[
Registers a mod to autoload language files in a `language` folder.

Automatically called on `.auto()` import.
]]
Language.register_autoload = function(env)
    if not env then env = envy.getfenv(2) end
    if not Util.table_has(__language_registered, env) then
        table.insert(__language_registered, env)
    end
end



-- ========== Functions ==========

-- Recursive parsing of a json-like Lua table
local function parse_keys(map, t, key)
    if not t then return end
    for k, v in pairs(t) do
        local newkey = key
        if not newkey then newkey = k
        else newkey = newkey.."."..k
        end
        if type(v) == "table" then parse_keys(map, v, newkey)
        else map:set(newkey, tostring(v))
        end
    end
end


-- Loads language files from a mod's "language" folder
local function load_from_folder(folder_path)
    -- Get current language name
    -- and `_language_map`
    local language = GM._mod_language_getLanguageName()
    local language_map = Global._language_map
    if type(language_map) == "number" then language_map = Map.wrap(language_map) end

    local eng_file = nil
    local eng_folder = nil
    local found = false

    -- Check for `<language>.lua`
    local files = path.get_files(folder_path)
    for _, file in ipairs(files) do
        local filename = path.filename(file):sub(1, -5):lower()
        if filename == "english" then eng_file = file end

        -- Parse returned table if found
        if filename == language then
            found = true
            parse_keys(language_map, require(file))
            break
        end
    end

    -- Check for `<language>` subfolder
    local folders = path.get_directories(folder_path)
    for _, folder in ipairs(folders) do
        local folder_name = path.filename(folder):lower()
        if folder_name == "english" then eng_folder = folder end
        
        -- Parse returned tables from all files inside if found
        if folder_name == language then
            found = true
            local files = path.get_files(folder)    -- Parse all files in folder
            for _, file in ipairs(files) do
                parse_keys(language_map, require(file))
            end
            break
        end
    end

    -- Load English by default if current language was *not*
    -- found as either a standalone file or a folder
    if not found then
        if eng_file then parse_keys(language_map, require(eng_file)) end
        if eng_folder then
            local files = path.get_files(eng_folder)    -- Parse all files in folder
            for _, file in ipairs(files) do
                parse_keys(language_map, require(file))
            end
        end
    end
end


-- Loads language files from all registered mods
local function load_from_mods()
    -- Loop through registered mods
    for _, env in ipairs(__language_registered) do

        -- Search for a "language" folder in mod folder
        local folders = path.get_directories(env["!plugins_mod_folder_path"])
        for k, folder_path in ipairs(folders) do
            if path.filename(folder_path):lower() == "language" then
                load_from_folder(folder_path)
            end
        end

    end
end



-- ========== Hooks ==========

Memory.dynamic_hook("RAPI.Language.translate_load_active_language", "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.translate_load_active_language),
    -- Pre-hook
    {nil,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
        load_from_mods()
    end}
)



__class.Language = Language