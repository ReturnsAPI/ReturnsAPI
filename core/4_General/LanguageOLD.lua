-- Language

if true then return end

-- TODO convert to `Language.english( ...` syntax proposal

Language = new_class()

if not __language_bank then __language_bank = {} end    -- Preserve on hotload



-- ========== Constants ==========

local language_constants = {
    ENGLISH     = "english",
    FRENCH      = "french",
    GERMAN      = "german",
    ITALIAN     = "italian",
    JAPANESE    = "japanese",
    KOREANA     = "koreana",
    PORTUGUESE  = "portuguese",
    RUSSIAN     = "russian",
    SCHINESE    = "schinese",
    SPANISH     = "spanish",
    TURKISH     = "turkish"
}

-- Add to Language directly (e.g., Language.ENGLISH)
for k, v in pairs(language_constants) do
    Language[k] = v
end



-- ========== Internal ==========

Language.internal.remove_all = function(namespace)
    for language, lbank_language in ipairs(__language_bank) do
        for j = #lbank_language.priorities, 1, -1 do
            local priority = lbank_language.priorities[j]
            local lbank_priority = lbank_language[priority]
            for i = #lbank_priority, 1, -1 do
                local lang_table = lbank_priority[i]
                if lang_table.namespace == namespace then
                    table.remove(lbank_priority, i)
                end
            end
            if #lbank_priority <= 0 then
                lbank_language[priority] = nil
                table.remove(lbank_language.priorities, j)
            end
        end
    end
end



-- ========== Metatables ==========

local function make_metatable_language(namespace)
    return {
        __call = function(t, language, key_table, priority)
            -- Default priority is 0
            priority = priority or 0

            -- Create __language_bank language subtable if it existn't
            if not __language_bank[language] then
                __language_bank[language] = {
                    priorities = {}
                }
            end

            -- Create __language_bank[language] priority subtable if it existn't
            if not __language_bank[language][priority] then
                __language_bank[language][priority] = {}
                table.insert(__language_bank[language].priorities, priority)
                table.sort(__language_bank[language].priorities, function(a, b) return a > b end)
            end
            
            -- Add to subtable
            table.insert(__language_bank[language][priority], {
                namespace   = namespace,
                table       = key_table
            })
        end,


        __metatable = "RAPI.Class.Language"
    }
end
setmetatable(Language, make_metatable_language(_ENV["!guid"]))



-- ========== Hooks ==========

local function parse_keys(map, t, key)
    for k, v in pairs(t) do
        if not key then key = k
        else key = key.."."..k
        end
        if type(v) == "table" then parse_keys(map, v, key)
        else map:set(key, tostring(v))
        end
    end
end

memory.dynamic_hook("RAPI.Language.translate_load_active_language", "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.translate_load_active_language),
    -- Pre-hook
    {nil,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
        local language = GM._mod_language_getLanguageName()
        local language_map = Map.wrap(Global._language_map)

        if __language_bank[language] then
            for _, priority in ipairs(__language_bank[language].priorities) do
                for __, lang_table in ipairs(__language_bank[language][priority]) do
                    parse_keys(language_map, lang_table.table)
                end
            end
        end
    end}
)



__class.Language = Language
__class_mt_builder.Language = make_metatable_language