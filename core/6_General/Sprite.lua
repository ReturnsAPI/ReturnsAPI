-- Sprite

Sprite = new_class()

local find_cache = FindCache.new()



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       Sprite
--@param        identifier      | string    | The identifier for the sprite.
--@param        path            | string    | The file path to the sprite. <br>`~` expands to your mod folder.
--@optional     image_number    | number    | The number of subimages. <br>`1` by default.
--@optional     x_origin        | number    | The x coordinate of the origin (offset). <br>`0` by default.
--@optional     y_origin        | number    | The y coordinate of the origin (offset). <br>`0` by default.
--[[
Creates a new sprite with the given identifier if it does not already exist,
or returns the existing one if it does.
]]
Sprite.new = function(NAMESPACE, identifier, path, image_number, x_origin, y_origin)
    Initialize.internal.check_if_started("Sprite.new")
    if not identifier then log.error("Sprite.new: No identifier provided", 2) end
    if not path then log.error("Sprite.new: No image path provided", 2) end

    path = expand_path(NAMESPACE, path)

    -- Return existing sprite if found
    local sprite = Sprite.find(identifier, NAMESPACE, NAMESPACE)
    if sprite then
        -- Allow for modification of sprite origin
        if x_origin and y_origin then sprite:set_origin(x_origin, y_origin) end
        return sprite
    end

    -- Create new sprite
    sprite = gm.sprite_add_w(
        NAMESPACE,
        identifier,
        path,
        image_number or 1,
        x_origin or 0,
        y_origin or 0
    )

    if sprite == -1 then
        log.error("Sprite.new: Could not load sprite at '"..path.."'", 2)
    end

    return Sprite.wrap(sprite)
end


--@static
--@return       Sprite or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified sprite and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]
Sprite.find = function(identifier, namespace, namespace_is_specified)
    -- Check in cache
    local cached = find_cache:get(identifier, namespace, namespace_is_specified)
    if cached then return cached end

    -- Search in namespace
    local sprite
    local resource_manager = Map.wrap(Global.ResourceManager_sprite.__namespacedAssetLookup)
    local namespace_map = resource_manager[namespace]
    if namespace_map then sprite = Map.wrap(namespace_map)[identifier] end

    if sprite then
        sprite = Sprite.wrap(sprite)
        find_cache:set(sprite, identifier, namespace)
        return sprite
    end

    -- Also search in "ror" namespace if passed no `namespace` arg
    if not namespace_is_specified then
        local sprite
        local namespace_map = resource_manager["ror"]
        if namespace_map then sprite = Map.wrap(namespace_map)[identifier] end
        
        if sprite then
            sprite = Sprite.wrap(sprite)
            find_cache:set(sprite, identifier, "ror")
            return sprite
        end
    end

    return nil
end


--@static
--@return       table
--@optional     namespace   | string    | The namespace to check.
--[[
Returns a table of all sprites in the specified namespace.
If no namespace is provided, retrieves from both your mod's namespace and "ror".
]]
Sprite.find_all = function(namespace, namespace_is_specified)
    local sprites = {}
    local resource_manager = Map.wrap(Global.ResourceManager_sprite.__namespacedAssetLookup)

    -- Search in namespace
    if resource_manager[namespace] then
        for identifier, sprite in pairs(Map.wrap(resource_manager[namespace])) do
            sprite = Sprite.wrap(sprite)
            table.insert(sprites, sprite)
            find_cache:set(sprite, identifier, namespace)
        end
    end

    -- Also search in "ror" namespace if passed no `namespace` arg
    if not namespace_is_specified then
        for identifier, sprite in pairs(Map.wrap(resource_manager["ror"])) do
            sprite = Sprite.wrap(sprite)
            table.insert(sprites, sprite)
            find_cache:set(sprite, identifier, "ror")
        end
    end
    
    return sprites
end


--@static
--@return       Sprite
--@param        sprite      | number    | The sprite ID to wrap.
--[[
Returns a Sprite wrapper containing the provided sprite ID.
]]
Sprite.wrap = function(sprite)
    -- Input:   number or Sprite wrapper
    -- Wraps:   number
    return make_proxy(Wrap.unwrap(sprite), metatable_sprite)
end



-- ========== Instance Methods ==========

--@section Instance Methods

methods_sprite = {

    --@instance
    --@optional     x_origin    | number    | The x coordinate of the origin (offset). <br>`0` by default.
    --@optional     y_origin    | number    | The y coordinate of the origin (offset). <br>`0` by default.
    --[[
    Sets the origin of the sprite.
    Resets unspecified coordinates to `0`.
    ]]
    set_origin = function(self, x_origin, y_origin)
        gm.sprite_set_offset(self.value, x_origin or 0, y_origin or 0)
    end,


    --@instance
    --@param        speed       | number    | The animation speed, in "sprite frames per game frame".
    --[[
    Sets the animation speed of the sprite.
    ]]
    set_speed = function(self, speed)
        gm.sprite_set_speed(self.value, speed, 1)   -- Using `spritespeed_framespergameframe` (1)
    end,


    --@instance
    --@param        bbox_left   | number    | The left x.
    --@param        bbox_top    | number    | The top y.
    --@param        bbox_right  | number    | The right x.
    --@param        bbox_bottom | number    | The bottom y.
    --[[
    Sets the collision mask of the sprite, relative to the top-left corner (0, 0).

    E.g., For a 16x16 `mySprite`, `mySprite:set_collision_mask(1, 1, 15, 15)` would reduce the hitbox by 1px on each side.
    ]]
    set_collision_mask = function(self, bbox_left, bbox_top, bbox_right, bbox_bottom)
        gm.sprite_collision_mask(
            self.value,
            false,
            2,  -- `2` is user-defined
            bbox_left,
            bbox_top,
            bbox_right,
            bbox_bottom,
            0,  -- `0` is `bboxkind_rectangular`
            0   -- `0` transparency tolerance
        )
    end

}



-- ========== Metatables ==========

local wrapper_name = "Sprite"

make_table_once("metatable_sprite", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return __proxy[proxy] end
        if k == "RAPI" then return wrapper_name end
        
        -- Methods
        if methods_sprite[k] then
            return methods_sprite[k]
        end

        return nil
    end,
    

    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end
        
        log.error("Sprite has no properties to set", 2)
    end,


    __metatable = "RAPI.Wrapper."..wrapper_name
})



-- Public export
__class.Sprite = Sprite