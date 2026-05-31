-- Equipment

---@class EquipmentClass
Equipment = C["Equipment"]

run_on_initial_load(function()
    P.equipment_is_passive      = {} ---@type table<id, true>
    P.equipment_toggle_loot_off = {} ---@type table<id, object> Equipment that is toggled off from dropping.
end)

local equipment_is_passive = P.equipment_is_passive
local toggle_loot_off      = P.equipment_toggle_loot_off

local proxy              = P.proxy
local metatable          = W["Equipment"]
local find_table_wrapper = P.class_find_tables_wrapper["Equipment"]
local find_table_array   = P.class_find_tables_array["Equipment"]

local type               = type
local math               = math
local gm                 = gm  ---@type table<string, function>
local List               = List
local Global             = Global
local Instance           = Instance
local LootPool           = LootPool
local Achievement        = Achievement
local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class Equipment
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field properties Array The array storing this equipment's properties.
---@field array Array Alias for `.properties`.

---@class Equipment
---@field namespace        string  The namespace the equipment is in.
---@field identifier       string  The identifier for the equipment within the namespace.
---@field token_name       string  The localization token for the equipment's name.
---@field token_text       string  The localization token for the equipment's pickup text.
---@field on_use           number  The ID of the callback that runs when the equipment is activated.
---@field cooldown         number  The cooldown of the equipment (in frames).
---@field tier             number  The tier of the equipment.
---@field sprite_id        sprite  The sprite ID of the equipment.
---@field object_id        object  The object ID of the equipment.
---@field item_log_id      number  The item log ID of the equipment.
---@field achievement_id   number  The achievement ID of the equipment. <br>If *not* `-1`, the equipment will be locked until the achievement is unlocked.
---@field effect_display   unknown
---@field loot_tags        number  The sum of all loot tags applied to the item.
---@field is_new_equipment boolean `true` for new vanilla equipment added in *Returns*.


-- ========== Enums ==========

Equipment.Property = {
    NAMESPACE        = 0,
    IDENTIFIER       = 1,
    TOKEN_NAME       = 2,
    TOKEN_TEXT       = 3,
    ON_USE           = 4,
    COOLDOWN         = 5,
    TIER             = 6,
    SPRITE_ID        = 7,
    OBJECT_ID        = 8,
    ITEM_LOG_ID      = 9,
    ACHIEVEMENT_ID   = 10,
    EFFECT_DISPLAY   = 11,
    LOOT_TAGS        = 12,
    IS_NEW_EQUIPMENT = 13,
}
local t = {}
for name, num in pairs(Equipment.Property) do t[num] = name end
for i = 0, #t do Equipment.Property[i] = t[i] end


-- ========== Static Methods ==========

--[[
Creates a new equipment with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the equipment.
---@return Equipment
Equipment.new = function(NAMESPACE, identifier)
    check_init_started("new")
    if not identifier then throw("No identifier provided", "new") end

    -- Return existing equipment if found
    local equip = Equipment.find(identifier, NAMESPACE, true)
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
    LootPool.wrap(LootPool.EQUIPMENT):add_equipment(equip)

    return equip
end

--[[
Searches for the specified equipment and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return Equipment
Equipment.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all equipment in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>`Equipment.Property.NAMESPACE` by default.
---@return table<number, Equipment>
Equipment.find_all = function(NAMESPACE, filter, property) end

--[[
Returns an equipment wrapper containing the provided equipment ID.
]]
---@param id number | Equipment The equipment to wrap.
---@return Equipment
Equipment.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class Equipment
local methods = G.methods_content["Equipment"]

--[[
Spawns and returns an equipment drop.
]]
---@param x number The x spawn coordinate.
---@param y number The y spawn coordinate.
---@param target? Instance If provided, the drop will move towards the target instance's position. <br>The position is determined on spawn, and does not follow the instance if they move. <br>If `nil`, will drop in a random direction around the spawn location. <br>`nil` by default.
---@param hack_double? boolean If `true`, spawns 2 drops. <br>`false` by default.
---@return Instance
methods.create = function(self, x, y, target, hack_double)
    if not x then throw("x is nil") end
    if not y then throw("y is nil") end

    local object_id = self.object_id
    if object_id == nil or object_id == -1 then return nil end

    -- This function spawns the item 40 px above,
    -- so add 40 to y in the call        
    gm.item_drop_object(object_id, x, y + 40, unwrap(target), hack_double or false)

    -- Look for drop (because gm.item_drop_object does not
    -- actually return the instance for some reason)
    local drop = nil
    local objs = {
        gm.constants.pPickupEquipment,
        gm.constants.oCustomObject_pPickupEquipment,
    }
    for i = 1, 2 do
        local obj = objs[i]
        local drops = Instance.find_all(obj)
        for j = 1, #drops do
            local d = drops[j]
            local drop_data = Instance.get_data(d)
            if math.abs(d.x - x) <= 1 and math.abs(d.y - y) <= 1
            and not drop_data.returned_drop then
                drop = d
                drop_data.returned_drop = true
                break
            end
        end
        if drop then break end
    end

    return drop
end

--[[
Sets the sprite of the equipment.
]]
---@param sprite number | Sprite The sprite to set.
methods.set_sprite = function(self, sprite)
    if not sprite then throw("sprite is nil") end

    sprite = unwrap(sprite)
    self.sprite_id = sprite

    -- Set equipment object sprite
    gm.object_set_sprite_w(self.object_id, sprite)
end

--[[
Sets the tier of the equipment, and assigns it to the appropriate <br>
loot pool (will remove from all previous loot pools).
]]
---@param tier number | ItemTier The @link {tier | ItemTier#constants} to set.
methods.set_tier = function(self, tier)
    if not tier then throw("tier is nil") end
    
    tier = unwrap(tier)
    self.tier = tier

    -- Remove from all loot pools that the equipment is in
    local pools = Global.treasure_loot_pools  ---@type Array
    for _, struct in ipairs(pools) do
        local drop_pool = List.wrap(struct.drop_pool)
        drop_pool:delete_value(self.object_id)
    end

    -- Add to new loot pool (if it exists)
    local pool = ItemTier.wrap(tier).equipment_pool_for_reroll
    if pool ~= -1 then LootPool.wrap(pool):add_equipment(self) end
end

--[[
Returns `true` if this equipment is marked as passive.
]]
---@return boolean
methods.is_passive = function(self)
    return (equipment_is_passive[proxy[self]] == true)
end

--[[
Sets whether or not the equipment is passive (i.e., cannot be activated).
]]
---@param bool boolean `true` (passive) or `false` (active)
methods.set_passive = function(self, bool)
    if bool == nil then throw("Missing bool argument") end
    equipment_is_passive[proxy[self]] = bool
end

--[[
Returns `true` if the equipment is available as a drop in at least one loot pool.
]]
---@return boolean
methods.is_loot = function(self)
    if toggle_loot_off[proxy[self]] then return false end

    --[[
    Out of run: Check if this equipment's object is in `drop_pool`
    In a run:   Check if this equipment's object is in `available_drop_pool` instead
                while in a run just in case that got modified
    ]]
    local which = "drop_pool"
    if Global.__run_exists then which = "available_drop_pool" end

    -- Loop through all pools
    local count = #Global.treasure_loot_pools
    for i = 0, count - 1 do
        local pool = LootPool.wrap(i)
        if List.wrap(pool[which]):contains(self.object_id) then
            return true
        end
    end
    return false
end

--[[
Toggles whether or not the equipment is available to drop from the loot pools it's in.

*Technical:* When `gm.run_update_available_loot` is called, the equipment is removed <br>
from all `available_drop_pool`s if toggled off; `drop_pool` is *not* modified.
]]
---@param bool boolean `true` - The equipment can drop as loot. <br>`false` - The equipment cannot drop as loot.
methods.toggle_loot = function(self, bool)
    if type(bool) ~= "boolean" then throw("bool is invalid") end

    toggle_loot_off[proxy[self]] = nil
    if not bool then toggle_loot_off[proxy[self]] = self.object_id end

    if Global.__run_exists then G.queue_run_update_available_loot = true end
end

--[[
Returns a table of all @link {LootPools | LootPools} the item is in, ignoring @link {`toggle_loot` | Item#toggle_loot}.
]]
---@return table<number, LootPool>
methods.get_loot_pools = function(self)
    -- Loop through all pools
    local pools, i = {}, 1
    for i = 0, #Global.treasure_loot_pools - 1 do
        local pool = LootPool.wrap(i)
        if List.wrap(pool.drop_pool):contains(self.object_id) then
            pools[i] = pool
            i = i + 1
        end
    end
    return pools
end

--[[
Returns a table of all @link {LootPools | LootPools} the item is available to drop from.
]]
---@return table<number, LootPool>
methods.get_available_loot_pools = function(self)
    if toggle_loot_off[proxy[self]] then return {} end

    --[[
    Out of run: Check if this item's object is in `drop_pool`
    In a run:   Check if this item's object is in `available_drop_pool` instead
                while in a run just in case that got modified
    ]]
    local which = "drop_pool"
    if Global.__run_exists then which = "available_drop_pool" end

    -- Loop through all pools
    local pools, j = {}, 1
    for i = 0, #Global.treasure_loot_pools - 1 do
        local pool = LootPool.wrap(i)
        if List.wrap(pool[which]):contains(self.object_id) then
            pools[j] = pool
            j = j + 1
        end
    end
    return pools
end

--[[
Returns the associated @link {Achievement | Achievement} if it exists, <br>
or an invalid Achievement if it does not.
]]
---@return Achievement
methods.get_achievement = function(self)
    return Achievement.wrap(self.achievement_id)
end

--[[
Prints the equipment's properties.
]]
methods.print = function(self) end


-- ========== Hooks ==========

-- Prevent passive equipment use
-- This hook only runs locally
-- Confirmed to work in multiplayer
gm.pre_script_hook(gm.constants.item_use_equipment, function(self, other, result, args)
    ---@type Equipment
    local equipment = self:equipment_get()
    if equipment and equipment_is_passive[proxy[equipment]] then
        return false
    end
end)

-- Remove equipment in `__toggle_loot_off` from all `available_drop_pool`s
gm.post_script_hook(gm.constants.run_update_available_loot, function(self, other, result, args)
    -- Loop through all toggled off
    for _, object_id in pairs(toggle_loot_off) do

        -- Loop through all pools and delete `object_id`
        for i = 0, #Global.treasure_loot_pools - 1 do
            local pool = LootPool.wrap(i)
            List.wrap(pool.available_drop_pool):delete_value(object_id)
        end
    end
end)