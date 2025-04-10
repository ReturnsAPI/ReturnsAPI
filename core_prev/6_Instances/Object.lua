-- Object

Object = new_class()

local find_cache = {}



-- ========== Constants and Enums ==========

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

Object.new = function(namespace, identifier, parent)
    Initialize.internal.check_if_done()
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

    -- Also search for object in "ror" and then gm.constants if no namespace arg
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


Object.wrap = function(object)
    return Proxy.new(Wrap.unwrap(object), metatable_object)
end



-- ========== Instance Methods ==========

methods_object = {

    create = function(self, x, y)
        local holder = RValue.new_holder_scr(3)
        holder[0] = RValue.new(x or 0)
        holder[1] = RValue.new(y or 0)
        holder[2] = RValue.new(self.value)
        local out = RValue.new(0)
        gmf.instance_create(nil, nil, out, 3, holder)
        return RValue.to_wrapper(out)
    end

}



-- ========== Metatables ==========

metatable_object = {
    __index = function(proxy, k)
        -- Get wrapped value
        local value = Proxy.get(proxy)
        if k == "value" then return value end
        if k == "RAPI" then return getmetatable(proxy):sub(14, -1) end

        -- Methods
        if methods_object[k] then
            return methods_object[k]
        end

        -- Getter
        if value < Object.CUSTOM_START then log.error("No object properties for vanilla objects", 2) end
        local index = Object.Property[k:upper()]
        if index then
            local obj_array = Global.custom_object:get(value - Object.CUSTOM_START)
            return obj_array:get(index)
        end
        log.error("Non-existent object property", 2)
        return nil
    end,


    __newindex = function(proxy, k, v)
        -- Setter
        local value = Proxy.get(proxy)
        if value < Object.CUSTOM_START then log.error("No object properties for vanilla objects", 2) end
        local index = Object.Property[k:upper()]
        if index then
            local obj_array = Global.custom_object:get(value - Object.CUSTOM_START)
            obj_array:set(index, v)
        end
        log.error("Non-existent object property", 2)
        return nil
    end,

    
    __metatable = "RAPI.Wrapper.Object"
}



__class.Object = Object