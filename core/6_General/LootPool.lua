-- LootPool

-- TODO: Add property docs
--       Add ability to modify command crate on_create variables easier
--       Prehook `object_create_w` for the command crate to use mod namespace instead of "ror"

LootPool = new_class()

run_once(function()
    __loot_pool_find_table = FindCache.new()
end)

local enable_capture = false
local passed_namespace
local binded_struct     -- Capture the struct from `callback_bind` on loot pool creation; this is the crate info struct
local crate_obj         -- Capture the created object from `object_add_w`



-- ========== Constants ==========

--@section Constants

--@constants
--[[
COMMON          0
UNCOMMON        1
RARE            2
EQUIPMENT       3
BOSS            4
BOSS_EQUIPMENT  5
FOOD            6
]]

local pool_constants = {
    COMMON          = 0,
    UNCOMMON        = 1,
    RARE            = 2,
    EQUIPMENT       = 3,
    BOSS            = 4,
    BOSS_EQUIPMENT  = 5,
    FOOD            = 6
}

-- Add to LootPool directly (e.g., LootPool.COMMON)
for k, v in pairs(pool_constants) do
    LootPool[k] = v
end



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The ID of the loot pool.
`RAPI`          | string    | *Read-only.* The wrapper name.

<br>

Property | Type | Description
| - | - | -
`namespace`                 | string    | The namespace the loot pool is in.
`identifier`                | string    | The identifier for the loot pool within the namespace.
`drop_pool`                 | number    | List containing item/equipment `object_id`s that may appear as drops.
`available_drop_pool`       | number    | List containing item/equipment `object_id`s that may appear as drops. <br>Populated on run creation from `drop_pool` and is what's actually used.
`item_tier`                 | number    | The associated item tier.
`is_equipment_pool`         | bool      | Whether or not this pool is marked as dropping equipment. <br>`false` by default.

<br>

The following modify the generated command crate.
(Not available for vanilla LootPools.)

Property | Type | Description
| - | - | -
`crate_sprite`                  | sprite    | The sprite ID of the crate.
`crate_sprite_death`            | sprite    | The sprite ID of the crate after use.
`crate_outline_index_inactive`  | number    | 
`crate_outline_index_active`    | number    | 
`crate_sprite_ping`             | sprite    | 
`crate_col_index`               | number    | 
]]



-- ========== Internal ==========

LootPool.internal.initialize = function()
    -- Populate find table with vanilla pools
    for constant, id in pairs(pool_constants) do
        local namespace = "ror"
        local identifier = constant:lower()

        local struct = Global.treasure_loot_pools:get(id)

        -- Custom properties
        struct.namespace    = namespace
        struct.identifier   = identifier

        __loot_pool_find_table:set(
            {
                wrapper         = LootPool.wrap(id),
                struct          = struct,
                crate_obj       = nil,
                crate_struct    = nil
            },
            identifier, namespace, id
        )
    end

    -- Update cached wrappers
    __loot_pool_find_table:loop_and_update_values(function(value)
        return {
            wrapper         = LootPool.wrap(value.wrapper),
            struct          = value.struct,
            crate_obj       = value.crate_obj,
            crate_struct    = value.crate_struct
        }
    end)
end
table.insert(_rapi_initialize, LootPool.internal.initialize)



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return   LootPool
--@param    identifier      | string    | The identifier for the loot pool.
--[[
Creates a new loot pool with the given identifier if it does not already exist,
or returns the existing one if it does.
]]
LootPool.new = function(NAMESPACE, identifier)
    Initialize.internal.check_if_started("LootPool.new")
    if not identifier then log.error("LootPool.new: No identifier provided", 2) end

    -- Return existing pool if found
    local pool = LootPool.find(identifier, NAMESPACE, true)
    if pool then return pool end

    -- Get next usable ID for pool
    local loot_pools_array = Global.treasure_loot_pools
    local id = #loot_pools_array

    -- Enable capturing with the hooks below
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
    struct.namespace    = NAMESPACE
    struct.identifier   = identifier

    -- Push onto array
    loot_pools_array:push(struct)

    local pool = LootPool.wrap(id)

    -- This is called in TreasureLootPool constructor
    -- if a sprite was provided for the crate
    gm.object_set_depth(crate_obj.value, -289)

    -- Add to find table
    __loot_pool_find_table:set(
        {
            wrapper         = pool,
            struct          = struct,
            crate_obj       = crate_obj,
            crate_struct    = binded_struct
        },
        identifier, NAMESPACE, id
    )

    return pool
end


--@static
--@return   LootPool
--@param    tier            | ItemTier  | The item tier to use as a base.
--[[
Creates a new loot pool using an item tier as a base,
automatically populating the pool's properties and
setting the item tier's `*_pool_for_reroll` properties.
]]
LootPool.new_from_tier = function(NAMESPACE, tier)
    Initialize.internal.check_if_started("LootPool.new_from_tier")
    
    if not tier then log.error("LootPool.new_from_tier: No tier provided", 2) end
    tier = ItemTier.wrap(tier)

    if type(tier.value) ~= "number" then log.error("LootPool.new_from_tier: Invalid tier", 2) end
    
    -- Use existing pool or create a new one
    local pool = LootPool.find(tier.identifier, NAMESPACE, true)
              or LootPool.new(NAMESPACE, tier.identifier)

    -- Set pool properties
    pool.item_tier = tier

    -- Set tier properties
    tier.item_pool_for_reroll       = pool
    tier.equipment_pool_for_reroll  = pool

    return pool
end


--@static
--@return       LootPool or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified loot pool and returns it.
If no namespace is provided, searches in your mod's namespace first, and vanilla pools second.
]]
LootPool.find = function(identifier, namespace, namespace_is_specified)
    -- Check in find table
    local cached = __loot_pool_find_table:get(identifier, namespace, namespace_is_specified)
    if cached then return cached.wrapper end

    return nil
end


--@static
--@return       LootPool
--@param        pool        | number    | The loot pool to wrap.
--[[
Returns an LootPool wrapper containing the provided loot pool.
]]
LootPool.wrap = function(pool)
    -- Input:   number or LootPool wrapper
    -- Wraps:   number
    return make_proxy(Wrap.unwrap(pool), metatable_loot_pool)
end



-- ========== Instance Methods ==========

--@section Instance Methods

methods_loot_pool = {

    --@instance
    --[[
    Prints the loot pool's properties.
    ]]
    print = function(self)
        local struct = __loot_pool_find_table[self.value].struct
        struct:print()
    end,


    --@instance
    --@param        ...         | Item(s)   | A variable number of items. <br>Alternatively, a table may be provided.
    --[[
    Adds an item(s) to the loot pool.
    ]]
    add_item = function(self, ...)
        local t = {...}
        if type(t[1]) == "table" and (not t[1].RAPI) then t = t[1] end

        local drop_pool = List.wrap(self.drop_pool)
        for _, item in ipairs(t) do
            drop_pool:add(Item.wrap(item).object_id)
        end
    end,


    --@instance
    --@param        ...         | Item(s)   | A variable number of items. <br>Alternatively, a table may be provided.
    --[[
    Removes an item(s) from the loot pool.
    ]]
    remove_item = function(self, ...)
        local t = {...}
        if type(t[1]) == "table" and (not t[1].RAPI) then t = t[1] end

        local drop_pool = List.wrap(self.drop_pool)
        for _, item in ipairs(t) do
            drop_pool:delete_value(Item.wrap(item).object_id)
        end
    end,


    --@instance
    --@param        ...         | Equipment | A variable number of equipment. <br>Alternatively, a table may be provided.
    --[[
    Adds (an) equipment to the loot pool.
    ]]
    add_equipment = function(self, ...)
        local t = {...}
        if type(t[1]) == "table" and (not t[1].RAPI) then t = t[1] end

        local drop_pool = List.wrap(self.drop_pool)
        for _, equip in ipairs(t) do
            drop_pool:add(Equipment.wrap(equip).object_id)
        end
    end,


    --@instance
    --@param        ...         | Equipment | A variable number of equipment. <br>Alternatively, a table may be provided.
    --[[
    Removes (an) equipment from the loot pool.
    ]]
    remove_equipment = function(self, ...)
        local t = {...}
        if type(t[1]) == "table" and (not t[1].RAPI) then t = t[1] end

        local drop_pool = List.wrap(self.drop_pool)
        for _, equip in ipairs(t) do
            drop_pool:delete_value(Equipment.wrap(equip).object_id)
        end
    end,


    --@instance
    --@return       Item, Object
    --@optional     required_loot_tags      | number or table   | A bit sum of flags; the chosen item must have at least one. <br>Alternatively, table containing multiple flags can be provided. <br>`0` by default.
    --@optional     disallowed_loot_tags    | number or table   | A bit sum of flags; the chosen item must not have any of these. <br>Alternatively, table containing multiple flags can be provided. <br>`0` by default.
    --[[
    Rolls for a random item from the loot pool, taking
    into account allowed and disallowed loot tags.

    Returns the chosen Item and its pickup object.
    ]]
    roll = function(self, required_loot_tags, disallowed_loot_tags)
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

        local obj_id    = gm.treasure_loot_pool_roll(self.value, required_sum, disallowed_sum)
        local item      = gm.object_to_item(obj_id)

        if item ~= -1 then item = Item.wrap(item)
        else item = nil
        end

        -- Return both the Item wrapper and item pickup object
        return item, Object.wrap(obj_id)
    end,


    --@instance
    --@return       Object
    --[[
    Returns the command crate that was generated alongside this loot pool.
    ]]
    get_crate = function(self)
        return __loot_pool_find_table:get(__proxy[self]).crate_obj
    end

}



-- ========== Metatables ==========

local wrapper_name = "LootPool"

make_table_once("metatable_loot_pool", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return __proxy[proxy] end
        if k == "RAPI" then return wrapper_name end

        -- Methods
        if methods_loot_pool[k] then
            return methods_loot_pool[k]
        end

        -- Getter
        local loot_struct = __loot_pool_find_table:get(__proxy[proxy]).struct
        local ret = loot_struct[k]
        if ret then return ret end

        -- Getter (Crate)
        if k == "crate_sprite" then return proxy:get_crate().obj_sprite end
        local crate_struct = __loot_pool_find_table:get(__proxy[proxy]).crate_struct
        return crate_struct[k:sub(7, -1)]
    end,


    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        local loot_struct = __loot_pool_find_table:get(__proxy[proxy]).struct
        if gm.variable_struct_exists(Wrap.unwrap(loot_struct), k) then
            loot_struct[k] = v
            return
        end

        -- Setter (Crate)
        if k == "crate_sprite" then
            gm.object_get_sprite_w(proxy:get_crate().value, Wrap.unwrap(v))
            return
        end
        local crate_struct = __loot_pool_find_table:get(__proxy[proxy]).crate_struct
        crate_struct[k:sub(7, -1)] = v
    end,

    
    __metatable = "RAPI.Wrapper."..wrapper_name
})



-- ========== Hooks ==========

-- Custom loot pools are not auto-populated by the game on run start

gm.post_script_hook(gm.constants.run_update_available_loot, function(self, other, result, args)
    local pools = Global.treasure_loot_pools

    -- Loop through custom loot pools (ID 7+)
    -- and call update method
    for i = 7, #pools - 1 do
        pools[i].update_available_drop_pool()
    end
end)


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
    binded_struct = GM.method_get_self(args[2].value)
    enable_capture = false
end)



-- Public export
__class.LootPool = LootPool