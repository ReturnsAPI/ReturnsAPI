-- Object

---@class ObjectClass
Object = new_class()
C.Object = Object

run_on_initial_load(function()
    P.object_find_table         = FindTable.new()
    P.object_tags               = {}    ---@type table<string, table<number, Object>> Maps tags -> hash tables of object indices that have the tag.
    P.object_vanilla_properties = {}    -- `.properties` but for vanilla objects

    -- __object_serializers = {}
    -- __object_deserializers = {}
end)

local object_find_table  = P.object_find_table
local object_tags        = P.object_tags
local vanilla_properties = P.object_vanilla_properties
local properties_cache   = {}   ---@type table<number, Array> Cache for `.properties`/`.array`

local proxy = P.proxy
local metatable

local type               = type
local gm                 = gm                   ---@type table<string, function>
local gm_instance_create = gm.instance_create   ---@type function
local gm_instance_exists = gm.instance_exists   ---@type function
local unwrap             = Wrap.unwrap
local check_init_started = Initialize.internal.check_if_started


-- ========== Constants and Enums ==========

Object.Property = {
    BASE        = 0,
    OBJ_DEPTH   = 1,
    OBJ_SPRITE  = 2,
    IDENTIFIER  = 3,
    NAMESPACE   = 4,
    ON_CREATE   = 5,
    ON_DESTROY  = 6,
    ON_STEP     = 7,
    ON_DRAW     = 8,
}

Object.Parent = {
    ACTOR               = gm.constants.pActor,
    ENEMY_CLASSIC       = gm.constants.pEnemyClassic,
    ENEMY_FLYING        = gm.constants.pEnemyFlying,
    BOSS                = gm.constants.pBoss,
    BOSS_CLASSIC        = gm.constants.pBossClassic,
    PICKUP_ITEM         = gm.constants.pPickupItem,
    PICKUP_EQUIPMENT    = gm.constants.pPickupEquipment,
    DRONE               = gm.constants.pDrone,
    MAP_OBJECTS         = gm.constants.pMapObjects,
    INTERACTABLE        = gm.constants.pInteractable,
    INTERACTABLE_CHEST  = gm.constants.pInteractableChest,
    INTERACTABLE_CRATE  = gm.constants.pInteractableCrate,
    INTERACTABLE_DRONE  = gm.constants.pInteractableDrone,
}

Object.CUSTOM_START = 900


-- ========== Internal ==========

local populate_find_table = function()
    -- Populate with vanilla objects
    -- (This iteration does include some custom objects
    -- added by the game, such as player scrap)
    local resource_manager = Map.wrap(Global.ResourceManager_object.__namespacedAssetLookup)
    
    for identifier, object in pairs(Map.wrap(resource_manager["ror"])) do
        object_find_table:set(Object.wrap(object), identifier, "ror")

        -- Create mock `.properties` tables for vanilla (non-custom) objects
        if object < Object.CUSTOM_START
        and not vanilla_properties[object] then
            vanilla_properties[object] = ReadOnly.new{
                nil,        -- base
                nil,        -- obj_depth    This is subject to change and should be fetched on demand
                nil,        -- obj_sprite   This is subject to change and should be fetched on demand
                identifier, -- identifier
                "ror",      -- namespace
                nil,        -- on_create
                nil,        -- on_destroy
                nil,        -- on_step
                nil,        -- on_draw
            }
        end
    end
end
run_on_initialize(populate_find_table)


-- ========== Static Methods ==========

--[[
Creates a new object with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the object.
---@param parent? number | Object The parent object to use as a base.
---@return Object
Object.new = function(NAMESPACE, identifier, parent)
    check_init_started("new")
    if not identifier then throw("No identifier provided", "new") end

    -- Return existing object if found
    local obj = Object.find(identifier, NAMESPACE, true)
    if obj then return obj end

    -- Create new object
    obj = gm.object_add_w(
        NAMESPACE,
        identifier,
        unwrap(parent)
    )

    -- Add to Cognition artifact blacklist
    ---@type Map
    local blacklist = Global.artifact_cognation_enemy_blacklist
    blacklist:set(obj, true)

    -- Add to deserialization map for online syncing
    ---@type Map
    local deserialize = Global.__mtd_deserialize
    deserialize:set(obj, gm.constants.__lf_init_multiplayer_globals_customobject_deserialize)

    -- Adding to find table is done in the hook at the bottom

    return Object.wrap(obj)
end

--[[
Searches for the specified object and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return Object | nil
Object.find = function(identifier, namespace, namespace_is_specified)
    return object_find_table:get(identifier, namespace, namespace_is_specified)
end

--[[
Returns a table of all objects in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
* Guaranteed to check in your mod's namespace first.
]]
---@param namespace? string The namespace to search in.
---@return table<number, Object>
Object.find_all = function(namespace, namespace_is_specified)
    return object_find_table:get_all(namespace, namespace_is_specified)
end

--[[
Returns a hash table of all objects with the specified tag, <br>
and the number of objects in the table.

Each key-value pair is `<object_index> = <Object wrapper>`.

ReturnsAPI-added tags:
- `"enemy_projectile"`
]]
---@param tag string The tag to search by.
---@return table<number, Object>, number
Object.find_all_by_tag = function(tag)
    local t = object_tags[tag]
    if not t then return {}, 0 end

    -- Return copy of tag subtable
    local copy = {}
    for k, v in pairs(t) do
        if k ~= "count" then copy[k] = v end
    end
    return copy, t.count
end

--@static
--@param        object          | Object    | The object to set for.
--@param        serializer      | function  | The serialization function.
--@param        deserializer    | function  | The deserialization function.
--[[
Adds serialization and deserialization functions
that run for instances of the object when syncing.

The arguments for each function should be `inst, buffer`.

Relevant functions (callable by host only):
- `inst:instance_sync()` - Initial setup (generally in `on_create`); creates new instance for clients
- `inst:instance_resync()` - Resync data
- `inst:projectile_sync(interval)` - Same as `instance_resync`, but with automatic periodic resync
- `inst:instance_destroy_sync()` - Sync destruction; place in `on_destroy`

**NOTE:** You *must* read all data you send in `serializer`,
as all object serializations share the same packet.
]]
-- TODO
-- Object.add_serializers = function(NAMESPACE, object, serializer, deserializer)
--     if not object                       then log.error("Object.add_serializers: Missing object argument", 2) end
--     if type(serializer)   ~= "function" then log.error("Object.add_serializers: serializer should be a function", 2) end
--     if type(deserializer) ~= "function" then log.error("Object.add_serializers: deserializer should be a function", 2) end

--     object = Wrap.unwrap(object)

--     if not __object_serializers[object] then __object_serializers[object] = {} end
--     table.insert(__object_serializers[object], {
--         namespace   = NAMESPACE,
--         fn          = serializer
--     })

--     if not __object_deserializers[object] then __object_deserializers[object] = {} end
--     table.insert(__object_deserializers[object], {
--         namespace   = NAMESPACE,
--         fn          = deserializer
--     })
-- end

--@static
--[[
Removes all registered serializers from your namespace.

Automatically called when you hotload your mod.
]]
-- TODO
-- Object.remove_all_serializers = function(NAMESPACE)
--     for object, subtable in pairs(__object_serializers) do
--         for i = #subtable, 1, -1 do
--             local fn_table = subtable[i]
--             if fn_table.namespace == NAMESPACE then
--                 table.remove(subtable, i)
--             end
--         end
--         if #subtable <= 0 then __object_serializers[object] = nil end
--     end

--     for object, subtable in pairs(__object_deserializers) do
--         for i = #subtable, 1, -1 do
--             local fn_table = subtable[i]
--             if fn_table.namespace == NAMESPACE then
--                 table.remove(subtable, i)
--             end
--         end
--         if #subtable <= 0 then __object_deserializers[object] = nil end
--     end
-- end
-- table.insert(_clear_namespace_functions, Object.remove_all_serializers)

--[[
Returns an Object wrapper containing the provided object index.
]]
---@param object number | Object The object index to wrap.
---@return Object
Object.wrap = function(object)
    return new_proxy(unwrap(object), metatable)
end


-- ========== Wrapper Methods ==========

---@class Object
local methods = {}

--[[
Creates and returns an instance of the object.
]]
---@param x? number The x spawn coordinate. <br>`0` by default.
---@param y? number The y spawn coordinate. <br>`0` by default.
---@return Instance
methods.create = function(self, x, y)
    return gm_instance_create(x or 0, y or 0, proxy[self])
end

--[[
Sets the sprite of the object.
]]
---@param sprite number | Sprite The sprite to set.
methods.set_sprite = function(self, sprite)
    if not sprite then throw("sprite not provided") end
    gm.object_set_sprite_w(proxy[self], unwrap(sprite))
end

--[[
Sets the initial depth for created instances of the object. <br>
Does not apply retroactively to existing instances.
]]
---@param depth number The depth to set.
methods.set_depth = function(self, depth)
    if type(depth) ~= "number" then throw("depth must be a number") end
    gm.object_set_depth(proxy[self], depth)
end

--[[
Adds a tag to this object. <br>
The purpose of this is to allow for easier lookup <br>
for groups of objects (see @link {`Object.find_all_by_tag` | Object#find_all_by_tag}).
]]
---@param tag string The tag to add.
methods.add_tag = function(self, tag)
    if tag == "count" then throw("'count' is reserved") end

    -- Create subtable if it does not exist
    local t = object_tags[tag]
    if not t then
        t = {count = 0}
        object_tags[tag] = t
    end

    -- Add to subtable
    local value = proxy[self]
    if t[value] then return end
    t[value] = self
    t.count = t.count + 1
end

--[[
Removes a tag from this object.
]]
---@param tag string The tag to remove.
methods.remove_tag = function(self, tag)
    if tag == "count" then throw("'count' is reserved") end

    local t = object_tags[tag]
    if not t then return end

    -- Remove from subtable
    local value = proxy[self]
    if not t[value] then return end
    t[value] = nil
    t.count = t.count - 1

    -- Delete subtable if there are no more objects
    if t.count <= 0 then object_tags[tag] = nil end
end

--[[
Returns `true` if this object has the specified tag.
]]
---@param tag string The tag to check.
---@return boolean
methods.has_tag = function(self, tag)
    if tag == "count" then throw("'count' is reserved") end

    local t = object_tags[tag]
    if not t then return false end

    if t[proxy[self]] then return true end
    return false
end

--[[
Returns a table of this object's tags.
]]
---@return table<number, string>
methods.get_tags = function(self)
    local value = proxy[self]
    local tags, i = {}, 1
    for tag, subtable in pairs(object_tags) do
        if subtable[value] then
            tags[i] = tag
            i = i + 1
        end
    end
    return tags
end


-- ========== Metatables ==========

---@class Object
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field properties Array | table The array storing this content's properties. <br>For vanilla objects, this is a Lua table.
---@field array Array | table Alias for `.properties`.

---@class Object
---@field base number The `object_index` of the "base" (parent) object used to create this one. <br>**Only exists for custom objects.**
---@field obj_depth number The object depth.
---@field obj_sprite number The object sprite ID.
---@field identifier string The identifier for the object within the namespace.
---@field namespace string The namespace the object is in.
---@field on_create number The ID of the callback that runs when an instance of the object is created. <br>The callback function should have the argument `inst`. <br>**Only exists for custom objects.**
---@field on_destroy number The ID of the callback that runs when an instance of the object is destroyed. <br>The callback function should have the argument `inst`. <br>**Only exists for custom objects.**
---@field on_step number The ID of the callback that runs every step for an instance of the object. <br>The callback function should have the argument `inst`. <br>**Only exists for custom objects.**
---@field on_draw number The ID of the callback that runs every step for an instance of the object (for drawing). <br>The callback function should have the argument `inst`. <br>**Only exists for custom objects.**

local mt_name = "Object"

W.Object = {
    ---@param t Object
    __index = function(t, k)
        -- Get wrapped value
        local value = proxy[t]
        if k == "value" then return value end
        if k == "RAPI" then return mt_name end
        if k == "properties"
        or k == "array" then
            -- Property table for vanilla objects
            if value < Object.CUSTOM_START then
                return vanilla_properties[value]
            end
            
            -- Check cache
            local array = properties_cache[value]
            if not array then
                ---@type Array
                array = Global.custom_object:get(value - Object.CUSTOM_START)
                properties_cache[value] = array
            end
            return array
        end

        -- Methods
        local method = methods[k]
        if method then return method end

        -- Getter
        local index = Object.Property[k:upper()]
        if index then
            if value < Object.CUSTOM_START then
                if index == Object.Property.OBJ_DEPTH  then return gm.object_get_depth(value) end
                if index == Object.Property.OBJ_SPRITE then return gm.object_get_sprite(value) end
                return vanilla_properties[value][index + 1]
            end
            return t.properties:get(index)
        end
        log.error("Non-existent Object property '"..k.."'", 2)
    end,

    ---@param t Object
    __newindex = function(t, k, v)
        -- Throw read-only error
        if k == "value"
        or k == "RAPI"
        or k == "properties"
        or k == "array" then
            log.error("Key '"..k.."' is read-only", 2)
        end
        
        -- Setter
        local value = proxy[t]
        local index = Object.Property[k:upper()]
        if index then
            if value < Object.CUSTOM_START then
                if     index == Object.Property.OBJ_DEPTH  then gm.object_set_depth(value, unwrap(v))
                elseif index == Object.Property.OBJ_SPRITE then gm.object_set_sprite(value, unwrap(v))
                else t.properties[index + 1] = v
                end
                return
            end
            t.properties:set(index, v)
            return
        end
        log.error("Non-existent Object property '"..k.."'", 2)
    end,

    ---@param t Object
    __tostring = function(t)
        return mt_name..": "..get_table_pointer(t)
    end,
    
    __metatable = mt_wrapper_name(mt_name),
}
metatable = W.Object


-- ========== Hooks ==========

-- Add new objects to find table
gm.post_script_hook(gm.constants.object_add_w, function(self, other, result, args)
    local id = result.value
    if id == -1 then return end

    object_find_table:set(
        Object.wrap(id),
        args[2].value,  -- identifier
        args[1].value   -- namespace
    )
end)

-- TODO
-- gm.post_script_hook(gm.constants.__lf_init_multiplayer_globals_customobject_serialize, function(self, other, result, args)
--     local index = self.__object_index
--     local subtable = __object_serializers[index]
-- 	if subtable then
--         local inst = Instance.wrap(self)
--         local buffer = Buffer.wrap(Global.multiplayer_buffer)
--         for _, fn_table in ipairs(subtable) do
--             local status, err = pcall(fn_table.fn, inst, buffer)
--             if not status then
--                 if (err == nil)
--                 or (err == "C++ exception") then err = "GameMaker error (see above)" end
--                 log.warning("\n"..fn_table.namespace..": Object serialization for object '"..index.."' failed to execute fully.\n"..err)
--             end
--         end
-- 	end
-- end)

-- TODO
-- gm.post_script_hook(gm.constants.__lf_init_multiplayer_globals_customobject_deserialize, function(self, other, result, args)
--     local index = self.__object_index
--     local subtable = __object_deserializers[index]
-- 	if subtable then
--         local inst = Instance.wrap(self)
--         local buffer = Buffer.wrap(Global.multiplayer_buffer)
--         for _, fn_table in ipairs(subtable) do
--             local status, err = pcall(fn_table.fn, inst, buffer)
--             if not status then
--                 if (err == nil)
--                 or (err == "C++ exception") then err = "GameMaker error (see above)" end
--                 log.warning("\n"..fn_table.namespace..": Object deserialization for object '"..index.."' failed to execute fully.\n"..err)
--             end
--         end
-- 	end
-- end)


-- ========== Assign some object tags ==========

run_on_initial_load(function()
    
    -- enemy_projectile
    for _, index in ipairs{
        gm.constants.oJellyMissile,
        gm.constants.oWurmMissile,
        gm.constants.oShamBMissile,
        gm.constants.oTurtleMissile,
        gm.constants.oBrambleBullet,
        gm.constants.oLizardRSpear,
        gm.constants.oEfMissileEnemy,
        gm.constants.oSpiderBulletNoSync,       gm.constants.oSpiderBullet,
        gm.constants.oGuardBulletNoSync,        gm.constants.oGuardBullet,
        gm.constants.oBugBulletNoSync,          gm.constants.oBugBullet,
        gm.constants.oScavengerBulletNoSync,    gm.constants.oScavengerBullet,
    } do
        Object.wrap(index):add_tag("enemy_projectile")
    end
end)