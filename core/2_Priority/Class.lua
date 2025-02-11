-- Class

Class = {}



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


    __metatable = "RAPI.Class"
}
setmetatable(Class, metatable_class)



-- ========== Custom `.find` table ==========

local class_find_tables = {}
for _, class_gm in pairs(class_rapi_to_gm) do
    class_find_tables[class_gm] = {}
end

local allow_find_repopulate = false

-- Run once on initialize, and afterwards
-- every time a new piece of content is added
Class_find_repopulate = function(class_gm)
    local arr = gm.variable_global_get(class_gm)
    local size = gm.array_length(arr)
    local t = class_find_tables[class_gm]

    -- Loop class_array
    for i = 0, size - 1 do

        -- If current element is valid (i.e., is an array),
        -- get its namespace and identifier
        local element = gm.array_get(arr, i)
        local namespace, identifier = nil, nil
        if userdata_type(element) == "sol.RefDynamicArrayOfRValue*" then
            namespace = gm.array_get(element, 0)
            identifier = gm.array_get(element, 1)
        end

        -- Store in table
        if namespace then
            if not t[namespace] then t[namespace] = {} end
            t[namespace][identifier] = i
            t[i] = {namespace, identifier}
        end
    end
end

-- Run Class_find_repopulate for a class
-- if a new piece of content is added to it
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
    gm.post_script_hook(hook[1], function(self, other, result, args)
        if not allow_find_repopulate then return end
        Class_find_repopulate(hook[2])
    end)
end



-- DEBUG
Class.debug_force_repopulate = function()
    -- Populate find table
    for _, class_gm in pairs(class_rapi_to_gm) do
        Class_find_repopulate(class_gm)
    end
    allow_find_repopulate = true

    -- Populate class_wrappers
    for class_rapi, class_gm in pairs(class_rapi_to_gm) do
        class_wrappers[class_rapi:upper()] = Array.wrap(gm.variable_global_get(class_gm))
    end
end



-- ========== Base Implementations ==========

-- This file will also create the base implementations
-- for every class_array class, containing:
--      * PROPERTY
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
    local class_table = {}

    class_table.PROPERTY = ReadOnly.new(properties[class_gm])

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
        return Proxy.new(value, metatable_class_arrays[class_rapi])
    end

    metatable_class_arrays[class_rapi] = {
        __index = function(t, k)
            -- Get wrapped value
            local value = Proxy.get(t)
            if k == "value" then return value end
            if k == "RAPI" then return true end

            -- Methods
            if methods_class[class_rapi][k] then
                return methods_class[class_rapi][k]
            end

            -- Getter
            local index = class_table.PROPERTY[k]
            if index then
                local array = gm.variable_global_get(class_gm)
                local element = gm.array_get(array, value)
                return Wrap.wrap(gm.array_get(element, index))
            end
            log.error("Non-existent "..class.." property", 2)
            return nil
        end,


        __newindex = function(t, k, v)
            -- Setter
            local index = class_table.PROPERTY[k]
            if index then
                local array = gm.variable_global_get(class_gm)
                local element = gm.array_get(array, Proxy.get(t))
                gm.array_set(element, index, Wrap.unwrap(v))
                return
            end
            log.error("Non-existent "..class.." property", 2)
        end,

        
        __metatable = "RAPI."..class_rapi
    }

    _CLASS[class_rapi] = class_table
end



_CLASS["Class"] = Class
_CLASS_MT["Class"] = metatable_class