-- Language

Language = new_class()

if not __language_registered then __language_registered = {} end    -- Preserve on hotload



-- ========== Static Methods ==========

Language.translate_token = function(token)
    local language_map = Global._language_map
    if type(language_map) == "number" then language_map = Map.wrap(language_map) end
    local text = language_map:get(token)
    if text then return text end
    return token
end


Language.register_autoload = function(env)
    if not env then env = envy.getfenv(2) end
    if not Util.table_has(__language_registered, env) then
        table.insert(__language_registered, env)
    end
end



-- ========== Functions ==========

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


local function load_from_folder(folder_path)
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
        if folder_name == language then
            found = true
            local files = path.get_files(folder)    -- Parse all files in folder
            for _, file in ipairs(files) do
                parse_keys(language_map, require(file))
            end
            break
        end
    end

    -- Load English by default if current language was not found
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



-- ========== Hooks and Other ==========

memory.dynamic_hook("RAPI.Language.translate_load_active_language", "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.translate_load_active_language),
    -- Pre-hook
    {nil,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
        load_from_mods()
    end}
)



__class.Language = Language