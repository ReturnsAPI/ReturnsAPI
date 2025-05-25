-- ItemTier

ItemTier = new_class()

run_once(function()
    __item_tier_find_table = {}
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

ItemTier.internal.initialize = function()
    -- Populate find table with vanilla tiers
    for constant, tier in pairs(tier_constants) do
        local namespace = "ror"
        local identifier = constant:lower()

        local element_table = {
            tier        = tier,
            namespace   = namespace,
            identifier  = identifier,
            struct      = Global.item_tiers:get(tier),
            wrapper     = ItemTier.wrap(tier)
        }
        if not __item_tier_find_table[namespace] then __item_tier_find_table[namespace] = {} end
        __item_tier_find_table[namespace][identifier] = element_table
        __item_tier_find_table[tier] = element_table
    end

    -- Update cached wrappers
    for tier, element_table in pairs(__item_tier_find_table) do
        element_table.wrapper = ItemTier.wrap(element_table.tier)
    end
end



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return   ItemTier
--@param    identifier      | string    | The identifier for the item tier.
--[[
Creates a new item tier with the given identifier if it does not already exist,
or returns the existing one if it does.
]]
ItemTier.new = function(namespace, identifier)
    Initialize.internal.check_if_started()
    if not identifier then log.error("No identifier provided", 2) end

    -- Return existing tier if found
    local tier = ItemTier.find(identifier, namespace)
    if tier then return tier end

    local tiers_array = Global.item_tiers
    tier = #tiers_array

    -- Create new struct for tier
    local tier_struct = Struct.new()
    tier_struct.namespace                   = namespace     -- RAPI custom variable
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
    tier_struct.spawn_sound                 = 57
    tier_struct.pickup_head_shape           = -1    -- This is `nil` in struct 1 and not present in any of the
                                                    -- others(?) but the game will throw an error without it
                                                    -- `-1` seems to work fine
                                                    -- TODO: this is present for the others actually, just
                                                    -- not showing in OB; figure this out sometime

    -- Push onto array
    tiers_array:push(tier_struct)

    -- Add to find table
    local element_table = {
        tier        = tier,
        namespace   = namespace,
        identifier  = identifier,
        struct      = tier_struct,
        wrapper     = ItemTier.wrap(tier)
    }
    if not __item_tier_find_table[namespace] then __item_tier_find_table[namespace] = {} end
    __item_tier_find_table[namespace][identifier] = element_table
    __item_tier_find_table[tier] = element_table

    return element_table.wrapper
end


--@static
--@return       ItemTier or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified item tier and returns it.
If no namespace is provided, searches in your mod's namespace first, and vanilla tiers second.
]]
ItemTier.find = function(identifier, namespace, default_namespace)
    local namespace, is_specified = parse_optional_namespace(namespace, default_namespace)

    -- Search in namespace
    local namespace_table = __item_tier_find_table[namespace]
    if namespace_table then
        local element_table = namespace_table[identifier]
        if element_table then return element_table.wrapper end
    end

    -- Also check vanilla tiers if no namespace arg
    if not is_specified then
        local element_table = __item_tier_find_table["ror"][identifier]
        if element_table then return element_table.wrapper end
    end

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
        local struct = __item_tier_find_table[self.value].struct
        local str = ""
        for k, v in pairs(struct) do
            str = str.."\n"..Util.pad_string_right(k, 32)..Util.tostring(v)
        end
        print(str)
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
        local tier_struct = __item_tier_find_table[__proxy[proxy]].struct
        return tier_struct[k]
    end,


    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        local tier_struct = __item_tier_find_table[__proxy[proxy]].struct
        tier_struct[k] = Wrap.unwrap(v)
    end,

    
    __metatable = "RAPI.Wrapper."..wrapper_name
})



-- Public export
__class.ItemTier = ItemTier