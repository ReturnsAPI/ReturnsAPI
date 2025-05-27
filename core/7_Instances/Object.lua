-- Object

--[[
This class provides some functionality for manipulating GameMaker objects.
]]

Object = new_class()

run_once(function()
    __object_wrapper_cache = {}
    __object_array_cache = {}

    __object_tags = {}

    __object_serializers = {}
    __object_deserializers = {}
end)

local find_cache = {}



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
CUSTOM_START    800
]]
Object.CUSTOM_START = 800



-- ========== Properties ==========

--@section Properties

--[[
These properties only exist for custom objects.

Property | Type | Description
| - | - | -
`base`          | number    | The object_index of the parent object.
`obj_depth`     | number    | The object depth.
`obj_sprite`    | sprite    | The object sprite.
`identifier`    | string    | The identifier for the object within the namespace.
`namespace`     | string    | The namespace the object is in.
`on_create`     | number    | The ID of the callback that runs when an instance of the object is created.
`on_destroy`    | number    | The ID of the callback that runs when an instance of the object is destroyed.
`on_step`       | number    | The ID of the callback that runs every step for an instance of the object.
`on_draw`       | number    | The ID of the callback that runs every step for an instance of the object (for drawing).
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
Object.new = function(namespace, identifier, parent)
    Initialize.internal.check_if_started()
    if not identifier then log.error("No identifier provided", 2) end

    -- Return existing object if found
    local obj = Object.find(identifier, namespace)
    if obj then return obj end

    -- Create new object
    obj = gm.object_add_w(
        namespace,
        identifier,
        Wrap.unwrap(parent)
    )

    -- Add to Cognition artifact blacklist
    Global.artifact_cognation_enemy_blacklist:set(obj, true)

    -- Add to deserialization map for onlne syncing
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
Object.find = function(identifier, namespace, default_namespace)
    local namespace, is_specified = parse_optional_namespace(namespace, default_namespace)

    local nsid = namespace.."-"..identifier
    local ror_nsid = "ror-"..identifier

    -- Check in cache (both mod namespace and "ror")
    local cached = find_cache[nsid]
    if cached then return cached end
    if not is_specified then
        local cached = find_cache[ror_nsid]
        if cached then return cached end
    end

    -- Search in namespace
    local holder = RValue.new_holder_scr(1)
    holder[0] = RValue.new(nsid)
    local out = RValue.new(0)
    gmf.object_find(nil, nil, out, 1, holder)
    local object = RValue.to_wrapper(out)
    if object then
        object = Object.wrap(object)
        find_cache[nsid] = object
        return object
    end

    -- Also search in "ror" and then gm.constants if passed no `namespace` arg
    if not is_specified then
        local holder = RValue.new_holder_scr(1)
        holder[0] = RValue.new(ror_nsid)
        local out = RValue.new(0)
        gmf.object_find(nil, nil, out, 1, holder)
        local object = RValue.to_wrapper(out)
        if object then
            object = Object.wrap(object)
            find_cache[ror_nsid] = object
            return object
        end

        local object = gm.constants["o"..identifier:sub(1, 1):upper()..identifier:sub(2, -1)]
        if object then
            object = Object.wrap(object)
            find_cache[ror_nsid] = object
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
Object.find_by_tag = function(tag)
    if type(tag) ~= "string" then log.error("Object.find_by_tag: tag must be a string", 2) end

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
Adds serialization and deserialization functions for the object.
The arguments for each are `self, buffer`.

Relevant functions:
- `instance_sync()` - Initial setup (generally in `on_create`); creates new instance for clients
- `instance_resync()` - Resync data
- `projectile_sync(interval)` - Same as `instance_resync`, but with automatic periodic resync
- `instance_destroy_sync` - Sync destruction

**NOTE:** You must read all data you send in `serializer`,
as all object serializations share the same packet.
]]
Object.add_serializers = function(namespace, object, serializer, deserializer)
    if not object                       then log.error("Object.add_serializers: Missing object argument", 2) end
    if type(serializer)   ~= "function" then log.error("Object.add_serializers: serializer should be a function", 2) end
    if type(deserializer) ~= "function" then log.error("Object.add_serializers: deserializer should be a function", 2) end

    object = Wrap.unwrap(object)

    if not __object_serializers[object] then __object_serializers[object] = {} end
    table.insert(__object_serializers[object], {
        namespace   = namespace,
        fn          = serializer
    })

    if not __object_deserializers[object] then __object_deserializers[object] = {} end
    table.insert(__object_deserializers[object], {
        namespace   = namespace,
        fn          = deserializer
    })
end


--@static
--[[
Removes all registered serializers from your namespace.

Automatically called when you hotload your mod.
]]
Object.remove_all_serializers = function(namespace)
    for object, subtable in pairs(__object_serializers) do
        for i = #subtable, 1, -1 do
            local fn_table = subtable[i]
            if fn_table.namespace == namespace then
                table.remove(subtable, i)
            end
        end
        if #subtable <= 0 then __object_serializers[object] = nil end
    end

    for object, subtable in pairs(__object_deserializers) do
        for i = #subtable, 1, -1 do
            local fn_table = subtable[i]
            if fn_table.namespace == namespace then
                table.remove(subtable, i)
            end
        end
        if #subtable <= 0 then __object_deserializers[object] = nil end
    end
end


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
    --@param        x           | number    | The x spawn coordinate. <br>`0` by default.
    --@param        y           | number    | The y spawn coordinate. <br>`0` by default.
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
        sprite = Wrap.unwrap(sprite)
        if self.value >= Object.CUSTOM_START then self.obj_sprite = sprite end
        GM.object_set_sprite_w(self, sprite)
    end,


    --@instance
    --@param        depth       | number    | The depth to set.
    --[[
    Sets the depth of the object.
    ]]
    set_depth = function(self, depth)
        if self.value >= Object.CUSTOM_START then self.obj_depth = depth end
        Global.object_depths:set(self.value, depth) -- Does not apply retroactively to existing instances
    end,


    --@instance
    --@param        tag         | string    | The tag to add.
    --[[
    Adds a tag to this object.
    The purpose of this is to allow for easier lookup
    for groups of objects (see @link {`Object.find_by_tag` | Object#find_by_tag}).
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
            if value < Object.CUSTOM_START then log.error("No Object properties for vanilla objects", 2) end
            
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
        if value < Object.CUSTOM_START then log.error("No Object properties for vanilla objects", 2) end
        local index = Object.Property[k:upper()]
        if index then
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
        if value < Object.CUSTOM_START then log.error("No Object properties for vanilla objects", 2) end
        local index = Object.Property[k:upper()]
        if index then
            proxy.array:set(index, v)
            return
        end
        log.error("Non-existent Object property '"..k.."'", 2)
    end,

    
    __metatable = "RAPI.Wrapper."..wrapper_name
})



-- ========== Hooks ==========

memory.dynamic_hook("RAPI.Object.serialize", "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.__lf_init_multiplayer_globals_customobject_serialize),
    -- Pre-hook
    {nil,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
        print("run serialize!")   -- DEBUG
        local inst = Instance.wrap(ffi.cast(__struct_cinstance, self:get_address()).id)
        local obj_ind = inst:get_object_index()
        local subtable = __object_serializers[obj_ind]
        print(obj_ind)   -- DEBUG
        if subtable then
            local buffer = Buffer.wrap(Global.multiplayer_buffer)
            for _, fn_table in ipairs(subtable) do
                local status, err = pcall(fn_table.fn, inst, buffer)
                if not status then
                    log.warning("\n"..fn_table.namespace:gsub("%.", "-")..": Object serialization for object '"..obj_ind.."' failed to execute fully.\n"..err)
                end
            end
        end
    end}
)


memory.dynamic_hook("RAPI.Object.deserialize", "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.__lf_init_multiplayer_globals_customobject_deserialize),
    -- Pre-hook
    {nil,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
        print("run deserialize!")   -- DEBUG
        local inst = Instance.wrap(ffi.cast(__struct_cinstance, self:get_address()).id)
        local obj_ind = inst:get_object_index()
        local subtable = __object_deserializers[obj_ind]
        print(obj_ind)   -- DEBUG
        if subtable then
            local buffer = Buffer.wrap(Global.multiplayer_buffer)
            for _, fn_table in ipairs(subtable) do
                local status, err = pcall(fn_table.fn, inst, buffer)
                if not status then
                    log.warning("\n"..fn_table.namespace:gsub("%.", "-")..": Object deserialization for object '"..obj_ind.."' failed to execute fully.\n"..err)
                end
            end
        end
    end}
)



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