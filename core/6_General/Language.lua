-- Language

--[[
You can create a folder called `language` (case-insensitive) containing
Lua files that will automatically be loaded in with the base language file.

A file should return a translation token table,
and should either be named `<language>.lua` or in a folder/subfolder `<language>`.

Example:
```lua
-- Example paths:
-- language/english.lua
-- language/english/myTranslations.lua
-- language/english/subfolder/myTranslations.lua
-- language/folder/subfolder/english/myTranslations.lua

return {
    item = {
        myItem = {
            name        = "My Item",
            pickup      = "A cool item!",
            description = "Does something really cool.",
            destination = "A place",
            date        = "A time",
            story       = "I found it on the ground.",
            priority    = "Standard"
        }
    },

    skill = {
        mySkill = {
            name        = "My Skill",
            description = "Pew pew"
        }
    }
}
```

---

`gm.translate(token, ...)` will return the actual text of the localization token in the current language.
If the token's actual text has instances of `%s`, they will be replaced with the variable arguments in order.

E.g.,
```lua
-- "foo.bar.baz" maps to "Hello %s!" in the language file.

gm.translate("foo.bar.baz", "world")    --> "Hello world!"
```
]]

Language = new_class()

run_once(function()
    -- Contains ENV tables of all registered mods
    __language_registered = {}
end)



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       string
--@param        env         | table     | The environment table of the mod to register.
--[[
Registers a mod to autoload language files in a `language` (case-insensitive) folder.

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
    local language = gm._mod_language_getLanguageName()
    local language_map = Map.wrap(Global._language_map)

    local eng_tables = {}
    local found = false

    local function loop_files(folder_path, folder_lang)
        -- Check for Lua files
        local files = path.get_files(folder_path)
        for _, file in ipairs(files) do
            local filename = path.filename(file):sub(1, -5):lower()
            local lang_table = require(file)

            -- Store table if English
            if (filename == "english")
            or (folder_lang == "english") then table.insert(eng_tables, lang_table) end

            -- Parse returned table if it matches language
            if (filename == language)
            or (folder_lang == language) then
                found = true
                parse_keys(language_map, lang_table)
                break
            end
        end

        -- Check for subfolders
        local folders = path.get_directories(folder_path)
        for _, folder in ipairs(folders) do
            local passed_folder_lang = folder_lang

            local folder_name = path.filename(folder):lower()
            if (folder_name == "english")
            or (folder_name == language) then
                passed_folder_lang = folder_name
            end

            loop_files(folder, passed_folder_lang)
        end
    end

    loop_files(folder_path)

    -- Load English by default if current
    -- language was not found anywhere
    if not found then
        for _, lang_table in ipairs(eng_tables) do
            parse_keys(language_map, lang_table)
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

memory.dynamic_hook("RAPI.Language.translate_load_active_language", "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.translate_load_active_language),
    -- Pre-hook
    {nil,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
        load_from_mods()
    end}
)



-- Public export
__class.Language = Language