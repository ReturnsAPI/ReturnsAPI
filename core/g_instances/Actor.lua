-- Actor

---@class ActorClass
Actor = new_class()
C.Actor = Actor

run_on_initial_load(function()
    P.item_count_cache = {} ---@type table<id, table<item, table<kind, count>>> Stores results from `item_count` for each item and stack kind
    P.buff_count_cache = {} ---@type table<id, table<buff, count>> Stores results from `buff_count` for each buff
end)

local item_count_cache = P.item_count_cache
local buff_count_cache = P.buff_count_cache

local proxy = P.proxy

local type       = type
local math_floor = math.floor
local math_clamp = math.clamp
local math_sign  = math.sign
local gm         = gm   ---@type table<string, function>
local bool       = Util.bool
local unwrap     = Wrap.unwrap

local sNone = gm.constants.sNone  ---@type number


-- ========== Enums ==========

Actor.KnockbackKind = {
    NONE        = 0,    -- Does nothing; do not use
    STANDARD    = 1,    -- Applies stun; actor cannot move horizontally or act, but can jump
    FREEZE      = 2,    -- Frozen color shader vfx; actor cannot move horizontally, but can jump and attack; actor also slides with less friction
    DEEPFREEZE  = 3,    -- Ice cube vfx; actor cannot move horizontally, but can jump and attack; actor also slides with less friction
    PULL        = 4,    -- `STANDARD`, but in the opposite direction
}


-- ========== Wrapper Methods ==========

---@class Actor: Instance
local methods = {}
G.methods_actor = methods

--[[
Returns `true` if the actor is on the ground.
]]
---@return boolean
methods.is_grounded = function(self)
    return not bool(self.free)
end

--[[
Returns `true` if the actor is climbing on a rope.
]]
---@return boolean
methods.is_climbing = function(self)
    return gm.actor_state_is_climb_state(self.actor_state_current_id)
end

--[[
Kills the actor (synced).

**Must be called offline or as host.**
]]
methods.kill = function(self)
    self:actor_kill()
end

--[[
Applies knockback/stun to the actor (synced).

**Must be called offline or as host.**

**Additional note** <br>
Seems to stack effects when called multiple times with different `kind`s. <br>
(Although they must be called in numerical order? Some combinations seem to not work either.)
]]
---@param direction number The direction of knockback. <br>A negative value is left, and a positive value is right <br>(actual value doesn't matter; just use `-1` and `1`).
---@param duration? number The duration of knockback (in frames). <br>`20` by default.
---@param force? number The force of knockback (in some unknown metric). <br>`3` by default.
---@param kind? number The kind of knockback. <br>`Actor.KnockbackKind.STANDARD` (`1`) by default.
methods.apply_knockback = function(self, direction, duration, force, kind)
    gm.actor_knockback_inflict(
        self,
        kind or Actor.KnockbackKind.STANDARD,
        math_sign(direction),
        duration,
        force
    )
end

--[[
Applies DoT (damage over time) to the actor (synced). <br>
Returns the DoT instance.

**Must be called offline or as host.**
]]
---@param damage number The damage dealt per tick. <br>This parameter will be treated as a damage coefficient if `source` is provided.
---@param ticks number The total number of damage ticks.
---@param rate number The number of frames between ticks. <br>(E.g., `6` = 10 ticks per second)
---@param source? Actor The inflictor of the damage.
---@param color? number | Color The color of the damage number. <br>`Color.WHITE` by default.
---@param use_raw_damage? boolean If `true`, damage will *not* be treated as a damage coefficient if `source` is provided. <br>`false` by default.
---@return Instance
methods.apply_dot = function(self, damage, ticks, rate, source, color, use_raw_damage)
    local dot = gm.instance_create(0, 0, gm.constants.oDot)
    dot.target = self
    dot.damage = damage
    if source then
        dot.parent = source
        if not use_raw_damage then
            dot.damage = damage * source.damage
        end
    end
    dot.ticks     = ticks
    dot.rate      = rate
    dot.textColor = color or Color.WHITE
    return dot
end

--[[
Heals the actor (synced).

**Must be called offline or as host.**
]]
---@param amount number The amount to heal.
---@param raw? boolean If `true`, no HUD health bar flash appears (if healing the local <br>player), and Aegis does not proc on overheal. <br>`false` by default.
methods.heal = function(self, amount, raw)
    gm.actor_heal_networked(self.id, amount, raw or false)
end

--[[
Heals the actor's barrier (synced).

**Must be called offline or as host.**
]]
---@param amount number The amount to heal.
methods.heal_barrier = function(self, amount)
    if Net.client then return end
    gm.actor_heal_barrier(self, amount)
end

--[[
Queues the actor's stats to be recalculated next frame. <br>
Prevents running `recalculate_stats` more than once per frame, so it's preferable over calling `recalculate_stats` directly.
]]
methods.queue_recalculate_stats = function(self)
    gm.actor_queue_dirty(self)
end

--[[
Sets a new state for the actor.
]]
---@param state ActorState The state to enter.
methods.set_state = function(self, state)
    gm.actor_set_state(self, unwrap(state))
end

--[[
Sets a new state for the actor (synced).

**Must be called as the local player.**
]]
---@param state ActorState The state to enter.
methods.set_state_networked = function(self, state)
    gm.actor_set_state_networked(self, unwrap(state))
end

--[[
Sets activity values for the actor.
]]
---@param activity number The activity to set.
---@param activity_type? number `0` by default.
methods.set_activity = function(self, activity, activity_type)
    gm.actor_activity_set(self, activity, activity_type)
end

--[[
Fires a bullet attack from the actor, and returns the attack instance. <br>
`.attack_info` will return an AttackInfo.

This can be called from host or client, and automatically syncs. <br>
The attack info can be modified before DamageCalculate callbacks run.
]]
---@param x number The x coordinate of the origin.
---@param y number The y coordinate of the origin.
---@param range number The range of the bullet (in pixels).
---@param direction number The angle to fire the bullet (in degrees).
---@param damage number The damage coefficient of the attack, <br>scaled off of the `actor`'s base damage. <br>`1` is 100% damage.
---@param pierce_multiplier? number Remaining damage is multiplied by this value per pierce. <br>If `nil` or `0`, no piercing happens.
---@param hit_sprite? number | Sprite The sprite to draw on collision with an actor or wall. <br>`nil` by default (no sprite).
---@param tracer? number | Tracer The bullet tracer to use. <br>@link {`Tracer.NONE` | Tracer#constants} by default.
---@param can_proc? boolean If `false` the attack will not proc. <br>`true` by default.
---@return Instance
methods.fire_bullet = function(self, x, y, range, direction, damage, pierce_multiplier, hit_sprite, tracer, can_proc)
    -- If `pierce_multiplier` is a number > 0,
    -- enable piercing for the attack
    local can_pierce = false
    if pierce_multiplier and (pierce_multiplier > 0) then can_pierce = true end

    -- Attack will proc by default
    if can_proc == nil then can_proc = true end

    local inst = gm._mod_attack_fire_bullet(
        self,
        x,
        y,
        range,
        direction,
        damage,
        unwrap(hit_sprite) or sNone,
        can_pierce,
        can_proc
    )

    -- Set attack_info properties
    local attack_info = inst.attack_info    -- Autowraps as AttackInfo
    attack_info.damage_color = Color.WHITE_ALMOST
    if pierce_multiplier then attack_info.damage_degrade = (1 - pierce_multiplier) end
    if tracer            then attack_info.tracer_kind = tracer end

    return inst
end

--[[
Fires an explosion attack from the actor, and returns the attack instance. <br>
`.attack_info` will return an AttackInfo.

This can be called from host or client, and automatically syncs. <br>
The attack info can be modified before DamageCalculate callbacks run.
]]
---@param x number The x coordinate of the origin.
---@param y number The y coordinate of the origin.
---@param width number The width of the explosion, centered at `x` (in pixels).
---@param height number The height of the explosion, centered at `y` (in pixels).
---@param damage number The damage coefficient of the attack, <br>scaled off of the `actor`'s base damage. <br>`1` is 100% damage.
---@param explosion_sprite? sprite The sprite to use for the explosion. <br>`nil` by default (no sprite).
---@param sparks_sprite? sprite The sprite to draw on hit actors. <br>`nil` by default (no sprite).
---@param can_proc? boolean If `false` the attack will not proc. <br>`true` by default.
---@return Instance
methods.fire_explosion = function(self, x, y, width, height, damage, explosion_sprite, sparks_sprite, can_proc)
    -- Attack will proc by default
    if can_proc == nil then can_proc = true end

    local inst = gm._mod_attack_fire_explosion(
        self,
        x,
        y,
        width,
        height,
        damage,
        unwrap(explosion_sprite) or sNone,
        unwrap(sparks_sprite)    or sNone,
        can_proc
    )

    -- Set attack_info properties
    local attack_info = inst.attack_info    -- Autowraps as AttackInfo
    attack_info.damage_color = Color.WHITE_ALMOST

    return inst
end

--[[
Fires an explosion attack from the actor, and returns the attack instance. <br>
`.attack_info` will return an AttackInfo.

This attack is not synced. <br>
The attack info can be modified before DamageCalculate callbacks run.
]]
---@param x number The x coordinate of the origin.
---@param y number The y coordinate of the origin.
---@param width number The width of the explosion, centered at `x` (in pixels).
---@param height number The height of the explosion, centered at `y` (in pixels).
---@param damage number The damage coefficient of the attack, <br>scaled off of the `actor`'s base damage. <br>`1` is 100% damage.
---@param explosion_sprite? sprite The sprite to use for the explosion. <br>`nil` by default (no sprite).
---@param sparks_sprite? sprite The sprite to draw on hit actors. <br>`nil` by default (no sprite).
---@param can_proc? boolean If `false` the attack will not proc. <br>`true` by default.
---@return Instance
methods.fire_explosion_local = function(self, x, y, width, height, damage, explosion_sprite, sparks_sprite, can_proc)
    -- Attack will proc by default
    if can_proc == nil then can_proc = true end

    gm.call("fire_explosion_local", self, nil,
        0,
        x,
        y,
        damage,
        unwrap(sparks_sprite) or sNone,
        2,
        width  / explosion_mask_width,
        height / explosion_mask_height
    )
    local inst = gm.variable_global_get("attack_bullet")  -- The function doesn't return anything

    -- Set attack_info properties
    local attack_info = inst.attack_info    -- Autowraps as AttackInfo
    attack_info.damage_color = Color.WHITE_ALMOST
    attack_info.proc = can_proc

    -- Create explosion sprite manually
    if explosion_sprite then
        local expl = gm.instance_create(x, y, gm.constants.oEfExplosion)
        expl.sprite_index = unwrap(explosion_sprite)
    end

    return inst
end

--[[
Fires a direct attack from the actor, and returns the attack instance. <br>
`.attack_info` will return an AttackInfo.

This can be called from host or client, and automatically syncs. <br>
The attack info can be modified before DamageCalculate callbacks run.
]]
---@param target Instance The target instance of the attack.
---@param damage number The damage coefficient of the attack, <br>scaled off of the `actor`'s base damage. <br>`1` is 100% damage.
---@param direction? number The angle of the attack (in degrees). <br>`0` by default.
---@param x? number The x coordinate. <br>`target.x` by default.
---@param y? number The y coordinate. <br>`target.y` by default.
---@param hit_sprite? sprite The sprite to draw on collision with an actor or wall. <br>`nil` by default (no sprite).
---@param can_proc? boolean If `false` the attack will not proc. <br>`true` by default.
---@return Instance
methods.fire_direct = function(self, target, damage, direction, x, y, hit_sprite, can_proc)
    -- Attack will proc by default
    if can_proc == nil then can_proc = true end

    local inst = gm.call("_mod_attack_fire_direct", nil, nil,
        self,
        target,
        x or target.x,
        y or target.y,
        direction or 0,
        damage,
        unwrap(hit_sprite) or sNone,
        can_proc
    )

    -- Set attack_info properties
    local attack_info = inst.attack_info    -- Autowraps as AttackInfo
    attack_info.damage_color = Color.WHITE_ALMOST

    return inst
end

--[[
Gives stacks of the specified item to the actor.

**Must be called offline or as host.**
]]
---@param item Item The item to give.
---@param count? number The amount of stacks to give. <br>`1` by default.
---@param kind? number The kind of item. <br>`Item.StackKind.NORMAL` by default.
methods.item_give = function(self, item, count, kind)
    item = unwrap(item)
    if type(item) ~= "number" then throw("item is invalid") end
    gm.item_give(self, item, math_floor(count or 1), kind or Item.StackKind.NORMAL)
end

--[[
Takes (removes) stacks of the specified item from the actor.

**Must be called offline or as host.**
]]
---@param item Item The item to take.
---@param count? number The amount of stacks to take. <br>`1` by default.
---@param kind? number The kind of item. <br>`Item.StackKind.NORMAL` by default.
methods.item_take = function(self, item, count, kind)
    item = unwrap(item)
    if type(item) ~= "number" then throw("item is invalid") end
    gm.item_take(self, item, math_floor(count or 1), kind or Item.StackKind.NORMAL)
end

--[[
Returns the number of stacks of the specified item the actor has.
]]
---@param item Item The item to check.
---@param kind? number The kind of item. <br>`Item.StackKind.ANY` by default.
---@return number
methods.item_count = function(self, item, kind)
    local id = self.id

    item = unwrap(item)
    if type(item) ~= "number" then throw("item is invalid") end
    
    -- Build cache subtables if they do not exist
    local kind = kind or Item.StackKind.ANY
    local t_actor = item_count_cache[id]
    if not t_actor then
        t_actor = {}
        item_count_cache[id] = t_actor
    end
    local t_item = t_actor[item]
    if not t_item then
        t_item = {}
        t_actor[item] = t_item
    end

    -- Return from cache if stored
    local value = t_item[kind]
    if value then return value end

    -- Store new value in cache and return
    local count = gm.item_count(self, item, kind)
    t_item[kind] = count
    return count
end

--[[
Returns the actor's current equipment.
]]
---@return Equipment | nil
methods.equipment_get = function(self)
    local equip = gm.equipment_get(self)
    if equip >= 0 then return Equipment.wrap(equip) end
    return nil
end

--[[
Sets the actor's equipment.
]]
---@param equip Equipment The equipment to set. <br>If `-1`, removes equipment.
methods.equipment_set = function(self, equip)
    gm.equipment_set(self, unwrap(equip))
end

--[[
Applies stacks of the specified buff to the actor.

**Must be called offline or as host.**
]]
-- TODO
-- ---@param buff Buff The buff to apply.
-- ---@param duration number The duration of the buff (in frames).
-- ---@param count? number The amount of stacks to apply. <br>`1` by default.
-- methods.buff_apply = function(self, buff, duration, count)
--     buff = unwrap(buff)
--     if type(buff) ~= "number" then throw("buff is invalid") end
--     if not duration then throw("duration is missing") end

--     -- Clamp to max stack or under
--     -- Funny stuff happens if this is exceeded
--     local current   = self:buff_count(buff)
--     local max_stack = Buff.wrap(buff).max_stack
--     count = math_clamp(math_floor(count or 1), 0, max_stack - current)

--     gm.apply_buff(self, buff, duration, count)
-- end

--[[
Applies stacks of the specified buff to the actor.

Application is not synced, and should be used for
buffs that have `client_handles_removal` as `true`.
]]
-- TODO
-- ---@param buff Buff The buff to apply.
-- ---@param duration number The duration of the buff (in frames).
-- ---@param count? number The amount of stacks to apply. <br>`1` by default.
-- methods.buff_apply_local = function(self, buff, duration, count)
--     buff = unwrap(buff)
--     if type(buff) ~= "number" then throw("buff is invalid") end
--     if not duration then throw("duration is missing") end

--     -- Clamp to max stack or under
--     -- Funny stuff happens if this is exceeded
--     local current   = self:buff_count(buff)
--     local max_stack = Buff.wrap(buff).max_stack
--     count = math_clamp(math_floor(count or 1), 0, max_stack - current)

--     gm.apply_buff_internal(self, buff, duration, count)
-- end

--[[
Removes stacks of the specified buff from the actor.

Removal is *not* synced if the buff's `client_handles_removal` is `true`.

**Must be called offline or as host.**
]]
-- TODO
-- ---@param buff Buff The buff to remove.
-- ---@param count? number The amount of stacks to remove. <br>`1` by default.
-- methods.buff_remove = function(self, buff, count)
--     if Net.client then return end

--     count = math_floor(count or 1)

--     -- Argument check
--     buff = unwrap(buff)
--     if type(buff) ~= "number" then throw("buff is invalid") end

--     local current_count = self:buff_count(buff)

--     -- Remove buff entirely if count >= current_count
--     if count >= current_count then
--         gm.remove_buff(self, buff)
--         return
--     end

--     -- Decrease count in array
--     -- Must manually call `recalculate_stats` when doing this
--     local value = current_count - count
--     self.buff_stack:set(buff, value)
--     self:queue_recalculate_stats()

--     if not bool(Buff.wrap(buff).client_handles_removal) then
--         packet_syncBuffStack:send_to_all(self, buff, value)
--     end

--     -- Reset cached value
--     local id = self.id
--     if not buff_count_cache[id] then buff_count_cache[id] = {} end
--     buff_count_cache[id][buff] = nil
-- end

--[[
Removes stacks of the specified buff from the actor.

Removal is not synced, and should be used for
buffs that have `client_handles_removal` as `true`.
]]
-- TODO
-- ---@param buff Buff The buff to remove.
-- ---@param count? number The amount of stacks to remove. <br>`1` by default.
-- methods.buff_remove_local = function(self, buff, count)
--     count = math_floor(count or 1)

--     -- Argument check
--     buff = unwrap(buff)
--     if type(buff) ~= "number" then log.error("buff_remove_local: buff is invalid", 2) end

--     local current_count = self:buff_count(buff)

--     -- Remove buff entirely if count >= current_count
--     if count >= current_count then
--         gm.remove_buff_internal(self, buff)
--         return
--     end

--     -- Decrease count in array
--     -- Must manually call `recalculate_stats` when doing this
--     local value = current_count - count
--     self.buff_stack:set(buff, value)
--     self:queue_recalculate_stats()

--     -- Reset cached value
--     local id = self.id
--     if not buff_count_cache[id] then buff_count_cache[id] = {} end
--     buff_count_cache[id][buff] = nil
-- end

--[[
Returns the number of stacks of the specified buff the actor has.
]]
-- TODO
-- ---@param buff Buff The buff to check.
-- ---@return number
-- methods.buff_count = function(self, buff)
--     local id = self.id

--     -- Argument check
--     buff = unwrap(buff)
--     if type(buff) ~= "number" then log.error("buff_count: buff is invalid", 2) end

--     -- Build cache subtable if it does not exist
--     if not buff_count_cache[id] then buff_count_cache[id] = {} end
    
--     -- Return from cache if stored
--     if buff_count_cache[id][buff] then return buff_count_cache[id][buff] end

--     -- Get buff count from array
--     local array = self.buff_stack
--     if buff >= #array then return 0 end -- Return 0 for custom if array hasn't been resized yet
--     local count = array:get(buff)

--     -- Store in cache and return
--     buff_count_cache[id][buff] = count
--     if count == nil then return 0 end
--     return count
-- end

--[[
Returns the remaining duration (in frames) of the specified buff the actor has.
]]
-- TODO
-- ---@param buff Buff The buff to check.
-- ---@return number
-- methods.buff_get_time = function(self, buff)
--     -- Argument check
--     buff = unwrap(buff)
--     if type(buff) ~= "number" then log.error("buff_get_time: buff is invalid", 2) end

--     return math.max(gm.get_buff_time(self, buff), 0)
-- end

--[[
Sets the remaining duration (in frames) for a specified buff that the actor has.
Does nothing if the actor does not have the buff.

**Must be called offline or as host.**
]]
-- TODO
-- ---@param buff Buff The buff to set.
-- ---@param duration number The duration of the buff (in frames).
-- methods.buff_set_time = function(self, buff, duration)
--     -- Argument check
--     buff = unwrap(buff)
--     if type(buff) ~= "number" then log.error("buff_set_time: buff is invalid", 2) end
--     if not duration then log.error("buff_set_time: duration is missing", 2) end

--     gm.set_buff_time(self, buff, math.max(duration, 0))
-- end

--[[
Sets the remaining duration (in frames) for a specified buff that the actor has.
Does nothing if the actor does not have the buff.

This is not synced, and should be used for
buffs that have `client_handles_removal` as `true`.
]]
-- TODO
-- ---@param buff Buff The buff to set.
-- ---@param duration number The duration of the buff (in frames).
-- methods.buff_set_time_local = function(self, buff, duration)
--     -- Argument check
--     buff = unwrap(buff)
--     if type(buff) ~= "number" then log.error("buff_set_time_local: buff is invalid", 2) end
--     if not duration then log.error("buff_set_time_local: duration is missing", 2) end

--     gm.set_buff_time_nosync(self, buff, math.max(duration, 0))
-- end

-- TODO ActorSkill methods


-- ========== Hooks ==========

-- Reset cache when an item is given/taken
local hooks = {"item_give_internal", "item_take_internal"}

for _, hook in ipairs(hooks) do
    gm.pre_script_hook(gm.constants[hook], function(self, other, result, args)
        local actor_id = args[1].value.id
        local t_actor = item_count_cache[actor_id]
        if not t_actor then return end

        -- Reset entire cached table for that item of the actor
        -- (The table contains cached values for every stack kind)
        local item_id = args[2].value
        t_actor[item_id] = {}
    end)
end