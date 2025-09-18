-- Equipment

local name_rapi = class_name_g2r["class_equipment"]
Equipment = __class[name_rapi]

run_once(function()
    __equipment_is_passive = {}
end)



-- ========== Enums ==========

--@section Enums

--@enum
--@name Property
--[[
NAMESPACE           0
IDENTIFIER          1
TOKEN_NAME          2
TOKEN_TEXT          3
ON_USE              4
COOLDOWN            5
TIER                6
SPRITE_ID           7
OBJECT_ID           8
ITEM_LOG_ID         9
ACHIEVEMENT_ID      10
EFFECT_DISPLAY      11
LOOT_TAGS           12
IS_NEW_EQUIPMENT    13
]]



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The equipment ID being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.

<br>

Property | Type | Description
| - | - | -
`namespace`          | string    | The namespace the equipment is in.
`identifier`         | string    | The identifier for the equipment within the namespace.
`token_name`         | string    | The localization token for the equipment's name.
`token_text`         | string    | The localization token for the equipment's pickup text.
`on_use`             | number    | The ID of the callback that runs when the equipment is activated.
`cooldown`           | number    | The cooldown of the equipment (in frames).
`tier`               | number    | The tier of the equipment.
`sprite_id`          | sprite    | The sprite ID of the equipment.
`object_id`          | object    | The object ID of the equipment.
`item_log_id`        | number    | The item log ID of the equipment.
`achievement_id`     | number    | The achievement ID of the equipment. <br>If *not* `-1`, the equipment will be locked until the achievement is unlocked.
`effect_display`     |           | 
`loot_tags`          | number    | The sum of all loot tags applied to the item.
`is_new_equipment`   | bool      | `true` for new vanilla equipment added in *Returns*.
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return   Equipment
--@param    identifier  | string    | The identifier for the equipment.
--[[
Creates a new equipment with the given identifier if it does not already exist,
or returns the existing one if it does.
]]
Equipment.new = function(NAMESPACE, identifier)
    Initialize.internal.check_if_started()
    if not identifier then log.error("No identifier provided", 2) end

    -- Return existing equipment if found
    local equip = Equipment.find(identifier, NAMESPACE)
    if equip then return equip end

    -- Create new
    equip = Equipment.wrap(gm.equipment_create(
        NAMESPACE,
        identifier,
        #Class.Equipment,   -- equip ID; *not* auto-set by the game
        ItemTier.EQUIPMENT,
        gm.object_add_w(NAMESPACE, identifier, gm.constants.pPickupEquipment),
        0,      -- loot_tags (?)
        nil,    -- ?
        45      -- cooldown (in seconds)
        -- true,   -- make log
        -- 6,      -- log group
        -- nil,    -- ?
        -- nil     -- ?
    ))

    -- Have to manually increase this variable for
    -- some reason (`class_equipment` array length)
    Global.count_equipment = Global.count_equipment + 1

    -- Remove `is_new_equipment` flag
    equip.is_new_equipment = false

    -- Add to Equipment loot pool by default
    local pool = ItemTier.wrap(ItemTier.EQUIPMENT).equipment_pool_for_reroll
    if pool ~= -1 then LootPool.wrap(pool):add_equipment(equip) end

    return equip
end


--@static
--@name         find
--@return       Equipment or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified equipment and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]


--@static
--@name         find_all
--@return       table
--@param        filter      |           | The filter to search by.
--@optional     property    | number    | The property to check. <br>@link {`Equipment.Property.NAMESPACE` | Equipment#Property} by default.
--[[
Returns a table of equipment matching the specified filter and property

**NOTE:** Filtering by a non-namespace property is *very slow*!
Try not to do that too much.
]]


--@static
--@name         wrap
--@return       Equipment
--@param        equip_id    | number    | The equipment ID to wrap.
--[[
Returns an Equipment wrapper containing the provided equipment ID.
]]



-- ========== Instance Methods ==========

--@section Instance Methods

Util.table_append(methods_class_array[name_rapi], {

    --@instance
    --@name         print_properties
    --[[
    Prints the equipment's properties.
    ]]


    --@instance
    --@return       Instance
    --@param        x           | number    | The x spawn coordinate.
    --@param        y           | number    | The y spawn coordinate.
    --@optional     target      | Instance  | If provided, the drop will move towards the target instance's position. <br>The position is determined on spawn, and does not follow the instance if they move. <br>If `nil`, will drop in a random direction around the spawn location.
    --[[
    Spawns and returns an equipment drop.
    ]]
    create = function(self, x, y, target)
        local object_id = self.object_id
        if object_id == nil or object_id == -1 then return nil end

        -- This function spawns the item 40 px above, so add 40 to y in the call
        gm.item_drop_object(object_id, x, y + 40, Wrap.unwrap(target), false)

        -- Look for drop (because gm.item_drop_object does not actually return the instance for some reason)
        local drop = nil
        local objs = {gm.constants.pPickupEquipment, gm.constants.oCustomObject_pPickupEquipment}
        for _, obj in ipairs(objs) do
            local drops = Instance.find_all(obj)
            for _, d in ipairs(drops) do
                local dData = Instance.get_data(d)
                if math.abs(d.x - x) <= 1 and math.abs(d.y - y) <= 1
                and (not dData.returned_drop) then
                    drop = d
                    dData.returned_drop = true
                    break
                end
            end
            if drop then break end
        end

        return drop
    end,


    --@instance
    --@param        sprite      | Sprite    | The sprite to set.
    --[[
    Sets the sprite of the equipment.
    ]]
    set_sprite = function(self, sprite)
        sprite = Wrap.unwrap(sprite)
        self.sprite_id = sprite
    
        -- Set equipment object sprite
        gm.object_set_sprite_w(self.object_id, sprite)
    end,


    --@instance
    --@param        tier        | number   | The @link {tier | ItemTier#constants} to set.
    --[[
    Sets the tier of the equipment, and assigns it to the appropriate
    loot pool (will remove from all previous loot pools).
    ]]
    set_tier = function(self, tier)
        tier = Wrap.unwrap(tier)
        self.tier = tier

        -- Remove from all loot pools that the equipment is in
        local pools = Global.treasure_loot_pools    -- Array
        for _, struct in ipairs(pools) do
            local drop_pool = List.wrap(struct.drop_pool)
            drop_pool:delete_value(self.object_id)
        end

        -- Add to new loot pool (if it exists)
        local pool = ItemTier.wrap(tier).equipment_pool_for_reroll
        if pool ~= -1 then LootPool.wrap(pool):add_equipment(self) end
    end,


    --@instance
    --@param        ...         | number(s) | A variable number of @link {loot tags | Item#LootTag} to add.
    --[[
    Sets the loot tags of the equipment.
    ]]
    set_loot_tags = function(self, ...)
        local args = {...}
        if type(args[1]) == "table" then args = args[1] end

        -- Sum variable number of tags
        local tags = 0
        for _, tag in ipairs(args) do tags = tags + tag end

        self.loot_tags = tags
    end,


    --@instance
    --@return       bool
    --[[
    Returns `true` if this equipment is marked as passive.
    ]]
    is_passive = function(self)
        return (__equipment_is_passive[self.value] == true)
    end,


    --@instance
    --@param        bool        | bool      | `true` (passive) or `false` (active)
    --[[
    Sets whether or not the equipment is passive (i.e., cannot be activated).
    ]]
    set_passive = function(self, bool)
        if bool == nil then log.error("set_passive: bool argument expected", 2) end
        __equipment_is_passive[self.value] = bool
    end,

})



-- ========== Hooks ==========

-- Prevent passive equipment use
-- This hook only runs locally
-- Confirmed to work in multiplayer

gm.pre_script_hook(gm.constants.item_use_equipment, function(self, other, result, args)
    local equipment = Instance.wrap(self.id):equipment_get()
    if equipment and __equipment_is_passive[equipment.value] then
        return false
    end
end)