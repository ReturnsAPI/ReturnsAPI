-- ItemTier

-- TODO: Add property docs

---@class ItemTierClass
ItemTier = new_class()
C.ItemTier = ItemTier

run_on_initial_load(function()
    P.item_tier_find_table_wrapper = FindTable.new()
    P.item_tier_find_table_struct  = FindTable.new()
end)

local wrapper_table = P.item_tier_find_table_wrapper
local struct_table  = P.item_tier_find_table_struct

local proxy = P.proxy
local metatable

local type               = type
local new_proxy          = new_proxy
local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Constants ==========

ItemTier.COMMON    = 0
ItemTier.UNCOMMON  = 1
ItemTier.RARE      = 2
ItemTier.EQUIPMENT = 3
ItemTier.BOSS      = 4
ItemTier.SPECIAL   = 5
ItemTier.FOOD      = 6
ItemTier.NOTIER    = 7

-- Populate `tier_constants`
local tier_constants = {}  ---@type table<number, string> Array table of vanilla tier IDs (indexed from `1`).
for name, tier in pairs(ItemTier) do
    if type(tier) == "number" then
        tier_constants[tier + 1] = name
    end
end


-- ========== Internal ==========

local function populate_find_table()
    -- Populate find tables with vanilla tiers
    for tier, name in pairs(tier_constants) do
        local identifier = name:lower()
        local struct     = Global.item_tiers:get(tier - 1)

        -- Custom properties
        struct.namespace  = "ror"
        struct.identifier = identifier

        wrapper_table:set(ItemTier.wrap(tier - 1), identifier, "ror", tier - 1)
        struct_table:set(struct, identifier, "ror", tier - 1)
    end
end
run_on_initialize(populate_find_table)


-- ========== Static Methods ==========

--[[
Creates a new item tier with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the item tier.
---@return ItemTier
ItemTier.new = function(NAMESPACE, identifier)
    check_init_started("new")
    if not identifier then throw("No identifier provided", "new") end

    -- Return existing tier if found
    local tier = ItemTier.find(identifier, NAMESPACE, true)
    if tier then return tier end

    -- Get next usable ID for tier
    local tiers_array = Global.item_tiers
    local id = #tiers_array

    local struct = Struct.new(
        gm.constants.ItemTierDef,
        id      -- index

        -- The rest have default constructor args
        -- fair_item_value              0
        -- text_color                   "w"
        -- spawn_sound                  wItemDrop_White
        -- pickup_color                 16777215
        -- pickup_color_bright          16777215
        -- pickup_particle_type         -1
        -- pickup_head_shape            undefined
        -- ignore_fair                  false
        -- item_pool_for_reroll         -1
        -- equipment_pool_for_reroll    -1
    )

    -- Custom properties
    struct.namespace  = NAMESPACE
    struct.identifier = identifier

    -- Push onto array
    tiers_array:push(struct)

    local wrapper = ItemTier.wrap(id)
    wrapper_table:set(wrapper, identifier, "ror", id)
    struct_table:set(struct, identifier, "ror", id)
    return wrapper
end

--[[
Searches for the specified item tier and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return ItemTier | nil
ItemTier.find = function(identifier, namespace, namespace_is_specified)
    return wrapper_table:get(identifier, namespace, namespace_is_specified)
end

--[[
Returns a table of all item tiers in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param namespace? string The namespace to search in.
---@return table<number, ItemTier>
ItemTier.find_all = function(namespace, namespace_is_specified)
    return wrapper_table:get_all(namespace, namespace_is_specified)
end

--[[
Returns an ItemTier wrapper containing the provided item tier ID.
]]
---@param id number | ItemTier The item tier to wrap.
---@return ItemTier
ItemTier.wrap = function(tier)
    return new_proxy(unwrap(tier), metatable)
end


-- ========== Wrapper Methods ==========

---@class ItemTier
local methods = {}

--[[
Sets the item drop head shape.
]]
---@param points table<number, table> A table of points; each point has the format `{angle, dist_from_center}`. <br>E.g., `{{0, 11}, {120, 11}, {240, 11}}` makes a triangle with each point being 11px from the center.
methods.set_head_shape = function(self, points)
    if type(points) ~= "table" then throw("points is invalid") end

    local arr = Array.new()
    for _, point in ipairs(points) do
        local p = Array.new(point)
        arr:push(p)
    end
    self.pickup_head_shape = arr
end

--[[
Prints the item tier's properties.
]]
methods.print = function(self)
    struct_table[proxy[self]].value:print()
end


-- ========== Metatables ==========

---@class ItemTier
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.

---@class ItemTier
---@field namespace                  string   The namespace the item tier is in.
---@field identifier                 string   The identifier for the item tier within the namespace.
---@field fair_item_value            number   `0` by default.
---@field text_color                 string   The text formatting color code. <br>`"w"` by default.
---@field spawn_sound                number   The ID of the sound played when an item pickup is spawned. <br>`wItemDrop_White` by default.
---@field pickup_color               number   The color used for the pickup head shape and trail. <br>`Color.WHITE` by default.
---@field pickup_color_bright        number   The color used for the outer ring of the center of the pickup head. <br>`Color.WHITE` by default.
---@field pickup_particle_type       number   The ID of the particle that is emitted while the item pickup is traveling. <br>Particle should be white; it is blended with `pickup_color`. <br>`-1` by default.
---@field pickup_head_shape          Array    An array of points; each point has the format `[angle, dist_from_center]`. <br>E.g., `[[0, 11], [120, 11], [240, 11]\]` makes a triangle with each point being 11px from the center. <br>`nil` by default.
---@field ignore_fair                boolean  `false` by default.
---@field item_pool_for_reroll       number   The ID of the associated item loot pool. <br>`-1` (none) by default.
---@field equipment_pool_for_reroll  number   The ID of the associated equipment loot pool. <br>`-1` (none) by default.

local mt_name = "ItemTier"

W.ItemTier = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return proxy[t] end
        if k == "RAPI" then return mt_name end

        -- Methods
        local method = methods[k]
        if method then return method end

        -- Getter
        local struct = struct_table[proxy[t]].value
        return struct[k]
    end,

    __newindex = function(t, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        local struct = struct_table[proxy[t]].value
        struct[k] = v
    end,
    
    __metatable = mt_wrapper_name(mt_name),
}
metatable = W.ItemTier