-- ItemTier

ItemTier = new_class()

run_once(function()
    __item_tier_find_table = FindCache.new()
end)



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | The ID of the item tier.
`RAPI`          | string    | The wrapper name.
]]



-- ========== Constants ==========

--@section Constants

--@constants
--[[
COMMON      0
UNCOMMON    1
RARE        2
EQUIPMENT   3
BOSS        4
SPECIAL     5
FOOD        6
NOTIER      7
]]

local tier_constants = {
    COMMON      = 0,
    UNCOMMON    = 1,
    RARE        = 2,
    EQUIPMENT   = 3,
    BOSS        = 4,
    SPECIAL     = 5,
    FOOD        = 6,
    NOTIER      = 7
}

-- Add to ItemTier directly (e.g., ItemTier.COMMON)
for k, v in pairs(tier_constants) do
    ItemTier[k] = v
end



-- ========== Internal ==========

ItemTier.internal.initialize = function()
    -- Populate find table with vanilla tiers
    for constant, tier in pairs(tier_constants) do
        local namespace = "ror"
        local identifier = constant:lower()

        __item_tier_find_table:set(
            {
                wrapper = ItemTier.wrap(tier),
                struct  = Global.item_tiers:get(tier)
            },
            identifier, namespace, tier
        )
    end

    -- Update cached wrappers
    __item_tier_find_table:loop_and_update_values(function(value)
        return {
            wrapper = ItemTier.wrap(value.wrapper),
            struct  = value.struct
        }
    end)
end
table.insert(_rapi_initialize, ItemTier.internal.initialize)



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return   ItemTier
--@param    identifier      | string    | The identifier for the item tier.
--[[
Creates a new item tier with the given identifier if it does not already exist,
or returns the existing one if it does.
]]
ItemTier.new = function(NAMESPACE, identifier)
    Initialize.internal.check_if_started()
    if not identifier then log.error("No identifier provided", 2) end

    -- Return existing tier if found
    local tier = ItemTier.find(identifier, NAMESPACE)
    if tier then return tier end

    local tiers_array = Global.item_tiers
    tier = #tiers_array

    -- Create new struct for tier
    local tier_struct = Struct.new()
    tier_struct.namespace                   = NAMESPACE     -- RAPI custom variable
    tier_struct.identifier                  = identifier    -- RAPI custom variable
    tier_struct.index                       = tier
    tier_struct.text_color                  = "w"
    tier_struct.pickup_color                = Color.WHITE
    tier_struct.pickup_color_bright         = Color.WHITE
    tier_struct.item_pool_for_reroll        = -1
    tier_struct.equipment_pool_for_reroll   = -1
    tier_struct.ignore_fair                 = false
    tier_struct.fair_item_value             = 1
    tier_struct.pickup_particle_type        = -1
    tier_struct.spawn_sound                 = 57    -- wItemDrop_White
    tier_struct.pickup_head_shape           = -1    -- Uncommon uses `global.pItemTierUncommon`, etc.

    -- Push onto array
    tiers_array:push(tier_struct)

    local wrapper = ItemTier.wrap(tier)

    -- Add to find table
    __item_tier_find_table:set(
        {
            wrapper = wrapper,
            struct  = tier_struct
        },
        identifier, NAMESPACE, tier
    )

    return wrapper
end


--@static
--@return       ItemTier or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified item tier and returns it.
If no namespace is provided, searches in your mod's namespace first, and vanilla tiers second.
]]
ItemTier.find = function(identifier, namespace, namespace_is_specified)
    -- Check in find table
    local cached = __item_tier_find_table:get(identifier, namespace, namespace_is_specified)
    if cached then return cached.wrapper end

    return nil
end


--@static
--@return       ItemTier
--@param        tier        | number    | The item tier to wrap.
--[[
Returns an ItemTier wrapper containing the provided item tier.
]]
ItemTier.wrap = function(tier)
    -- Input:   number or ItemTier wrapper
    -- Wraps:   number
    return make_proxy(Wrap.unwrap(tier), metatable_item_tier)
end



-- ========== Instance Methods ==========

--@section Instance Methods

methods_item_tier = {

    --@instance
    --[[
    Prints the item tier's properties.
    ]]
    print_properties = function(self)
        local struct = __item_tier_find_table:get(self.value).struct
        struct:print()
    end

}



-- ========== Metatables ==========

local wrapper_name = "ItemTier"

make_table_once("metatable_item_tier", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return __proxy[proxy] end
        if k == "RAPI" then return wrapper_name end

        -- Methods
        if methods_item_tier[k] then
            return methods_item_tier[k]
        end

        -- Getter
        local struct = __item_tier_find_table:get(__proxy[proxy]).struct
        return struct[k]
    end,


    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        local struct = __item_tier_find_table:get(__proxy[proxy]).struct
        struct[k] = Wrap.unwrap(v)
    end,

    
    __metatable = "RAPI.Wrapper."..wrapper_name
})



-- Public export
__class.ItemTier = ItemTier