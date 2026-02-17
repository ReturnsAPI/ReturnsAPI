-- Sprite

Sprite = new_class()

run_once(function()
    __sprite_find_cache = FindCache.new()
end)



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The sprite ID being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.
`namespace`     | string    | *Read-only.* The namespace the sprite is in.
`identifier`    | string    | *Read-only.* The identifier for the sprite within the namespace.
`width`         | number    | *Read-only.* The width of the sprite (in pixels).
`height`        | number    | *Read-only.* The height of the sprite (in pixels).
`subimages`     | number    | *Read-only.* The number of subimages of the sprite.
]]



-- ========== Internal ==========

Sprite.internal.initialize = function()
    -- Populate cache with vanilla sprites
    local resource_manager = Map.wrap(Global.ResourceManager_sprite.__namespacedAssetLookup)
    
    for identifier, sprite in pairs(Map.wrap(resource_manager["ror"])) do
        local wrapper = Sprite.wrap(sprite)

        __sprite_find_cache:set(
            {
                wrapper = wrapper,
            },
            identifier,
            "ror",
            sprite
        )
    end
end
table.insert(_rapi_initialize, Sprite.internal.initialize)



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
    local sprite = Sprite.find(identifier, NAMESPACE, true)
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

    -- Adding to find table is done in the hook at the bottom

    return Sprite.wrap(sprite)
end


--@static
--@return       Sprite or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified sprite and returns it.

--@findinfo
]]
Sprite.find = function(identifier, namespace, namespace_is_specified)
    local cached = __sprite_find_cache:get(identifier, namespace, namespace_is_specified)
    if cached then return cached.wrapper end
end


--@static
--@return       table
--@optional     namespace   | string    | The namespace to search in.
--[[
Returns a table of all sprites in the specified namespace.

--@findinfo
]]
Sprite.find_all = function(namespace, namespace_is_specified)
    return __sprite_find_cache:get_all(namespace, namespace_is_specified, "wrapper")
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
        if not speed then log.error("set_speed: speed is not provided", 2) end
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
        if not bbox_left    then log.error("set_collision_mask: bbox_left is not provided", 2) end
        if not bbox_top     then log.error("set_collision_mask: bbox_top is not provided", 2) end
        if not bbox_right   then log.error("set_collision_mask: bbox_right is not provided", 2) end
        if not bbox_bottom  then log.error("set_collision_mask: bbox_bottom is not provided", 2) end

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

        -- Get width/height
        if k == "width"     then return math.floor(gm.sprite_get_width (__proxy[proxy])) end
        if k == "height"    then return math.floor(gm.sprite_get_height(__proxy[proxy])) end
        if k == "subimages" then return math.floor(gm.sprite_get_number(__proxy[proxy])) end
        
        -- Methods
        if methods_sprite[k] then
            return methods_sprite[k]
        end

        -- Getter
        return __sprite_find_cache:get(__proxy[proxy])[k]
    end,
    

    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI"
        or k == "namespace"
        or k == "identifier"
        or k == "width"
        or k == "height"
        or k == "subimages" then
            log.error("Key '"..k.."' is read-only", 2)
        end
        
        log.error("Sprite has no properties to set", 2)
    end,


    __metatable = "RAPI.Wrapper."..wrapper_name
})



-- ========== Hooks ==========

-- Add new sprites to find table
Hook.add_post(RAPI_NAMESPACE, gm.constants.sprite_add_w, Callback.internal.FIRST, function(self, other, result, args)
    local id = result.value
    if id == -1 then return end

    __sprite_find_cache:set(
        {
            wrapper = Sprite.wrap(id),
        },
        args[2].value,
        args[1].value,
        id
    )
end)



-- Public export
__class.Sprite = Sprite