-- Sprite

Sprite = new_class()



-- ========== Static Methods ==========

Sprite.new = function(namespace, identifier, path, image_number, x_origin, y_origin)
    Initialize.internal.check_if_done()
    if not identifier then log.error("No identifier provided", 2) end
    if not path then log.error("No image path provided", 2) end

    local sprite = gm.sprite_find(namespace.."-"..identifier)
    if sprite then
        -- Modify sprite origin
        if x_origin and y_origin then
            gm.sprite_set_offset(sprite, x_origin or 0, y_origin or 0)
        end
        return Sprite.wrap(sprite)
    end

    -- Create sprite
    sprite = gm.sprite_add_w(
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
    -- Look in mod namespace
    local sprite = gm.sprite_find(namespace.."-"..identifier)
    if sprite then return Sprite.wrap(sprite) end

    -- Also look in "ror" namespace if user passed no `namespace` arg
    if namespace == default_namespace then
        sprite = gm.sprite_find("ror-"..identifier)
        if sprite then return Sprite.wrap(sprite) end
    end

    return nil
end


Sprite.wrap = function(sprite)
    return Proxy.new(Wrap.unwrap(sprite), metatable_sprite)
end



-- ========== Instance Methods ==========

methods_sprite = {

    set_origin = function(self, x_origin, y_origin)
        gm.sprite_set_offset(self.value, x_origin or 0, y_origin or 0)
    end,


    set_speed = function(self, speed)
        gm.sprite_set_speed(self.value, speed, 1)   -- Using `spritespeed_framespergameframe`
    end,


    set_collision_mask = function(self, bbox_left, bbox_top, bbox_right, bbox_bottom)
        -- Arguments are relative to the origin (i.e., `bbox_left < 0` means to the left of the origin)
        local x_origin = gm.sprite_get_xoffset(self.value)
        local y_origin = gm.sprite_get_yoffset(self.value)

        -- arg3 : `2` is user-defined
        -- arg8 : `0` is `bboxkind_rectangular`
        -- arg9 : `0` transparency tolerance
        gm.sprite_collision_mask(self.value, false, 2, bbox_left + x_origin, bbox_top + y_origin, bbox_right + x_origin, bbox_bottom + y_origin, 0, 0)
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



_CLASS["Sprite"] = Sprite