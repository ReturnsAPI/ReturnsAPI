-- Object

Object = new_class()

local find_cache = {}   -- Stores object IDs, not wrappers



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
    
end


Object.find = function(identifier, namespace, default_namespace)
    local nsid = namespace.."-"..identifier

    -- Check in cache
    local cached_id = find_cache[nsid]
    if cached_id then return Object.wrap(cached_id) end

    -- Search in namespace
    local object = gm.object_find(nsid)
    if object then
        find_cache[nsid] = object
        return Object.wrap(object)
    end

    -- Also search for object in "ror" and then gm.constants if no namespace arg
    if namespace == default_namespace then
        local object = gm.object_find("ror-"..identifier)
        if object then
            find_cache[nsid] = object
            return Object.wrap(object)
        end

        local object = gm.constants["o"..identifier:sub(1, 1):upper()..identifier:sub(2, -1)]
        if object then
            find_cache[nsid] = object
            return Object.wrap(object)
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
        local inst = gm.instance_create(x or 0, y or 0, self.value)
        return Instance.internal.wrap(inst)
    end

}



-- ========== Metatables ==========

metatable_object = {
    __index = function(t, k)
        -- Get wrapped value
        local value = Proxy.get(t)
        if k == "value" then return value end
        if k == "RAPI" then return getmetatable(t):sub(14, -1) end

        -- Methods
        if methods_object[k] then
            return methods_object[k]
        end

        -- Getter
        if value < Object.CUSTOM_START then log.error("No object properties for vanilla objects", 2) end
        local index = Object.Property[k:upper()]
        if index then
            local custom_object = Array.wrap(gm.variable_global_get("custom_object"))
            local obj_array = custom_object:get(value - Object.CUSTOM_START)
            return obj_array:get(index)
        end
        log.error("Non-existent object property", 2)
        return nil
    end,


    __newindex = function(t, k, v)
        -- Setter
        local value = Proxy.get(t)
        if value < Object.CUSTOM_START then log.error("No object properties for vanilla objects", 2) end
        local index = Object.Property[k:upper()]
        if index then
            local custom_object = Array.wrap(gm.variable_global_get("custom_object"))
            local obj_array = custom_object:get(value - Object.CUSTOM_START)
            obj_array:set(index, v)
        end
        log.error("Non-existent object property", 2)
        return nil
    end,

    
    __metatable = "RAPI.Wrapper.Object"
}



_CLASS["Object"] = Object