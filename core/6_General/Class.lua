-- Class

--[[
Allows for accessing content class arrays via `Class.<class>`.
(E.g., `Class.Item`)
]]

Class = new_class()



-- ========== RAPI <-> Global name mapping ==========

-- Mappings for RAPI class name
-- to global name and vice versa
local file = toml.decodeFromFile(path.combine(PATH, "core/data/class_name_mapping.txt"))

local class_name_r2g = file.mapping   -- RAPI   -> Global
local class_name_g2r = {}             -- Global -> RAPI

for name_rapi, name_global in pairs(class_name_r2g) do
    class_name_g2r[name_global] = name_rapi
end



-- ========== Metatables ==========

local class_wrappers = {}

Class.internal.initialize = function()
    for name_rapi, name_global in pairs(class_name_r2g) do
        -- Populate class_wrappers on initialize
        -- since some content class arrays do not exist before then
        -- Wrap `class_*` in Array wrappers and store in `class_wrappers`
        class_wrappers[name_rapi:upper()] = Global[name_global]
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



-- ========== Find Caches ==========

-- Create class find caches
run_once(function()
    __class_find_caches = {}

    for name_global, _ in pairs(class_name_g2r) do
        __class_find_caches[name_global] = __class_find_caches[name_global] or FindCache.new()
    end
end)


-- Detect if new content is added and add to find cache
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
    local name_rapi   = class_name_g2r[hook[2]]
    local name_global = hook[2]

    gm.post_script_hook(hook[1], function(self, other, result, args)
        local namespace  = args[1].value
        local identifier = args[2].value
        local id         = result.value

        -- Add to find cache
        if namespace then
            __class_find_caches[name_global]:set(
                {
                    wrapper = __class[name_rapi].wrap(id),
                    array   = Global[name_global]:get(id),
                },
                identifier,
                namespace,
                id
            )
        end
    end)
end



-- ========== Class Base Implementations ==========

-- This file will also create the base implementations
-- for every class array, containing:
--      * Property      enum
--      * find          static method
--      * find_all      static method
--      * wrap          static method
--      * print         instance method
--      * Metatable for get/set properties
-- 
-- The variable for the class (e.g., `Item`)
-- will already be defined, so no need to write
-- `= new_class()` or anything in their files
-- 
-- Additionally, modify `methods_class[<RAPI name>]` for instance methods


-- Load property names from data
local file = toml.decodeFromFile(PATH.."core/data/class_array.txt")
local properties = file.array


-- Create new class table for every content class
methods_content_class = {}

for name_rapi, name_global in pairs(class_name_r2g) do
    local class_table = new_class()

    __class[name_rapi] = class_table
    private[name_rapi] = class_table    -- Define variable for internal use

    local metatable_name = "metatable_"..name_rapi


    -- Create enum `Property` from "class_array.txt"
    local enum = {}
    for k, v in pairs(properties[name_global]) do
        enum[k:upper()] = v -- e.g., Item.Property.NAMESPACE = 0
        enum[v] = k         -- e.g., Item.Property[0] = "namespace"; don't capitalize property name here
    end
    class_table.Property = enum


    -- `new` (placeholder)
    class_table.new = function(NAMESPACE, identifier)
        log.error(name_rapi..".new: Method has not been created for this class yet", 2)
    end


    -- `find`
    class_table.find = function(identifier, namespace, namespace_is_specified)
        local cached = __class_find_caches[name_global]:get(identifier, namespace, namespace_is_specified)
        if cached then return cached.wrapper end
    end


    -- `find_all`
    class_table.find_all = function(NAMESPACE, filter, property)
        property = property or 0    -- `namespace` filter by default

        -- Namespace filter
        if property == 0 then
            local namespace_is_specified = (filter ~= nil)
            filter = filter or NAMESPACE
            return __class_find_caches[name_global]:get_all(filter, namespace_is_specified, "wrapper")
        end


        -- Other filter (very slow!)
        local elements = {}
        local find_cache = __class_find_caches[name_global]

        for id = 0, #find_cache - 1 do
            local element_table = find_cache:get(id)
            if element_table.array:get(property) == filter then
                table.insert(elements, element_table.wrapper)
            end
        end

        return elements
    end


    -- `wrap`
    class_table.wrap = function(value)
        -- Input:   number
        -- Wraps:   number
        return make_proxy(Wrap.unwrap(value), private[metatable_name])
    end


    -- Instance methods
    methods_content_class[name_rapi] = {
        print = function(self)
            local array = __class_find_caches[name_global]:get(self.value).array
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
            if k == "array" then return __class_find_caches[name_global]:get(value).array end

            -- Methods
            local method = methods_content_class[name_rapi][k]
            if method then
                return method
            end

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
end



-- Public export
__class.Class = Class
__class_mt.Class = metatable_class