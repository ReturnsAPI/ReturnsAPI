-- Object

--[[
This class provides some functionality for manipulating GameMaker objects.
]]

Object = new_class()

run_once(function()
    __object_wrapper_cache = {}
    __object_array_cache = {}

    __object_tags = {}
    __object_vanilla_properties = {}    -- Object.Property table but for vanilla objects

    __object_serializers = {}
    __object_deserializers = {}
end)

local find_cache = FindCache.new()



-- ========== Constants and Enums ==========

--@section Enums

--@enum
Object.Property = {
    BASE        = 0,
    OBJ_DEPTH   = 1,
    OBJ_SPRITE  = 2,
    IDENTIFIER  = 3,
    NAMESPACE   = 4,
    ON_CREATE   = 5,
    ON_DESTROY  = 6,
    ON_STEP     = 7,
    ON_DRAW     = 8
}


--@enum
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
    INTERACTABLE_DRONE  = gm.constants.pInteractableDrone
}


--@constants
--[[
CUSTOM_START    900
]]
Object.CUSTOM_START = 900



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The `object_index` of the object.
`RAPI`          | string    | *Read-only.* The wrapper name.
`array`         | Array     | *Read-only.* The object property array.

<br>

Property | Type | Description
| - | - | -
`base`          | number    | The `object_index` of the "base" object used to create this one. <br>Only exists for custom objects.
`obj_depth`     | number    | The object depth.
`obj_sprite`    | sprite    | The object sprite ID.
`identifier`    | string    | The identifier for the object within the namespace.
`namespace`     | string    | The namespace the object is in.
`on_create`     | number    | The ID of the callback that runs when an instance of the object is created. <br>The callback function should have the argument `inst`. <br>**Only exists for custom objects.**
`on_destroy`    | number    | The ID of the callback that runs when an instance of the object is destroyed. <br>The callback function should have the argument `inst`. <br>**Only exists for custom objects.**
`on_step`       | number    | The ID of the callback that runs every step for an instance of the object. <br>The callback function should have the argument `inst`. <br>**Only exists for custom objects.**
`on_draw`       | number    | The ID of the callback that runs every step for an instance of the object (for drawing). <br>The callback function should have the argument `inst`. <br>**Only exists for custom objects.**
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return   Object
--@param    identifier      | string    | The identifier for the object.
--[[
Creates a new object with the given identifier if it does not already exist,
or returns the existing one if it does.
]]
Object.new = function(NAMESPACE, identifier, parent)
    Initialize.internal.check_if_started("Object.new")
    if not identifier then log.error("Object.new: No identifier provided", 2) end

    -- Return existing object if found
    local obj = Object.find(identifier, NAMESPACE)
    if obj then return obj end

    -- Create new object
    obj = gm.object_add_w(
        NAMESPACE,
        identifier,
        Wrap.unwrap(parent)
    )

    -- Add to Cognition artifact blacklist
    Global.artifact_cognation_enemy_blacklist:set(obj, true)

    -- Add to deserialization map for online syncing
    Global.__mtd_deserialize:set(obj, gm.constants.__lf_init_multiplayer_globals_customobject_deserialize)

    return Object.wrap(obj)
end


--@static
--@return       Object or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified object and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]
Object.find = function(identifier, namespace, namespace_is_specified)
    -- Check in cache
    local cached = find_cache:get(identifier, namespace, namespace_is_specified)
    if cached then return cached end

    -- Search in namespace
    local object = gm._mod_object_find(identifier, namespace)
    if object ~= -1 then
        object = Object.wrap(object)
        find_cache:set(object, identifier, namespace)
        return object
    end

    -- Also search in "ror" and then gm.constants if passed no `namespace` arg
    if not namespace_is_specified then
        local object = gm._mod_object_find(identifier, "ror")
        if object ~= -1 then
            object = Object.wrap(object)
            find_cache:set(object, identifier, "ror")
            return object
        end

        local object = gm.constants["o"..identifier:sub(1, 1):upper()..identifier:sub(2, -1)]
        if object then
            object = Object.wrap(object)
            find_cache:set(object, identifier, "ror")
            return object
        end
    end

    return nil
end


--@static
--@return       table, number
--@param        tag         | string    | The tag to search by.
--[[
Returns a key-value pair table of all objects with the specified tag,
and the number of objects in the table.

Each key-value pair is `object_index, Object wrapper`.
]]
Object.find_all_by_tag = function(tag)
    if type(tag) ~= "string" then log.error("Object.find_all_by_tag: tag must be a string", 2) end

    -- Check if tag subtable exists
    local subtable = __object_tags[tag]
    if not subtable then return {}, 0 end

    -- Return copy of tag subtable
    local copy = {}
    for k, v in pairs(subtable) do
        if k ~= "count" then copy[k] = v end
    end
    return copy, subtable.count
end


--@static
--@param        object          | Object    | The object to set for.
--@param        serializer      | function  | The serialization function.
--@param        deserializer    | function  | The deserialization function.
--[[
Adds serialization and deserialization functions
that run for instances of the object when syncing.

The arguments for each function should be `inst, buffer`.

Relevant functions:
- `inst:instance_sync()` - Initial setup (generally in `on_create`); creates new instance for clients
- `inst:instance_resync()` - Resync data
- `inst:projectile_sync(interval)` - Same as `instance_resync`, but with automatic periodic resync
- `inst:instance_destroy_sync()` - Sync destruction; place in `on_destroy` (host only)

**NOTE:** You *must* read all data you send in `serializer`,
as all object serializations share the same packet.
]]
Object.add_serializers = function(NAMESPACE, object, serializer, deserializer)
    if not object                       then log.error("Object.add_serializers: Missing object argument", 2) end
    if type(serializer)   ~= "function" then log.error("Object.add_serializers: serializer should be a function", 2) end
    if type(deserializer) ~= "function" then log.error("Object.add_serializers: deserializer should be a function", 2) end

    object = Wrap.unwrap(object)

    if not __object_serializers[object] then __object_serializers[object] = {} end
    table.insert(__object_serializers[object], {
        namespace   = NAMESPACE,
        fn          = serializer
    })

    if not __object_deserializers[object] then __object_deserializers[object] = {} end
    table.insert(__object_deserializers[object], {
        namespace   = NAMESPACE,
        fn          = deserializer
    })
end


--@static
--[[
Removes all registered serializers from your namespace.

Automatically called when you hotload your mod.
]]
Object.remove_all_serializers = function(NAMESPACE)
    for object, subtable in pairs(__object_serializers) do
        for i = #subtable, 1, -1 do
            local fn_table = subtable[i]
            if fn_table.namespace == NAMESPACE then
                table.remove(subtable, i)
            end
        end
        if #subtable <= 0 then __object_serializers[object] = nil end
    end

    for object, subtable in pairs(__object_deserializers) do
        for i = #subtable, 1, -1 do
            local fn_table = subtable[i]
            if fn_table.namespace == NAMESPACE then
                table.remove(subtable, i)
            end
        end
        if #subtable <= 0 then __object_deserializers[object] = nil end
    end
end
table.insert(_clear_namespace_functions, Object.remove_all_serializers)


--@static
--@return       Object
--@param        object      | number    | The object index to wrap.
--[[
Returns an Object wrapper containing the provided object index.
]]
Object.wrap = function(object)
    -- Check cache
    if __object_wrapper_cache[object] then return __object_wrapper_cache[object] end

    local proxy = make_proxy(Wrap.unwrap(object), metatable_object)
    __object_wrapper_cache[object] = proxy
    return proxy
end



-- ========== Instance Methods ==========

--@section Instance Methods

methods_object = {

    --@instance
    --@return       Instance
    --@optional     x           | number    | The x spawn coordinate. <br>`0` by default.
    --@optional     y           | number    | The y spawn coordinate. <br>`0` by default.
    --[[
    Creates and returns an instance of the specified object.

    Also exists as a @link {method of Instance | Instance#create}.
    ]]
    create = function(self, x, y)
        return Instance.wrap(gm.instance_create(Wrap.unwrap(x) or 0, Wrap.unwrap(y) or 0, self.value).id)
    end,


    --@instance
    --@param        sprite      | sprite    | The sprite to set.
    --[[
    Sets the sprite of the object.
    ]]
    set_sprite = function(self, sprite)
        if not sprite then log.error("set_sprite: sprite not provided", 2) end
        gm.object_set_sprite_w(self.value, Wrap.unwrap(sprite))
    end,


    --@instance
    --@param        depth       | number    | The depth to set.
    --[[
    Sets the initial depth for created instances of the object.
    Does not apply retroactively to existing instances.
    ]]
    set_depth = function(self, depth)
        if type(depth) ~= "number" then log.error("set_depth: depth must be a number", 2) end
        gm.object_set_depth(self.value, depth)
    end,


    --@instance
    --@param        tag         | string    | The tag to add.
    --[[
    Adds a tag to this object.
    The purpose of this is to allow for easier lookup
    for groups of objects (see @link {`Object.find_all_by_tag` | Object#find_all_by_tag}).
    ]]
    add_tag = function(self, tag)
        if type(tag) ~= "string" then log.error("add_tag: tag must be a string", 2) end

        -- Create subtable if existn't
        if not __object_tags[tag] then __object_tags[tag] = { count = 0 } end

        -- Add to subtable
        __object_tags[tag][self.value] = self
        __object_tags[tag].count = __object_tags[tag].count + 1
    end,


    --@instance
    --@param        tag         | string    | The tag to remove.
    --[[
    Removes a tag from this object.
    ]]
    remove_tag = function(self, tag)
        if type(tag) ~= "string" then log.error("remove_tag: tag must be a string", 2) end
        if not __object_tags[tag] then return end

        -- Remove from subtable
        __object_tags[tag][self.value] = nil
        __object_tags[tag].count = __object_tags[tag].count - 1

        -- Delete subtable if there are no more objects
        if __object_tags[tag].count <= 0 then __object_tags[tag] = nil end
    end,


    --@instance
    --@return       bool
    --@param        tag         | string    | The tag to check.
    --[[
    Returns `true` if this object has the specified tag.
    ]]
    has_tag = function(self, tag)
        if type(tag) ~= "string" then log.error("has_tag: tag must be a string", 2) end

        if not __object_tags[tag] then return false end
        if __object_tags[tag][self.value] then return true end
        return false
    end,


    --@instance
    --@return       table
    --[[
    Returns a table of this object's tags.
    ]]
    get_tags = function(self)
        local tags = {}
        for tag, subtable in pairs(__object_tags) do
            if subtable[self.value] then table.insert(tags, tag) end
        end
        return tags
    end

}



-- ========== Metatables ==========

local wrapper_name = "Object"

make_table_once("metatable_object", {
    __index = function(proxy, k)
        -- Get wrapped value
        local value = __proxy[proxy]
        if k == "value" then return value end
        if k == "RAPI" then return wrapper_name end
        if k == "array" then
            if value < Object.CUSTOM_START then
                -- Custom object property table for vanilla objects
                if not __object_vanilla_properties[value] then
                    local name = gm.object_get_name(value)
                    name = name:sub(2, 2):lower()..name:sub(3, -1)  -- e.g., oLizard -> lizard

                    __object_vanilla_properties[value] = {
                        nil,    -- base
                        nil,    -- obj_depth    This is subject to change and should be fetched on demand
                        nil,    -- obj_sprite   This is subject to change and should be fetched on demand
                        name,   -- identifier
                        "ror",  -- namespace
                        nil,    -- on_create
                        nil,    -- on_destroy
                        nil,    -- on_step
                        nil     -- on_draw
                    }
                end

                return __object_vanilla_properties[value]
            end
            
            -- Check cache
            local array = __object_array_cache[value]
            if not array then
                array = Global.custom_object:get(value - Object.CUSTOM_START)
                __object_array_cache[value] = array
            end

            return array
        end

        -- Methods
        if methods_object[k] then
            return methods_object[k]
        end

        -- Getter
        local index = Object.Property[k:upper()]
        if index then
            if value < Object.CUSTOM_START then
                if (index == Object.Property.OBJ_DEPTH)     then return gm.object_get_depth(value) end
                if (index == Object.Property.OBJ_SPRITE)    then return gm.object_get_sprite(value) end
                return proxy.array[index + 1]
            end
            return proxy.array:get(index)
        end
        log.error("Non-existent Object property '"..k.."'", 2)
    end,


    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end
        
        -- Setter
        local value = __proxy[proxy]
        local index = Object.Property[k:upper()]
        if index then
            if value < Object.CUSTOM_START then
                if      (index == Object.Property.OBJ_DEPTH)    then gm.object_set_depth(value, Wrap.unwrap(v))
                elseif  (index == Object.Property.OBJ_SPRITE)   then gm.object_set_sprite(value, Wrap.unwrap(v))
                else proxy.array[index + 1] = v
                end
                return
            end
            proxy.array:set(index, v)
            return
        end
        log.error("Non-existent Object property '"..k.."'", 2)
    end,

    
    __metatable = "RAPI.Wrapper."..wrapper_name
})



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.__lf_init_multiplayer_globals_customobject_serialize, function(self, other, result, args)
    local index = self.__object_index
    local subtable = __object_serializers[index]
	if subtable then
        local inst = Instance.wrap(self)
        local buffer = Buffer.wrap(Global.multiplayer_buffer)
        for _, fn_table in ipairs(subtable) do
            local status, err = pcall(fn_table.fn, inst, buffer)
            if not status then
                if (err == nil)
                or (err == "C++ exception") then err = "GameMaker error (see above)" end
                log.warning("\n"..fn_table.namespace..": Object serialization for object '"..index.."' failed to execute fully.\n"..err)
            end
        end
	end
end)


gm.post_script_hook(gm.constants.__lf_init_multiplayer_globals_customobject_deserialize, function(self, other, result, args)
    local index = self.__object_index
    local subtable = __object_deserializers[index]
	if subtable then
        local inst = Instance.wrap(self)
        local buffer = Buffer.wrap(Global.multiplayer_buffer)
        for _, fn_table in ipairs(subtable) do
            local status, err = pcall(fn_table.fn, inst, buffer)
            if not status then
                if (err == nil)
                or (err == "C++ exception") then err = "GameMaker error (see above)" end
                log.warning("\n"..fn_table.namespace..": Object deserialization for object '"..index.."' failed to execute fully.\n"..err)
            end
        end
	end
end)



-- ========== Assign some object tags ==========

run_once(function()

    -- enemy_projectile
    local t = {
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
    }
    for _, obj_id in ipairs(t) do
        Object.wrap(obj_id):add_tag("enemy_projectile")
    end
    
end)



-- Public export
__class.Object = Object