-- Class

Class = new_class()



-- ========== Populate RAPI <-> GM name mappings ==========

local file = toml.decodeFromFile(PATH.."core/data/class_name_mapping.txt")
class_rapi_to_gm = file.mapping
class_gm_to_rapi = {}
for k, v in pairs(class_rapi_to_gm) do
    class_gm_to_rapi[v] = k
end



-- ========== Metatables ==========

local class_wrappers = {}

Class.internal.initialize = function()
    -- Populate class_wrappers on initialize
    for class_rapi, class_gm in pairs(class_rapi_to_gm) do
        class_wrappers[class_rapi:upper()] = Global[class_gm]
    end
end


metatable_class = {
    -- Allows for accessing wrapped class arrays via Class.<class>
    __index = function(t, k)
        k = k:upper()
        if class_wrappers[k] then return class_wrappers[k] end
        log.error("Class does not exist", 2)
    end,


    __metatable = "RAPI.Class.Class"
}
setmetatable(Class, metatable_class)



-- ========== Custom `.find` table ==========

if not __class_find_tables then -- Preserve on hotload
    __class_find_tables = {}
    for _, class_gm in pairs(class_rapi_to_gm) do
        __class_find_tables[class_gm] = {}
    end
end

-- Detect if new content is added and add to find table
-- All vanilla content is added through these as well
local allow_find_repopulate = false
local hooks = {
    {gm.constants.achievement_create,       "class_achievement"},
    {gm.constants.actor_skin_create,        "class_actor_skin"},
    {gm.constants.actor_state_create,       "class_actor_state"},
    {gm.constants.artifact_create,          "class_artifact"},
    {gm.constants.buff_create,              "class_buff"},
    {gm.constants.difficulty_create,        "class_difficulty"},
    {gm.constants.elite_type_create,        "class_elite"},
    {gm.constants.ending_create,            "class_ending_type"},
    {gm.constants.environment_log_create,   "class_environment_log"},
    {gm.constants.equipment_create,         "class_equipment"},
    {gm.constants.gamemode_create,          "class_game_mode"},
    {gm.constants.interactable_card_create, "class_interactable_card"},
    {gm.constants.item_create,              "class_item"},
    {gm.constants.item_log_create,          "class_item_log"},
    {gm.constants.monster_card_create,      "class_monster_card"},
    {gm.constants.monster_log_create,       "class_monster_log"},
    {gm.constants.skill_create,             "class_skill"},
    {gm.constants.stage_create,             "class_stage"},
    {gm.constants.survivor_create,          "class_survivor"},
    {gm.constants.survivor_log_create,      "class_survivor_log"}
}
for _, hook in ipairs(hooks) do
    memory.dynamic_hook("RAPI.Class."..hook[2], "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(hook[1]),
        -- Pre-hook
        {nil,

        -- Post-hook
        function(ret_val, self, other, result, arg_count, args)
            local args_typed = ffi.cast("struct RValue**", args:get_address())

            local namespace = RValue.to_wrapper(args_typed[0])
            local identifier = RValue.to_wrapper(args_typed[1])
            local id = RValue.to_wrapper(ffi.cast("struct RValue*", result:get_address()))

            if namespace then
                local t = __class_find_tables[hook[2]]
                if not t[namespace] then t[namespace] = {} end
                t[namespace][identifier] = id
                t[id] = {namespace = namespace, identifier = identifier}
            end
        end}
    )
end



-- ========== Base Implementations ==========

-- This file will also create the base implementations
-- for every class_array class, containing:
--      * Property
--      * find
--      * find_all
--      * wrap
--      * Metatable for get/set properties
-- 
-- Use __class[<RAPI name>] in their respective
-- files instead of creating a new table
-- 
-- Additionally, modify method_class[<RAPI name>] for instance methods

local metatable_class_arrays = {}
methods_class = {}

-- Load property name from data
local file = toml.decodeFromFile(PATH.."core/data/class_array.txt")
local properties = file.array

for class_rapi, class_gm in pairs(class_rapi_to_gm) do
    local class_table = new_class()

    local capitalized = {}
    for k, v in pairs(properties[class_gm]) do
        capitalized[k:upper()] = v
        capitalized[v] = k  -- Don't capitalize this lol
    end
    class_table.Property = ReadOnly.new(capitalized)

    class_table.find = function(identifier, namespace, default_namespace)
        local namespace, is_specified = parse_optional_namespace(namespace, default_namespace)

        -- Search in namespace
        local namespace_table = __class_find_tables[class_gm][namespace]
        if namespace_table then
            local element = namespace_table[identifier]
            if element then return class_table.wrap(element) end
        end

        -- Also search in "ror" namespace by default if unspecified
        if not is_specified then
            element = __class_find_tables[class_gm]["ror"][identifier]
            if element then return class_table.wrap(element) end
        end

        return nil
    end

    class_table.find_all = function(filter, property)
        -- TODO
    end

    class_table.wrap = function(value)
        return Proxy.new(Wrap.unwrap(value), metatable_class_arrays[class_rapi])
    end

    methods_class[class_rapi] = {}  -- Populate in class file

    metatable_class_arrays[class_rapi] = {
        __index = function(proxy, k)
            -- Get wrapped value
            local value = Proxy.get(proxy)
            if k == "value" then return value end
            if k == "RAPI" then return getmetatable(proxy):sub(14, -1) end

            -- Methods
            if methods_class[class_rapi][k] then
                return methods_class[class_rapi][k]
            end

            -- Getter
            local index = class_table.Property[k:upper()]
            if index then
                return Class[class_rapi]:get(value):get(index)
            end
            log.error("Non-existent "..class_rapi.." property", 2)
            return nil
        end,


        __newindex = function(proxy, k, v)
            -- Setter
            local index = class_table.Property[k:upper()]
            if index then
                Class[class_rapi]:get(Proxy.get(proxy)):set(index, v)
                return
            end
            log.error("Non-existent "..class_rapi.." property", 2)
        end,

        
        __metatable = "RAPI.Wrapper."..class_rapi
    }

    __class[class_rapi] = class_table
end



__class.Class = Class
__class_mt.Class = metatable_class