-- Class

--[[
Allows for accessing content class arrays via `Class.<class>`.
(E.g., `Class.Item`)
]]
---@class Class
Class = new_class()
C.Class = Class

local proxy = P.proxy

local string_upper       = string.upper
local check_init_started = Initialize.internal.check_if_started


-- ========== RAPI <-> Global name mapping ==========

-- Mappings for RAPI class name
-- to global name and vice versa

local file = toml.decodeFromFile(path.combine(PATH, "data", "tables", "class_name_mapping.txt"))

local class_name_r2g = file.mapping ---@type table<string, string> RAPI   -> Global
local class_name_g2r = {}           ---@type table<string, string> Global -> RAPI

for name_rapi, name_global in pairs(class_name_r2g) do
    class_name_g2r[name_global] = name_rapi
end


-- ========== Metatables ==========

local class_arrays = {} ---@type table<string, Array>

local populate_class_arrays = function()
    for name_rapi, name_global in pairs(class_name_r2g) do
        -- Populate `class_arrays` on initialize
        -- since some content class arrays do not exist before then

        -- Wrap `class_*` in Array wrappers and store in `class_arrays`
        -- E.g., `class_arrays["ITEM"] = Global["class_item"]
        class_arrays[string_upper(name_rapi)] = Global[name_global]
    end
end
run_on_initialize(populate_class_arrays)

---@class Class
---@field [string] Array A content class array.

local mt_name = "Class"

M.Class = {
    -- Allows for accessing wrapped content class arrays via `Class.<class>` (case-insensitive)
    __index = function(t, k)
        check_init_started(mt_name)
        local wrapper = class_arrays[string_upper(k)]
        if wrapper then return wrapper end
        log.error("Class does not exist", 2)
    end,

    __newindex = function(t, k, v)
        log.error(mt_name.." has no properties to set", 2)
    end,

    __metatable = mt_class_name(mt_name),
}
setmetatable(Class, M.Class)


-- ========== Find Tables ==========

run_on_initial_load(function()
    P.class_find_tables = {}  ---@type table<string, FindTable> `<name_global>` -> Content class FindTable

    for name_global, _ in pairs(class_name_g2r) do
        P.class_find_tables[name_global] = FindTable.new()
    end
end)

local class_find_tables = P.class_find_tables

-- Detect if new content is added and add to find table
-- All vanilla content is added through these as well
---@type table<number, table>
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
    {gm.constants.survivor_log_create,      "class_survivor_log"},
}
for _, hook in ipairs(hooks) do
    local name_rapi   = class_name_g2r[hook[2]]
    local name_global = hook[2]  ---@type string

    gm.post_script_hook(hook[1], function(self, other, result, args)
        local namespace  = args[1].value  ---@type string
        local identifier = args[2].value  ---@type string
        local id         = result.value   ---@type number

        -- Add to find table
        if namespace then
            class_find_tables[name_global]:set(
                {
                    wrapper    = C[name_rapi].wrap(id),
                    properties = Global[name_global]:get(id), -- Array
                },
                identifier,
                namespace,
                id
            )
        end
    end)
end


-- ========== Class Base Implementations ==========

-- This file will also create the table declarations
-- for every content class array, as well as the
-- metatables for get/set properties
--
-- The variable for the class (e.g., `Item`)
-- will already be defined
-- E.g.,
-- ---@class Item
-- Item = C["Item"]
--
-- Additionally, modify `G.methods_content[<RAPI name>]` for wrapper methods
-- E.g.,
-- ---@class Item
-- local methods = G.methods_content["Item"]

-- Load property names from data
local file = toml.decodeFromFile(path.combine(PATH, "data", "tables", "class_array.txt"))
local properties = file.array

G.methods_content = {}  ---@type table<string, table> Contains tables of wrapper methods for each content class.

-- Create new class table for every content class
for name_rapi, name_global in pairs(class_name_r2g) do
    local content_class = new_class()
    C[name_rapi] = content_class

    local methods = {}
    G.methods_content[name_rapi] = methods

    -- Must create `Property` enum and
    -- all methods in respective class file
    -- (See above)
    content_class.Property = {}
    content_class.new      = function() throw("Method has not been created for this class yet") end
    content_class.find     = function() throw("Method has not been created for this class yet") end
    content_class.find_all = function() throw("Method has not been created for this class yet") end
    content_class.wrap     = function() throw("Method has not been created for this class yet") end
    methods.print          = function() throw("Method has not been created for this class yet") end

    local class_find_table = class_find_tables[name_global]

    W[name_rapi] = {
        __index = function(t, k)
            -- Get wrapped value
            local value = proxy[t]  ---@type number
            if k == "value" then return value end
            if k == "RAPI" then return name_rapi end
            if k == "properties"
            or k == "array" then
                return class_find_table[value].value.properties
            end

            -- Methods
            local method = methods[k]
            if method then return method end

            -- Getter
            local index = content_class.Property[string_upper(k)]
            if index then
                ---@type Array
                local properties = class_find_table[value].value.properties
                return properties:get(index)
            end
            log.error("Non-existent "..name_rapi.." property '"..k.."'", 2)
        end,

        __newindex = function(t, k, v)
            -- Throw read-only error for certain keys
            if k == "value"
            or k == "RAPI"
            or k == "properties"
            or k == "array" then
                log.error("Key '"..k.."' is read-only", 2)
            end

            -- Setter
            local index = content_class.Property[string_upper(k)]
            if index then
                local value = proxy[t]
                ---@type Array
                local properties = class_find_table[value].value.properties
                properties:set(index, v)
                return
            end
            log.error("Non-existent "..name_rapi.." property '"..k.."'", 2)
        end,

        __eq = function(t, other)
            return proxy[t] == proxy[other]
        end,

        __tostring = function(t)
            return name_rapi..": "..get_table_pointer(t)
        end,

        __metatable = mt_wrapper_name(name_rapi),
    }
end