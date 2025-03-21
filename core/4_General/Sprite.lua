-- Sprite

Sprite = new_class()

local find_cache = {}



-- ========== Static Methods ==========

Sprite.new = function(namespace, identifier, path, image_number, x_origin, y_origin)
    -- Initialize.internal.check_if_done()  -- TODO
    if not identifier then log.error("No identifier provided", 2) end
    if not path then log.error("No image path provided", 2) end

    path = path:gsub("~", NAMESPACE_PATH[namespace])

    -- Search for existing sprite
    local sprite
    local namespace_struct = Global.ResourceManager_sprite.__namespacedAssetLookup[namespace]
    if namespace_struct then sprite = namespace_struct[identifier] end

    if sprite then
        -- Modify sprite origin
        local sprite = Sprite.wrap(sprite)
        if x_origin and y_origin then sprite:set_origin(x_origin or 0, y_origin or 0) end
        return sprite
    end

    -- Create sprite
    sprite = GM.sprite_add_w(
        namespace,
        identifier,
        path,
        image_number or 1,
        x_origin or 0,
        y_origin or 0
    )

    if sprite == -1 then
        log.error("Could not load sprite at "..path, 2)
    end

    return Sprite.wrap(sprite)
end


Sprite.find = function(identifier, namespace, default_namespace)
    local nsid = namespace.."-"..identifier
    local ror_nsid = "ror-"..identifier

    -- Check in cache (both mod namespace and "ror")
    local cached = find_cache[nsid]
    if cached then return cached end
    if namespace == default_namespace then
        local cached = find_cache[ror_nsid]
        if cached then return cached end
    end

    -- Look in mod namespace
    local holder = RValue.new_holder_scr(1)
    holder[0] = RValue.new(nsid)
    local out = RValue.new(0)
    gmf.sprite_find(nil, nil, out, 1, holder)
    local sprite = RValue.to_wrapper(out)

    if sprite then
        sprite = Sprite.wrap(sprite)
        find_cache[nsid] = sprite
        return sprite
    end

    -- Also look in "ror" namespace if user passed no `namespace` arg
    if namespace == default_namespace then
        local holder = RValue.new_holder_scr(1)
        holder[0] = RValue.new(ror_nsid)
        local out = RValue.new(0)
        gmf.sprite_find(nil, nil, out, 1, holder)
        local sprite = RValue.to_wrapper(out)
        
        if sprite then
            sprite = Sprite.wrap(sprite)
            find_cache[ror_nsid] = sprite
            return sprite
        end
    end

    return nil
end


Sprite.wrap = function(sprite)
    return Proxy.new(Wrap.unwrap(sprite), metatable_sprite)
end



-- ========== Instance Methods ==========

methods_sprite = {

    set_origin = function(self, x_origin, y_origin)
        local holder = RValue.new_holder(3)
        holder[0] = RValue.new(self.value)
        holder[1] = RValue.new(x_origin or 0)
        holder[2] = RValue.new(y_origin or 0)
        gmf.sprite_set_offset(RValue.new(0), nil, nil, 3, holder)
    end,


    set_speed = function(self, speed)
        local holder = RValue.new_holder(3)
        holder[0] = RValue.new(self.value)
        holder[1] = RValue.new(speed)
        holder[2] = RValue.new(1)   -- Using `spritespeed_framespergameframe`
        gmf.sprite_set_speed(RValue.new(0), nil, nil, 3, holder)
    end,


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

}



-- ========== Metatables ==========

metatable_sprite = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(t) end
        if k == "RAPI" then return getmetatable(t):sub(14, -1) end
        
        -- Methods
        if methods_sprite[k] then
            return methods_sprite[k]
        end

        return nil
    end,
    

    __newindex = function(t, k, v)
        -- Setter
        log.error("Sprite has no properties to set")
    end,


    __metatable = "RAPI.Wrapper.Sprite"
}



__class.Sprite = Sprite