-- Sprite

Sprite = new_class()

local find_cache = {}



-- ========== Static Methods ==========

--$static
--$return       Sprite
--$param        identifier      | string    | The identifier for the sprite.
--$param        path            | string    | The file path to the sprite. <br>`~` expands to your mod folder (without a trailing slash).
--$optional     image_number    | number    | The number of subimages. <br>`1` by default.
--$optional     x_origin        | number    | The x coordinate of the origin (offset). <br>`0` by default.
--$optional     y_origin        | number    | The y coordinate of the origin (offset). <br>`0` by default.
--[[
Creates a new sprite with the given identifier if it does not already exist,
or returns the existing one if it does.
]]
Sprite.new = function(namespace, identifier, path, image_number, x_origin, y_origin)
    Initialize.internal.check_if_started()
    if not identifier then log.error("No identifier provided", 2) end
    if not path then log.error("No image path provided", 2) end

    -- Expand `~` to mod folder
    path = path:gsub("~", __namespace_path[namespace])

    -- Return existing sprite if found
    local sprite = Sprite.find(identifier, namespace, namespace)
    if sprite then
        -- Allow for modification of sprite origin
        if x_origin and y_origin then sprite:set_origin(x_origin or 0, y_origin or 0) end
        return sprite
    end

    -- Create new sprite
    sprite = GM.sprite_add_w(
        namespace,
        identifier,
        path,
        image_number or 1,
        x_origin or 0,
        y_origin or 0
    )

    if sprite == -1 then
        log.error("Could not load sprite at '"..path.."'", 2)
    end

    -- Add to cache and return
    local wrapper = Sprite.wrap(sprite)
    find_cache[namespace.."-"..identifier] = wrapper
    return wrapper
end


--$static
--$return       Sprite or nil
--$param        identifier  | string    | The identifier to search for.
--$optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified sprite and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]
Sprite.find = function(identifier, namespace, default_namespace)
    local namespace, is_specified = parse_optional_namespace(namespace, default_namespace)

    local nsid = namespace.."-"..identifier
    local ror_nsid = "ror-"..identifier

    -- Check in cache (both in namespace and in "ror" if no `namespace` arg)
    local cached = find_cache[nsid]
    if cached then return cached end
    if not is_specified then
        local cached = find_cache[ror_nsid]
        if cached then return cached end
    end

    -- Search in namespace
    local sprite
    local resource_manager = Global.ResourceManager_sprite.__namespacedAssetLookup
    local namespace_struct = resource_manager[namespace]
    if namespace_struct then sprite = namespace_struct[identifier] end

    if sprite then
        sprite = Sprite.wrap(sprite)
        find_cache[nsid] = sprite
        return sprite
    end

    -- Also search in "ror" namespace if passed no `namespace` arg
    if not is_specified then
        local sprite
        local namespace_struct = resource_manager["ror"]
        if namespace_struct then sprite = namespace_struct[identifier] end
        
        if sprite then
            sprite = Sprite.wrap(sprite)
            find_cache[ror_nsid] = sprite
            return sprite
        end
    end

    return nil
end


--$static
--$return       table, bool
--$optional     namespace   | string    | The namespace to check.
--[[
Returns a table of all sprites in the specified namespace,
and a boolean that is `true` if the table is *not* empty.
If no namespace is provided, retrieves from both your mod's namespace and "ror".
]]
Sprite.find_all = function(namespace, _namespace)
    local namespace, is_specified = parse_optional_namespace(_namespace, namespace)
    
    local sprites = {}
    local resource_manager = Global.ResourceManager_sprite.__namespacedAssetLookup

    -- Search in namespace
    if resource_manager[namespace] then
        for _, sprite in pairs(resource_manager[namespace]) do
            table.insert(sprites, Sprite.wrap(sprite))
        end
    end

    -- Also search in "ror" namespace if passed no `namespace` arg
    if not is_specified then
        for _, sprite in pairs(resource_manager["ror"]) do
            table.insert(sprites, Sprite.wrap(sprite))
        end
    end
    
    return sprites, #sprites > 0
end


--$static
--$return       Sprite
--$param        sprite      | number    | The sprite ID to wrap.
--[[
Returns a Sprite wrapper containing the provided sprite ID.
]]
Sprite.wrap = function(sprite)
    return Proxy.new(Wrap.unwrap(sprite), metatable_sprite)
end



-- ========== Instance Methods ==========

make_table_once("methods_sprite", {

    --$instance
    --$optional     x_origin    | number    | The x coordinate of the origin (offset). <br>`0` by default.
    --$optional     y_origin    | number    | The y coordinate of the origin (offset). <br>`0` by default.
    --[[
    Sets the origin of the sprite.
    Resets unspecified coordinates to `0`.
    ]]
    set_origin = function(self, x_origin, y_origin)
        local holder = RValue.new_holder(3)
        holder[0] = RValue.new(self.value)
        holder[1] = RValue.new(x_origin or 0)
        holder[2] = RValue.new(y_origin or 0)
        gmf.sprite_set_offset(RValue.new(0), nil, nil, 3, holder)
    end,


    --$instance
    --$param        speed       | number    | The animation speed, in "sprite frames per game frame".
    --[[
    Sets the animation speed of the sprite.
    ]]
    set_speed = function(self, speed)
        local holder = RValue.new_holder(3)
        holder[0] = RValue.new(self.value)
        holder[1] = RValue.new(speed)
        holder[2] = RValue.new(1)   -- Using `spritespeed_framespergameframe`
        gmf.sprite_set_speed(RValue.new(0), nil, nil, 3, holder)
    end,


    --$instance
    --$param        bbox_left   | number    | The left side, relative to the origin.
    --$param        bbox_top    | number    | The top side, relative to the origin.
    --$param        bbox_right  | number    | The right side, relative to the origin.
    --$param        bbox_bottom | number    | The bottom side, relative to the origin.
    --[[
    Sets the collision mask of the sprite, relative to the origin.

    E.g.,
    - A negative `bbox_left` value means to the left of the origin.
    - `bbox_left = -5` and `bbox_right = 5` would give a total width of `10` pixels, centered on the origin.
    ]]
    set_collision_mask = function(self, bbox_left, bbox_top, bbox_right, bbox_bottom)
        -- Arguments are relative to the origin (i.e., `bbox_left < 0` means to the left of the origin)

        -- Get x and y origin
        local holder = RValue.new_holder(1)
        holder[0] = RValue.new(self.value)
        local out = RValue.new(0)
        gmf.sprite_get_xoffset(out, nil, nil, 1, holder)
        local x_origin = out.value

        local holder = RValue.new_holder(1)
        holder[0] = RValue.new(self.value)
        local out = RValue.new(0)
        gmf.sprite_get_yoffset(out, nil, nil, 1, holder)
        local y_origin = out.value

        -- Set collision mask properties
        local holder = RValue.new_holder(9)
        holder[0] = RValue.new(self.value)
        holder[1] = RValue.new(false)
        holder[2] = RValue.new(2)   -- `2` is user-defined
        holder[3] = RValue.new(bbox_left    + x_origin)
        holder[4] = RValue.new(bbox_top     + y_origin)
        holder[5] = RValue.new(bbox_right   + x_origin)
        holder[6] = RValue.new(bbox_bottom  + y_origin)
        holder[7] = RValue.new(0)   -- `0` is `bboxkind_rectangular`
        holder[8] = RValue.new(0)   -- `0` transparency tolerance
        gmf.sprite_collision_mask(RValue.new(0), nil, nil, 9, holder)
    end

})



-- ========== Metatables ==========

make_table_once("metatable_sprite", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(proxy) end
        if k == "RAPI" then return getmetatable(proxy):sub(14, -1) end
        
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


    __metatable = "RAPI.Wrapper.Sprite"
})



-- Public export
__class.Sprite = Sprite