-- ItemTier

-- TODO: Add property docs

ItemTier = new_class()

run_once(function()
    __item_tier_find_table = FindCache.new()
end)



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



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The ID of the item tier.
`RAPI`          | string    | *Read-only.* The wrapper name.

<br>

Property | Type | Description
| - | - | -
`namespace`                 | string    | The namespace the item tier is in.
`identifier`                | string    | The identifier for the item tier within the namespace.
`fair_item_value`           | number    | <br>`0` by default.
`text_color`                | string    | The text formatting color code. <br>`"w"` by default.
`spawn_sound`               | sound     | <br>`wItemDrop_White` by default.
`pickup_color`              | color     | <br>`Color.WHITE` by default.
`pickup_color_bright`       | color     | <br>`Color.WHITE` by default.
`pickup_particle_type`      | number    | <br>`-1` by default.
`pickup_head_shape`         |           | 
`ignore_fair`               | bool      | <br>`false` by default.
`item_pool_for_reroll`      | number    | The ID of the associated item loot pool. <br>`-1` (none) by default.
`equipment_pool_for_reroll` | number    | The ID of the associated equipment loot pool. <br>`-1` (none) by default.
]]



-- ========== Internal ==========

ItemTier.internal.initialize = function()
    -- Populate find table with vanilla tiers
    for constant, id in pairs(tier_constants) do
        local namespace = "ror"
        local identifier = constant:lower()

        local struct = Global.item_tiers:get(id)

        -- Custom properties
        struct.namespace    = namespace
        struct.identifier   = identifier

        __item_tier_find_table:set(
            {
                wrapper = ItemTier.wrap(id),
                struct  = struct
            },
            identifier, namespace, id
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
    Initialize.internal.check_if_started("ItemTier.new")
    if not identifier then log.error("ItemTier.new: No identifier provided", 2) end

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
    struct.namespace    = NAMESPACE
    struct.identifier   = identifier

    -- Push onto array
    tiers_array:push(struct)

    local tier = ItemTier.wrap(id)

    -- Add to find table
    __item_tier_find_table:set(
        {
            wrapper = tier,
            struct  = struct
        },
        identifier, NAMESPACE, id
    )

    return tier
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