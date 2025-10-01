-- Class

--[[
Allows for accessing class arrays via `Class.<class>`.
(E.g., `Class.Item`)
]]

Class = new_class()



-- ========== Populate RAPI <-> Global name mapping ==========

-- Passing RAPI class name as key returns
-- its global class name, and vice versa

local file = toml.decodeFromFile(PATH.."core/data/class_name_mapping.txt")
class_name_r2g = file.mapping   -- RAPI     ->      Global
class_name_g2r = {}             -- Global   ->      RAPI
for name_rapi, name_global in pairs(class_name_r2g) do
    class_name_g2r[name_global] = name_rapi
end



-- ========== Metatables ==========

local class_wrappers = {}

Class.internal.initialize = function()
    -- For reference:
    -- __class_find_tables[name_global][namespace][identifier]  = element_table (see in next section below)
    -- __class_find_tables[name_global][id]                     = element_table

    -- Populate class_wrappers on initialize
    -- since some class arrays existn't before then
    for name_rapi, name_global in pairs(class_name_r2g) do

        -- Wrap `class_*` in Array wrappers and store in `class_wrappers`
        class_wrappers[name_rapi:upper()] = Global[name_global]

        -- Update cached wrappers in __class_find_tables
        local find_table = __class_find_tables[name_global]
        for id, element_table in pairs(find_table) do
            if type(id) == "number" then
                element_table.wrapper = __class[name_rapi].wrap(element_table.id)
            end
        end
    end
end
table.insert(_rapi_initialize, Class.internal.initialize)


make_table_once("metatable_class", {
    -- Allows for accessing wrapped class arrays via Class.<class> (case-insensitive)
    __index = function(t, k)
        k = k:upper()
        if class_wrappers[k] then return class_wrappers[k] end
        log.error("Class does not exist", 2)
    end,


    __newindex = function(t, k, v)
        log.error("Class has no properties to set", 2)
    end,


    __metatable = "RAPI.Class.Class"
})
setmetatable(Class, metatable_class)



-- ========== Custom `.find` table ==========

-- E.g.,
-- local element_table = {
--     id          = id,
--     namespace   = namespace,
--     identifier  = identifier,
--     array       = Global[name_global]:get(id)
--     wrapper     = __class[class_name_g2r[name_global]].wrap(id)
-- }
-- __class_find_tables["class_item"]["ror"]["meatNugget"] = element_table
-- __class_find_tables["class_item"][0] = element_table

run_once(function()
    __class_find_tables = {}
    for name_global, _ in pairs(class_name_g2r) do
        __class_find_tables[name_global] = {}
    end
end)

-- Detect if new content is added and add to find table
-- All vanilla content is added through these as well
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
    local name_global = hook[2]

    gm.post_script_hook(hook[1], function(self, other, result, args)
        local namespace     = args[1].value
        local identifier    = args[2].value
        local id            = result.value

        -- Add to find table
        if namespace then
            local element_table = {
                id          = id,
                namespace   = namespace,
                identifier  = identifier,
                array       = Global[name_global]:get(id),
                wrapper     = __class[class_name_g2r[name_global]].wrap(id)
            }
            local t = __class_find_tables[name_global]
            if not t[namespace] then t[namespace] = {} end
            t[namespace][identifier] = element_table
            t[id] = element_table
        end
    end)
end



-- ========== Class Base Implementations ==========

-- This file will also create the base implementations
-- for every class array, containing:
--      * Property          enum
--      * find              static method
--      * find_all          static method
--      * wrap              static method
--      * print_properties  instance method
--      * Metatable for get/set properties
-- 
-- Use __class[<RAPI name>] in their respective
-- files instead of creating a new table
-- 
-- Additionally, modify methods_class[<RAPI name>] for instance methods

methods_class_array = {}

run_once(function()
    for name_rapi, _ in pairs(class_name_r2g) do
        make_table_once("metatable_"..name_rapi)
    end
end)

-- Load property names from data
local file = toml.decodeFromFile(PATH.."core/data/class_array.txt")
local properties = file.array

-- Create new class table for every class array
for name_rapi, name_global in pairs(class_name_r2g) do
    local metatable_name = "metatable_"..name_rapi

    local class_table = new_class()

    -- Create enum `*.Property` from "class_array.txt"
    local enum = {}
    for k, v in pairs(properties[name_global]) do
        enum[k:upper()] = v     -- e.g., Item.Property.NAMESPACE = 0
        enum[v] = k             -- e.g., Item.Property[0] = "namespace";    Don't capitalize name here
    end
    class_table.Property = enum

    -- find
    class_table.find = function(identifier, namespace, namespace_is_specified)
        -- Search in namespace
        local namespace_table = __class_find_tables[name_global][namespace]
        if namespace_table then
            local element_table = namespace_table[identifier]
            if element_table then return element_table.wrapper end
        end

        -- Also search in "ror" namespace by default if unspecified
        if not namespace_is_specified then
            element_table = __class_find_tables[name_global]["ror"][identifier]
            if element_table then return element_table.wrapper end
        end

        return nil
    end

    -- find_all
    class_table.find_all = function(NAMESPACE, filter, property)
        local elements = {}
        local filter_arg = filter
        local filter = Wrap.unwrap(filter) or NAMESPACE
        local property = property or 0  -- Namespace filter by default

        -- Namespace filter
        if property == 0 then
            local namespace_table = __class_find_tables[name_global][filter]
            if namespace_table then
                for _, element_table in pairs(namespace_table) do
                    table.insert(elements, element_table.wrapper)
                end
            end

            -- Also search in "ror" namespace if passed no `filter` arg
            if not filter_arg then
                filter = "ror"
                local namespace_table = __class_find_tables[name_global][filter]
                if namespace_table then
                    for _, element_table in pairs(namespace_table) do
                        table.insert(elements, element_table.wrapper)
                    end
                end
            end

        -- Other filter (very slow!)
        else
            local find_table = __class_find_tables[name_global]
            local element_max = #find_table
            for i = 0, element_max do
                local element_table = find_table[i]
                if element_table.array:get(property) == filter then
                    table.insert(elements, element_table.wrapper)
                end
            end
        end

        return elements
    end

    -- wrap
    class_table.wrap = function(value)
        -- Input:   number
        -- Wraps:   number
        return make_proxy(Wrap.unwrap(value), private[metatable_name])
    end

    -- Instance methods
    methods_class_array[name_rapi] = {
        print_properties = function(self)
            local array = __class_find_tables[name_global][self.value].array
            local str = ""
            for i, v in ipairs(array) do
                str = str.."\n"..Util.pad_string_right(class_table.Property[i - 1], 32).." = "..Util.tostring(v)
            end
            print(str)
        end
    }

    -- Metatable
    make_table_once(metatable_name, {
        __index = function(proxy, k)
            -- Get wrapped value
            local value = __proxy[proxy]
            if k == "value" then return value end
            if k == "RAPI"  then return name_rapi end
            if k == "array" then return __class_find_tables[name_global][value].array end

            -- Methods
            local method = methods_class_array[name_rapi][k]
            if method then return method end

            -- Getter
            if type(k) == "string" then
                local index = class_table.Property[k:upper()]
                if index then
                    return proxy.array:get(index)
                end
            end
            log.error("Non-existent "..name_rapi.." property '"..k.."'", 2)
        end,


        __newindex = function(proxy, k, v)
            -- Throw read-only error for certain keys
            if k == "value"
            or k == "RAPI"
            or k == "array" then
                log.error("Key '"..k.."' is read-only", 2)
            end
            
            -- Setter
            if type(k) == "string" then
                local index = class_table.Property[k:upper()]
                if index then
                    proxy.array:set(index, v)
                    return
                end
            end
            log.error("Non-existent "..name_rapi.." property '"..k.."'", 2)
        end,


        __eq = function(proxy, other)
            return proxy.value == other.value
        end,

        
        __metatable = "RAPI.Wrapper."..name_rapi
    })

    __class[name_rapi] = class_table
    private[name_rapi] = class_table    -- To allow internal use in RAPI
                                        -- if the Lua file doesn't exist yet
end



-- Public export
__class.Class = Class
__class_mt.Class = metatable_class