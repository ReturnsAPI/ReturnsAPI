-- LootPool

LootPool = new_class()

run_once(function()
    __loot_pool_find_table = {}
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

LootPool.internal.initialize = function()
    -- Populate find table with vanilla pools
    for constant, pool in pairs(pool_constants) do
        local namespace = "ror"
        local identifier = constant:lower()

        local element_table = {
            pool        = pool,
            namespace   = namespace,
            identifier  = identifier,
            struct      = Global.treasure_loot_pools:get(pool),
            wrapper     = LootPool.wrap(pool)
        }
        if not __loot_pool_find_table[namespace] then __loot_pool_find_table[namespace] = {} end
        __loot_pool_find_table[namespace][identifier] = element_table
        __loot_pool_find_table[pool] = element_table
    end

    -- Update cached wrappers
    for tier, element_table in pairs(__loot_pool_find_table) do
        element_table.wrapper = LootPool.wrap(element_table.pool)
    end
end



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return   LootPool
--@param    identifier      | string    | The identifier for the loot pool.
--[[
Creates a new loot pool with the given identifier if it does not already exist,
or returns the existing one if it does.
]]
LootPool.new = function(namespace, identifier)
    Initialize.internal.check_if_started()
    if not identifier then log.error("No identifier provided", 2) end

    -- Return existing pool if found
    local pool = LootPool.find(identifier, namespace)
    if pool then return pool end

    local loot_pools_array = Global.treasure_loot_pools
    pool = #loot_pools_array

    -- Create new struct for pool
    local loot_struct = Struct.new()
    loot_struct.namespace                   = namespace     -- RAPI custom variable
    loot_struct.identifier                  = identifier    -- RAPI custom variable
    loot_struct.index                       = pool
    loot_struct.item_tier                   = 0             -- Common
    loot_struct.drop_pool                   = List.new()
    loot_struct.available_drop_pool         = List.new()
    loot_struct.is_equipment_pool           = false
    loot_struct.command_crate_object_id     = 800           -- White crate

    -- Push onto array
    loot_pools_array:push(loot_struct)

    -- Add to find table
    local element_table = {
        pool        = pool,
        namespace   = namespace,
        identifier  = identifier,
        struct      = loot_struct,
        wrapper     = LootPool.wrap(pool)
    }
    if not __loot_pool_find_table[namespace] then __loot_pool_find_table[namespace] = {} end
    __loot_pool_find_table[namespace][identifier] = element_table
    __loot_pool_find_table[pool] = element_table

    return element_table.wrapper
end


--@static
--@return   LootPool
--@param    tier            | ItemTier  | The item tier to use as a base.
--[[
Creates a new loot pool using an item tier as a base,
automatically populating the pool's properties and
setting the item tier's `_pool_for_reroll` properties.
]]
LootPool.new_from_tier = function(namespace, tier)
    Initialize.internal.check_if_started()
    
    if not tier then log.error("No tier provided", 2) end
    tier = Wrap.unwrap(tier)
    
    -- Create LootPool with same identifier as the item tier
    local tier_lookup = __item_tier_find_table[tier]
    local pool = LootPool.new(namespace, tier_lookup.identifier)

    -- Set pool properties
    pool.item_tier = tier

    -- Set tier properties
    local tier_struct = tier_lookup.struct
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
LootPool.find = function(identifier, namespace, default_namespace)
    local namespace, is_specified = parse_optional_namespace(namespace, default_namespace)

    -- Search in namespace
    local namespace_table = __loot_pool_find_table[namespace]
    if namespace_table then
        local element_table = namespace_table[identifier]
        if element_table then return element_table.wrapper end
    end

    -- Also check vanilla pools if no namespace arg
    if not is_specified then
        local element_table = __loot_pool_find_table["ror"][identifier]
        if element_table then return element_table.wrapper end
    end

    return nil
end


--@static
--@return       LootPool
--@param        pool        | number    | The loot pool to wrap.
--[[
Returns an LootPool wrapper containing the provided loot pool.
]]
LootPool.wrap = function(pool)
    return Proxy.new(Wrap.unwrap(pool), metatable_loot_pool)
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
        local str = ""
        for k, v in pairs(struct) do
            str = str.."\n"..Util.pad_string_right(k, 32)..Util.tostring(v)
        end
        print(str)
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
    --@optional     required_loot_tags      | number or table   | A bit sum of flags; the chosen item must have at least one. <br>Alternatively, table containing multiple flags can be provided. <br>`0` by default.
    --@optional     disallowed_loot_tags    | number or table   | A bit sum of flags; the chosen item must not have any of these. <br>Alternatively, table containing multiple flags can be provided. <br>`0` by default.
    --[[
    Rolls for a random item from the loot pool, taking
    into account allowed and disallowed loot tags.
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
        
        local holder = RValue.new_holder_scr(3)
        holder[0] = RValue.new(self.value)
        holder[1] = RValue.new(required_sum)
        holder[2] = RValue.new(disallowed_sum)
        local out = RValue.new(0)
        gmf.treasure_loot_pool_roll(nil, nil, out, 3, holder)
        local obj_id = out.value

        local holder = RValue.new_holder_scr(1)
        holder[0] = RValue.new(obj_id)
        local out = RValue.new(0)
        gmf.object_to_item(nil, nil, out, 1, holder)
        local item = out.value

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

make_table_once("metatable_loot_pool", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(proxy) end
        if k == "RAPI" then return getmetatable(proxy):sub(14, -1) end

        -- Methods
        if methods_loot_pool[k] then
            return methods_loot_pool[k]
        end

        -- Getter
        local loot_struct = __loot_pool_find_table[Proxy.get(proxy)].struct
        return loot_struct[k]
    end,


    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        local loot_struct = __loot_pool_find_table[Proxy.get(proxy)].struct
        loot_struct[k] = Wrap.unwrap(v)
    end,

    
    __metatable = "RAPI.Wrapper.LootPool"
})



-- ========== Hooks ==========

-- Custom loot pools are not auto-populated by the game

memory.dynamic_hook("RAPI.LootPool.run_create", "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.run_create),
    -- Pre-hook
    {nil,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
        local size = #Global.treasure_loot_pools
    
        -- Loop through custom loot pools (ID 7+)
        for i = 7, size - 1 do
            local pool_struct = __loot_pool_find_table[i].struct
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
    end}
)



-- Public export
__class.LootPool = LootPool