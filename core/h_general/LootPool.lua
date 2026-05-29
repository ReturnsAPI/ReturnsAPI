-- LootPool

-- TODO: Add property docs
--       Add ability to modify command crate on_create variables easier
--       Prehook `object_create_w` for the command crate to use mod namespace instead of "ror"

---@class LootPoolClass
LootPool = new_class()
C.LootPool = LootPool

run_on_initial_load(function()
    P.loot_pool_table_wrapper      = FindTable.new()
    P.loot_pool_table_struct       = FindTable.new()
    P.loot_pool_table_crate_obj    = FindTable.new()
    P.loot_pool_table_crate_struct = FindTable.new()
end)

local wrapper_table      = P.loot_pool_table_wrapper
local struct_table       = P.loot_pool_table_struct
local crate_obj_table    = P.loot_pool_table_crate_obj
local crate_struct_table = P.loot_pool_table_crate_struct

local proxy = P.proxy
local metatable

local type               = type
local gm                 = gm
local new_proxy          = new_proxy
local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap

local enable_capture = false
local passed_namespace
local binded_struct  ---@type Struct Capture the struct from `callback_bind` on loot pool creation; this is the crate info struct
local crate_obj      ---@type Object Capture the created object from `object_add_w`


-- ========== Constants ==========

LootPool.COMMON          = 0
LootPool.UNCOMMON        = 1
LootPool.RARE            = 2
LootPool.EQUIPMENT       = 3
LootPool.BOSS            = 4
LootPool.BOSS_EQUIPMENT  = 5
LootPool.FOOD            = 6

-- Populate `pool_constants`
local pool_constants = {}  ---@type table<number, string> Array table of vanilla loot pool IDs (indexed from `1`).
for name, pool in pairs(LootPool) do
    if type(pool) == "number" then
        pool_constants[pool + 1] = name
    end
end


-- ========== Internal ==========

local function populate_find_table()
    -- Populate find table with vanilla pools
    for tier, name in pairs(pool_constants) do
        local identifier = name:lower()
        local struct     = Global.treasure_loot_pools:get(tier - 1)

        -- Custom properties
        struct.namespace  = "ror"
        struct.identifier = identifier

        wrapper_table:set(LootPool.wrap(tier - 1), identifier, "ror", tier - 1)
        struct_table:set(struct, identifier, "ror", tier - 1)
    end
end
run_on_initialize(populate_find_table)


-- ========== Static Methods ==========

--[[
Creates a new loot pool with the given identifier if it does not already exist,
or returns the existing one if it does.
]]
---@param identifier string The identifier for the loot pool.
---@return LootPool
LootPool.new = function(NAMESPACE, identifier)
    check_init_started("new")
    if not identifier then throw("No identifier provided", "new") end

    -- Return existing pool if found
    local pool = LootPool.find(identifier, NAMESPACE, true)
    if pool then return pool end

    -- Get next usable ID for pool
    local loot_pools_array = Global.treasure_loot_pools
    local id = #loot_pools_array

    -- Enable capturing of crate object in the hooks below
    -- Also pass the namespace to `object_add_w` hook
    enable_capture = true
    passed_namespace = NAMESPACE

    -- Create new struct for pool
    local struct = Struct.new(
        gm.constants.TreasureLootPool,
        id      -- index
        
        -- The rest have default constructor args
        -- item_tier                    -1
        -- is_equipment_pool            false
        -- command_crate_sprite         -1
        -- sprite_death                 -1      (in crate object on_create)
        -- sprite_ping                  -1      (in crate object on_create)
        -- outline_index_inactive       0       (in crate object on_create)
        -- outline_index_active         1       (in crate object on_create)
        -- col_index                    0       (in crate object on_create)

        -- `command_crate_object_id` is automatically created with the
        -- identifier `generated_CommandCrate_<index>` in `ror` namespace

        -- Use `gm.method_get_self` to get the bound
        -- struct for the object on_create callback
    )

    -- Custom properties
    struct.namespace  = NAMESPACE
    struct.identifier = identifier

    -- Push onto array
    loot_pools_array:push(struct)

    -- This is called in TreasureLootPool constructor
    -- if a sprite was provided for the crate
    gm.object_set_depth(crate_obj.value, -289)

    local wrapper = LootPool.wrap(id)
    wrapper_table:set(wrapper, identifier, NAMESPACE, id)
    struct_table:set(struct, identifier, NAMESPACE, id)
    crate_obj_table:set(crate_obj, identifier, NAMESPACE, id)
    crate_struct_table:set(binded_struct, identifier, NAMESPACE, id)
    return wrapper
end

--[[
Creates a new loot pool using an item tier as a base, <br>
automatically populating the pool's properties and <br>
setting the item tier's `*_pool_for_reroll` properties.

This also populates the pool's `drop_pool` with all items *currently* in the tier; <br>
if you are relying on this, this must be called *after* setting all desired items to the tier.
]]
---@param tier number | ItemTier The item tier to use as a base.
---@return LootPool
LootPool.new_from_tier = function(NAMESPACE, tier)
    check_init_started("new_from_tier")
    if not tier then throw("No tier provided", "new_from_tier") end

    tier = ItemTier.wrap(tier)
    if type(tier.value) ~= "number" then throw("Invalid tier '"..tostring(tier.value).."'", "new_from_tier") end
    
    -- Use existing pool or create a new one
    local pool = LootPool.find(tier.identifier, NAMESPACE, true)
              or LootPool.new(NAMESPACE, tier.identifier)

    -- Set pool properties
    pool.item_tier = tier

    -- Set tier properties
    tier.item_pool_for_reroll      = pool
    tier.equipment_pool_for_reroll = pool

    -- Clear and populate `drop_pool`
    List.wrap(pool.drop_pool):clear()
    local items = Item.find_all(RAPI_NAMESPACE, tier.value, Item.Property.TIER)
    for _, item in ipairs(items) do
        pool:add_item(item)
    end

    return pool
end

--[[
Searches for the specified loot pool and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return LootPool | nil
LootPool.find = function(identifier, namespace, namespace_is_specified)
    return wrapper_table:get(identifier, namespace, namespace_is_specified)
end

--[[
Returns a table of all loot pools in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param namespace? string The namespace to search in.
---@return table<number, LootPool>
LootPool.find_all = function(namespace, namespace_is_specified)
    return wrapper_table:get_all(namespace, namespace_is_specified)
end

--[[
Returns a LootPool wrapper containing the provided loot pool ID.
]]
---@param id number | LootPool The loot pool to wrap.
---@return LootPool
LootPool.wrap = function(pool)
    return new_proxy(unwrap(pool), metatable)
end


-- ========== Wrapper Methods ==========

---@class LootPool
local methods = {}

--[[
Adds an item(s) to the loot pool.
]]
---@param ... number | Item A variable number of items. <br>Alternatively, a table may be provided.
methods.add_item = function(self, ...)
    local t = {...}
    if type(t[1]) == "table" and not t[1].RAPI then t = t[1] end

    local drop_pool = List.wrap(self.drop_pool)
    for _, item in ipairs(t) do
        drop_pool:add(Item.wrap(item).object_id)
    end
end

--[[
Removes an item(s) from the loot pool.
]]
---@param ... number | Item A variable number of items. <br>Alternatively, a table may be provided.
methods.remove_item = function(self, ...)
    local t = {...}
    if type(t[1]) == "table" and not t[1].RAPI then t = t[1] end

    local drop_pool = List.wrap(self.drop_pool)
    for _, item in ipairs(t) do
        drop_pool:delete_value(Item.wrap(item).object_id)
    end
end

--[[
Adds (an) equipment to the loot pool.
]]
---@param ... number | Equipment A variable number of equipment. <br>Alternatively, a table may be provided.
methods.add_equipment = function(self, ...)
    local t = {...}
    if type(t[1]) == "table" and not t[1].RAPI then t = t[1] end

    local drop_pool = List.wrap(self.drop_pool)
    for _, equip in ipairs(t) do
        drop_pool:add(Equipment.wrap(equip).object_id)
    end
end

--[[
Removes (an) equipment from the loot pool.
]]
---@param ... number | Equipment A variable number of equipment. <br>Alternatively, a table may be provided.
methods.remove_equipment = function(self, ...)
    local t = {...}
    if type(t[1]) == "table" and not t[1].RAPI then t = t[1] end

    local drop_pool = List.wrap(self.drop_pool)
    for _, equip in ipairs(t) do
        drop_pool:delete_value(Equipment.wrap(equip).object_id)
    end
end

--[[
Rolls for a random item from the loot pool, taking
into account allowed and disallowed loot tags.

Returns the chosen Item and its pickup object.
]]
---@param required_loot_tags? number | table A bit sum of flags; the chosen item must have at least one. <br>Alternatively, table containing multiple flags can be provided. <br>`0` by default.
---@param disallowed_loot_tags? number | table A bit sum of flags; the chosen item must not have any of these. <br>Alternatively, table containing multiple flags can be provided. <br>`0` by default.
---@return Item, Object
methods.roll = function(self, required_loot_tags, disallowed_loot_tags)
    local required_sum, disallowed_sum = required_loot_tags or 0, disallowed_loot_tags or 0

    if type(required_loot_tags) == "table" then
        required_sum = 0
        for _, v in ipairs(required_loot_tags) do
            required_sum = required_sum + v
        end
    end
    if type(disallowed_loot_tags) == "table" then
        disallowed_sum = 0
        for _, v in ipairs(disallowed_loot_tags) do
            disallowed_sum = disallowed_sum + v
        end
    end

    local obj_id = gm.treasure_loot_pool_roll(proxy[self], required_sum, disallowed_sum)
    local item   = gm.object_to_item(obj_id)

    if item ~= -1 then item = Item.wrap(item)
    else item = nil
    end

    -- Return both the Item wrapper and item pickup object
    return item, Object.wrap(obj_id)
end

--[[
Returns the command crate that was generated alongside this loot pool.
]]
---@return Object
methods.get_crate = function(self)
    return crate_obj_table[proxy[self]].value
end

--[[
Prints the loot pool's properties.
]]
methods.print = function(self)
    struct_table[proxy[self]].value:print()
end


-- ========== Metatables ==========

---@class LootPool
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.

---@class LootPool
---@field namespace            string   The namespace the loot pool is in.
---@field identifier           string   The identifier for the loot pool within the namespace.
---@field drop_pool            number   List containing item/equipment `object_id`s that may appear as drops.
---@field available_drop_pool  number   List containing item/equipment `object_id`s that may appear as drops. <br>Populated on run creation from `drop_pool` and is what's actually used.
---@field item_tier            number   The associated item tier.
---@field is_equipment_pool    boolean  Whether or not this pool is marked as dropping equipment. <br>`false` by default.

---@class LootPool
---@field crate_sprite                  number  The sprite ID of the crate. <br>*Only available for custom loot pools.*
---@field crate_sprite_death            number  The sprite ID of the crate after use. <br>*Only available for custom loot pools.*
---@field crate_outline_index_inactive  number  *Only available for custom loot pools.*
---@field crate_outline_index_active    number  *Only available for custom loot pools.*
---@field crate_sprite_ping             number  Sprite ID <br>*Only available for custom loot pools.*
---@field crate_col_index               number  <br>*Only available for custom loot pools.*

local mt_name = "LootPool"

W.LootPool = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return proxy[t] end
        if k == "RAPI" then return mt_name end

        -- Methods
        local method = methods[k]
        if method then return method end

        -- Getter
        local loot_struct = struct_table[proxy[t]].value.
        local ret = loot_struct[k]
        if ret then return ret end

        -- Getter (Crate)
        if k == "crate_sprite" then return t:get_crate().obj_sprite end
        local crate_struct = crate_struct_table[proxy[t]].value
        return crate_struct[k:sub(7, -1)]
    end,

    __newindex = function(t, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        local loot_struct = struct_table[proxy[t]].value
        if gm.variable_struct_exists(unwrap(loot_struct), k) then
            loot_struct[k] = v
            return
        end

        -- Setter (Crate)
        if k == "crate_sprite" then
            gm.object_get_sprite_w(t:get_crate().value, unwrap(v))
            return
        end
        local crate_struct = crate_struct_table[proxy[t]].value
        crate_struct[k:sub(7, -1)] = v
    end,

    __metatable = mt_wrapper_name(mt_name),
}
metatable = W.LootPool


-- ========== Hooks ==========

-- Custom loot pools are not auto-populated by the game on run start

gm.post_script_hook(gm.constants.run_update_available_loot, function(self, other, result, args)
    local pools = Global.treasure_loot_pools

    -- Loop through custom loot pools (ID 7+)
    -- and call update method
    for i = 7, #pools - 1 do
        pools:get(i).update_available_drop_pool()
    end
end)

-- Capture crate object stuff

gm.pre_script_hook(gm.constants.object_add_w, function(self, other, result, args)
    -- This runs before `callback_bind` in TreasureLootPool constructor
    if not enable_capture then return end
    args[1].value = passed_namespace
end)

gm.post_script_hook(gm.constants.object_add_w, function(self, other, result, args)
    if not enable_capture then return end
    crate_obj = Object.wrap(result.value)
end)

gm.post_script_hook(gm.constants.callback_bind, function(self, other, result, args)
    if not enable_capture then return end
    binded_struct = gm.method_get_self(args[2].value)
    enable_capture = false
end)