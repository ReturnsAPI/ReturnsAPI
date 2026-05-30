-- Sprite

---@class SpriteClass
Sprite = new_class()
C.Sprite = Sprite

run_on_initial_load(function()
    P.sprite_find_table = FindTable.new()
end)

local sprite_find_table = P.sprite_find_table

local proxy = P.proxy
local metatable

local floor              = math.floor
local gm                 = gm  ---@type table<string, function>
local new_proxy          = new_proxy
local unwrap             = Wrap.unwrap
local check_init_started = Initialize.internal.check_if_started


-- ========== Internal ==========

local function populate_find_table()
    -- Populate cache with vanilla sprites
    local resource_manager = Map.wrap(Global.ResourceManager_sprite.__namespacedAssetLookup)
    
    for identifier, sprite in pairs(Map.wrap(resource_manager["ror"])) do
        local wrapper = Sprite.wrap(sprite)
        sprite_find_table:set(wrapper, identifier, "ror", sprite)
    end
end
run_on_initialize(populate_find_table)


-- ========== Static Methods ==========

--@section Static Methods

--[[
Creates a new sprite with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the sprite.
---@param path string The file path to the sprite. <br>`~` expands to your mod folder.
---@param image_number number The number of subimages. <br>`1` by default.
---@param x_origin number The x coordinate of the origin (offset). <br>`0` by default.
---@param y_origin number The y coordinate of the origin (offset). <br>`0` by default.
---@return Sprite
Sprite.new = function(NAMESPACE, identifier, path, image_number, x_origin, y_origin)
    check_init_started("new")
    if not identifier then throw("No identifier provided", "new") end
    if not path then throw("No image path provided", "new") end

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
        throw("Could not load sprite at '"..path.."'", "new")
    end

    -- Adding to find table is done in the hook at the bottom

    return Sprite.wrap(sprite)
end

--[[
Searches for the specified sprite and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return Sprite | nil
Sprite.find = function(identifier, namespace, namespace_is_specified)
    return sprite_find_table:get(identifier, namespace, namespace_is_specified)
end

--[[
Returns a table of all sprites in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param namespace? string The namespace to search in.
---@return table<number, Sprite>
Sprite.find_all = function(namespace, namespace_is_specified)
    return sprite_find_table:get_all(namespace, namespace_is_specified)
end

--[[
Returns a Sprite wrapper containing the provided sprite ID.
]]
---@param sprite number | Sprite The sprite to wrap.
---@return Sprite
Sprite.wrap = function(sprite)
    return new_proxy(unwrap(sprite), metatable)
end


-- ========== Wrapper Methods ==========

local methods = {}

--[[
Sets the origin of the sprite.
Resets unspecified coordinates to `0`.
]]
---@param x_origin? number The x coordinate of the origin (offset). <br>`0` by default.
---@param y_origin? number The y coordinate of the origin (offset). <br>`0` by default.
methods.set_origin = function(self, x_origin, y_origin)
    gm.sprite_set_offset(proxy[self], x_origin or 0, y_origin or 0)
end

--[[
Sets the animation speed of the sprite.
]]
---@param speed number The animation speed, in "sprite frames per game frame".
methods.set_speed = function(self, speed)
    if not speed then throw("speed is not provided") end
    gm.sprite_set_speed(proxy[self], speed, 1)  -- Using `spritespeed_framespergameframe` (1)
end

--[[
Sets the collision mask of the sprite, relative to the top-left corner (0, 0).

E.g., For a 16x16 `mySprite`, `mySprite:set_collision_mask(1, 1, 15, 15)` would reduce the hitbox by 1px on each side.
]]
---@param bbox_left number The left x.
---@param bbox_top number The top y.
---@param bbox_right number The right x.
---@param bbox_bottom number The bottom y.
methods.set_collision_mask = function(self, bbox_left, bbox_top, bbox_right, bbox_bottom)
    if not bbox_left   then throw("bbox_left is not provided", 2) end
    if not bbox_top    then throw("bbox_top is not provided", 2) end
    if not bbox_right  then throw("bbox_right is not provided", 2) end
    if not bbox_bottom then throw("bbox_bottom is not provided", 2) end

    gm.sprite_collision_mask(
        proxy[self],
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


-- ========== Metatables ==========

---@class Sprite
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field namespace string The namespace of the sprite.
---@field identifier string The identifier of the sprite.
---@field width number The width of the sprite (in pixels).
---@field height number The height of the sprite (in pixels).
---@field subimages number The number of subimages of the sprite.

local mt_name = "Sprite"

W.Sprite = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return proxy[t] end
        if k == "RAPI" then return mt_name end

        -- Get width/height
        if k == "width"     then return floor(gm.sprite_get_width (proxy[t])) end
        if k == "height"    then return floor(gm.sprite_get_height(proxy[t])) end
        if k == "subimages" then return floor(gm.sprite_get_number(proxy[t])) end
        
        -- Methods
        local method = methods[k]
        if method then return method end

        -- Getter
        return sprite_find_table:get(proxy[t])[k]
    end,

    __newindex = function(t, k, v)
        log.error(mt_name.." has no properties to set", 2)
    end,

    __metatable = mt_wrapper_name(mt_name),
}
metatable = W.Sprite


-- ========== Hooks ==========

-- Add new sprites to find table
gm.post_script_hook(gm.constants.sprite_add_w, function(self, other, result, args)
    local id = result.value
    if id == -1 then return end

    sprite_find_table:set(
        Sprite.wrap(id),
        args[2].value,
        args[1].value,
        id
    )
end)