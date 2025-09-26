-- LootPool

LootPool = new_class()

run_once(function()
    __loot_pool_find_table = FindCache.new()
end)



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



-- ========== Internal ==========

LootPool.internal.initialize = function()
    -- Populate find table with vanilla pools
    for constant, pool in pairs(pool_constants) do
        local namespace = "ror"
        local identifier = constant:lower()

        __loot_pool_find_table:set(
            {
                wrapper = LootPool.wrap(pool),
                struct  = Global.treasure_loot_pools:get(pool)
            },
            identifier, namespace, pool
        )
    end

    -- Update cached wrappers
    __loot_pool_find_table:loop_and_update_values(function(value)
        return {
            wrapper = LootPool.wrap(value.wrapper),
            struct  = value.struct
        }
    end)
end
table.insert(_rapi_initialize, LootPool.internal.initialize)



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The ID of the loot pool.
`RAPI`          | string    | *Read-only.* The wrapper name.
]]



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
    Initialize.internal.check_if_started()
    if not identifier then log.error("No identifier provided", 2) end

    -- Return existing pool if found
    local pool = LootPool.find(identifier, NAMESPACE)
    if pool then return pool end

    local loot_pools_array = Global.treasure_loot_pools
    pool = #loot_pools_array

    -- Create new struct for pool
    local loot_struct = Struct.new{
        namespace                   = NAMESPACE,    -- RAPI custom variable
        identifier                  = identifier,   -- RAPI custom variable
        index                       = pool,
        item_tier                   = 0,            -- Common
        drop_pool                   = List.new(),
        available_drop_pool         = List.new(),
        is_equipment_pool           = false,
        command_crate_object_id     = 800           -- White crate
    }

    -- Push onto array
    loot_pools_array:push(loot_struct)

    local wrapper = LootPool.wrap(pool)

    -- Add to find table
    __loot_pool_find_table:set(
        {
            wrapper = wrapper,
            struct  = loot_struct
        },
        identifier, NAMESPACE, pool
    )

    return wrapper
end


--@static
--@return   LootPool
--@param    tier            | ItemTier  | The item tier to use as a base.
--[[
Creates a new loot pool using an item tier as a base,
automatically populating the pool's properties and
setting the item tier's `_pool_for_reroll` properties.
]]
LootPool.new_from_tier = function(NAMESPACE, tier)
    Initialize.internal.check_if_started()
    
    if not tier then log.error("No tier provided", 2) end
    tier = Wrap.unwrap(tier)
    
    -- Create LootPool with same identifier as the item tier
    local tier_table = __item_tier_find_table:get(tier)
    local pool = LootPool.new(NAMESPACE, tier_table.wrapper.identifier)

    -- Set pool properties
    pool.item_tier = tier

    -- Set tier properties
    local tier_struct = tier_table.struct
    tier_struct.item_pool_for_reroll        = pool.value
    tier_struct.equipment_pool_for_reroll   = pool.value

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
    print_properties = function(self)
        local struct = __loot_pool_find_table[self.value].struct
        struct:print()
    end,


    --@instance
    --@param        item        | Item      | The item to add.
    --[[
    Adds an item to the loot pool.
    ]]
    add_item = function(self, item)
        List.wrap(self.drop_pool):add(Item.wrap(item).object_id)
    end,


    --@instance
    --@param        item        | Item      | The item to remove.
    --[[
    Removes an item from the loot pool.
    ]]
    remove_item = function(self, item)
        List.wrap(self.drop_pool):delete_value(Item.wrap(item).object_id)
    end,


    --@instance
    --@param        equip       | Equipment | The equipment to add.
    --[[
    Adds an equipment to the loot pool.
    ]]
    add_equipment = function(self, equip)
        List.wrap(self.drop_pool):add(Equipment.wrap(equip).object_id)
    end,


    --@instance
    --@param        equip       | Equipment | The equipment to remove.
    --[[
    Removes an equipment from the loot pool.
    ]]
    remove_equipment = function(self, equip)
        List.wrap(self.drop_pool):delete_value(Equipment.wrap(equip).object_id)
    end,


    --@instance
    --@return       Item, number
    --@optional     required_loot_tags      | number or table   | A bit sum of flags; the chosen item must have at least one. <br>Alternatively, table containing multiple flags can be provided. <br>`0` by default.
    --@optional     disallowed_loot_tags    | number or table   | A bit sum of flags; the chosen item must not have any of these. <br>Alternatively, table containing multiple flags can be provided. <br>`0` by default.
    --[[
    Rolls for a random item from the loot pool, taking
    into account allowed and disallowed loot tags.

    Returns the chosen Item and the `object_index` of its drop.
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

        -- Return both the Item wrapper and item object_index
        return item, obj_id
    end,


    new_command_crate = function(self)
        -- TODO generates a new command crate object for the loot pool and sets `command_crate_object_id`
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
        return loot_struct[k]
    end,


    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        local loot_struct = __loot_pool_find_table:get(__proxy[proxy]).struct
        loot_struct[k] = Wrap.unwrap(v)
    end,

    
    __metatable = "RAPI.Wrapper."..wrapper_name
})



-- ========== Hooks ==========

-- Custom loot pools are not auto-populated by the game

gm.post_script_hook(gm.constants.run_create, function(self, other, result, args)
    local size = #Global.treasure_loot_pools

    -- Loop through custom loot pools (ID 7+)
    for i = 7, size - 1 do
        local pool_struct = __loot_pool_find_table:get(i).struct
        local drop_pool = List.wrap(pool_struct.drop_pool)

        -- Clear available_drop_pool
        local available_drop_pool = List.wrap(pool_struct.available_drop_pool)
        available_drop_pool:clear()

        -- Insert item objects from drop_pool to available_drop_pool
        local list_size = #drop_pool
        for j = 0, list_size - 1 do
            local item_obj = drop_pool:get(j)

            -- TODO check if item is unlocked first

            available_drop_pool:add(item_obj)
        end
    end
end)



-- Public export
__class.LootPool = LootPool