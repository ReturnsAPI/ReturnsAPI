-- Object

Object = new_class()

run_once(function()
    __object_tags = {}
    __object_wrapper_cache = {}
    __object_array_cache = {}
end)

local find_cache = {}



-- ========== Constants and Enums ==========

--$enum
Object.Property = ReadOnly.new({
    BASE        = 0,
    OBJ_DEPTH   = 1,
    OBJ_SPRITE  = 2,
    IDENTIFIER  = 3,
    NAMESPACE   = 4,
    ON_CREATE   = 5,
    ON_DESTROY  = 6,
    ON_STEP     = 7,
    ON_DRAW     = 8
})


--$enum
Object.Parent = ReadOnly.new({
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
})


Object.CUSTOM_START = 800



-- ========== Static Methods ==========

--$static
--$return   Object
--$param    identifier      | string    | The identifier for the object.
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
    obj = GM.object_add_w(
        namespace,
        identifier,
        Wrap.unwrap(parent)
    )

    -- Add to Cognition artifact blacklist
    Global.artifact_cognation_enemy_blacklist:set(obj, true)

    return Object.wrap(obj)
end


--$static
--$return       Object or nil
--$param        identifier  | string    | The identifier to search for.
--$optional     namespace   | string    | The namespace to search in.
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


Object.find_all = function()

end


--$static
--$return       table
--$param        tag         | string    | The tag to search by.
--[[
Returns a table of all objects with the specified tag.
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


Object.add_serializers = function(namespace, object, serializer, deserializer)
    -- Notes:
    -- Remove on hotload
    -- Write a note that the deserializer should read *everything* written in serialize,
    -- since it seems that all custom objects share the same packet
end


--$static
--$return       Object
--$param        object      | number    | The object index to wrap.
--[[
Returns an Object wrapper containing the provided object index.
]]
Object.wrap = function(object)
    -- Check cache
    if __object_wrapper_cache[object] then return __object_wrapper_cache[object] end

    local proxy = Proxy.new(Wrap.unwrap(object), metatable_object)
    __object_wrapper_cache[object] = proxy
    return proxy
end



-- ========== Instance Methods ==========

methods_object = {

    --$instance
    --$return       Instance
    --$param        x           | number    | The x spawn coordinate. <br>`0` by default.
    --$param        y           | number    | The y spawn coordinate. <br>`0` by default.
    --[[
    Creates and returns an instance of the specified object.

    Also exists as a $method of Instance, Instance#create$.
    ]]
    create = function(self, x, y)
        local holder = RValue.new_holder_scr(3)
        holder[0] = RValue.new(x or 0)
        holder[1] = RValue.new(y or 0)
        holder[2] = RValue.new(self.value)
        local out = RValue.new(0)
        gmf.instance_create(nil, nil, out, 3, holder)
        return RValue.to_wrapper(out)
    end,


    --$instance
    --$param        sprite      | sprite    | The sprite to set.
    --[[
    Sets the sprite of the object.
    ]]
    set_sprite = function(self, sprite)
        self.obj_sprite = sprite
        GM.object_set_sprite_w(self.value, sprite)
    end,


    --$instance
    --$param        depth       | number    | The depth to set.
    --[[
    Sets the depth of the object.
    ]]
    set_depth = function(self, depth)
        self.obj_depth = depth
        Global.object_depths:set(self.value, depth) -- Does not apply retroactively to existing instances
    end,


    --$instance
    --$param        tag         | string    | The tag to add.
    --[[
    Adds a tag to this object for easier lookup grouping.
    ]]
    add_tag = function(self, tag)
        if type(tag) ~= "string" then log.error("add_tag: tag must be a string", 2) end

        -- Create subtable if existn't
        if not __object_tags[tag] then __object_tags[tag] = { count = 0 } end

        -- Add to subtable
        __object_tags[tag][self.value] = self
        __object_tags[tag].count = __object_tags[tag].count + 1
    end,


    --$instance
    --$param        tag         | string    | The tag to remove.
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


    --$instance
    --$return       bool
    --$param        tag         | string    | The tag to check.
    --[[
    Returns `true` if this object has the specified tag.
    ]]
    has_tag = function(self, tag)
        if type(tag) ~= "string" then log.error("has_tag: tag must be a string", 2) end

        if not __object_tags[tag] then return false end
        if __object_tags[tag][self.value] then return true end
        return false
    end,


    --$instance
    --$return       table
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

make_table_once("metatable_object", {
    __index = function(proxy, k)
        -- Get wrapped value
        local value = Proxy.get(proxy)
        if k == "value" then return value end
        if k == "RAPI" then return getmetatable(proxy):sub(14, -1) end
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
        local value = Proxy.get(proxy)
        if value < Object.CUSTOM_START then log.error("No Object properties for vanilla objects", 2) end
        local index = Object.Property[k:upper()]
        if index then
            proxy.array:set(index, v)
            return
        end
        log.error("Non-existent Object property '"..k.."'", 2)
    end,

    
    __metatable = "RAPI.Wrapper.Object"
})



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