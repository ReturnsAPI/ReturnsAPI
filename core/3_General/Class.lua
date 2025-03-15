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

local class_wrappers = {}   -- Populated on initialize

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

local class_find_tables = {}
for _, class_gm in pairs(class_rapi_to_gm) do
    class_find_tables[class_gm] = {}
end

-- Run once on initialize, and afterwards
-- every time a new piece of content is added
Class.internal.find_repopulate = function(class_gm)
    local arr = Class[class_gm_to_rapi[class_gm]]
    local t = class_find_tables[class_gm]

    -- Loop class_array
    for i, v in ipairs(arr) do

        -- If current element is valid (i.e., is an array),
        -- get its namespace and identifier
        local element = arr:get(i - 1)
        local namespace, identifier = nil, nil
        if Array.is(element) then
            namespace = element:get(0)
            identifier = element:get(1)
        end

        -- Store in table
        if namespace then
            if not t[namespace] then t[namespace] = {} end
            t[namespace][identifier] = i - 1
            t[i - 1] = {namespace, identifier}
        end
    end
end

-- Run Class_find_repopulate for a class
-- if a new piece of content is added to it
local allow_find_repopulate = false
local hooks = {
    {gmf.achievement_create,       "class_achievement"},
    {gmf.actor_skin_create,        "class_actor_skin"},
    {gmf.actor_state_create,       "class_actor_state"},
    {gmf.artifact_create,          "class_artifact"},
    {gmf.buff_create,              "class_buff"},
    {gmf.difficulty_create,        "class_difficulty"},
    {gmf.elite_type_create,        "class_elite"},
    {gmf.ending_create,            "class_ending_type"},
    {gmf.environment_log_create,   "class_environment_log"},
    {gmf.equipment_create,         "class_equipment"},
    {gmf.gamemode_create,          "class_game_mode"},
    {gmf.interactable_card_create, "class_interactable_card"},
    {gmf.item_create,              "class_item"},
    {gmf.item_log_create,          "class_item_log"},
    {gmf.monster_card_create,      "class_monster_card"},
    {gmf.monster_log_create,       "class_monster_log"},
    {gmf.skill_create,             "class_skill"},
    {gmf.stage_create,             "class_stage"},
    {gmf.survivor_create,          "class_survivor"},
    {gmf.survivor_log_create,      "class_survivor_log"}
}
for _, hook in ipairs(hooks) do
    memory.dynamic_hook("RAPI.Class."..hook[2], "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants[hook[1]]),
        -- Pre-hook
        {nil,

        -- Post-hook
        function(ret_val, self, other, result, arg_count, args)
            if not allow_find_repopulate then return end
            Class.internal.find_repopulate(hook[2])
        end}
    )
end



-- ========== Initialize ==========

Class.internal.initialize = function()
    -- Populate class_wrappers
    for class_rapi, class_gm in pairs(class_rapi_to_gm) do
        class_wrappers[class_rapi:upper()] = Global[class_gm]
    end

    -- Populate find table
    for _, class_gm in pairs(class_rapi_to_gm) do
        Class.internal.find_repopulate(class_gm)
    end
    allow_find_repopulate = true
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
-- Use _CLASS[<RAPI name>] in their respective
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
    for k, v in pairs(properties[class_gm]) do capitalized[k:upper()] = v end
    class_table.Property = ReadOnly.new(capitalized)

    class_table.find = function(identifier, namespace, default_namespace)
        -- Search in namespace
        local namespace_table = class_find_tables[class_gm][namespace]
        if namespace_table then
            local element = namespace_table[identifier]
            if element then return class_table.wrap(element) end
        end

        -- Also search in "ror" namespace if default namespace (i.e., No namespace arg)
        if namespace == default_namespace then
            element = class_find_tables[class_gm]["ror"][identifier]
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
        __index = function(t, k)
            -- Get wrapped value
            local value = Proxy.get(t)
            if k == "value" then return value end
            if k == "RAPI" then return getmetatable(t):sub(14, -1) end

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


        __newindex = function(t, k, v)
            -- Setter
            local index = class_table.Property[k:upper()]
            if index then
                Class[class_rapi]:get(Proxy.get(t)):set(index, Wrap.unwrap(v))
                return
            end
            log.error("Non-existent "..class_rapi.." property", 2)
        end,

        
        __metatable = "RAPI.Wrapper."..class_rapi
    }

    _CLASS[class_rapi] = class_table
end



_CLASS["Class"] = Class
_CLASS_MT["Class"] = metatable_class