-- Actor

--[[
Actor wrappers are "children" of @link {`Instance` | Instance}, and can use its properties and instance methods.
]]

Actor = new_class()

run_once(function()
    __item_count_cache = {} -- Stores results from `item_count` for each item and stack kind
    __buff_count_cache = {} -- Stores results from `buff_count` for each buff
end)



-- ========== Enums ==========

--@section Enums

--@enum
Actor.KnockbackKind = {
    NONE        = 0,    -- Does nothing; do not use
    STANDARD    = 1,    -- Applies stun; actor cannot move horizontally or act, but can jump
    FREEZE      = 2,    -- Frozen color shader vfx; actor cannot move horizontally, but can jump and attack; actor also slides with less friction
    DEEPFREEZE  = 3,    -- Ice cube vfx; actor cannot move horizontally, but can jump and attack; actor also slides with less friction
    PULL        = 4     -- STANDARD, but in the opposite direction
}



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`/`id`    | number    | *Read-only.* The instance ID of the Actor.
`RAPI`          | string    | *Read-only.* The wrapper name.
`cinstance`     | CInstance | *Read-only.* The `sol.CInstance*` of the Actor.

<br>

Notable variables belonging to actors.
TODO populate with more

Variable                | Type          | Description
| --------------------- | ------------- | -----------
`hp`                    | number        | The current health of the actor.
`maxhp`                 | number        | The maximum health of the actor.
`maxhp_base`            | number        | The starting maximum health of the actor.
`maxhp_level`           | number        | The maximum health gained from each level up.
`maxhp_cap`             | number        | The cap for maximum health. <br>`9999` by default.
`infusion_hp`           | number        | The amount of maximum health this actor has gained from Infusion.
`shield`                | number        | The current shield of the actor.
`maxshield`             | number        | The maximum shield of the actor.
`barrier`               | number        | The barrier of the actor.
`maxbarrier`            | number        | The maximum barrier of the actor.
`armor`                 | number        | The armor of the actor.
`armor_base`            | number        | The starting armor of the actor.
`armor_level`           | number        | The armor gained from each level up.
`damage`                | number        | The damage of the actor.
`damage_base`           | number        | The starting damage of the actor.
`damage_level`          | number        | The damage gained from each level up.
`critical_chance`       | number        | The critical chance of the actor. <br>E.g., `7` = 7% critical chance
`critical_chance_base`  | number        | The starting critical chance of the actor.
`critical_chance_level` | number        | The critical chance gained from each level up.
`attack_speed`          | number        | The attack speed of the actor. <br>E.g., `1.4` = +40% attack speed from base
`attack_speed_base`     | number        | The starting attack speed of the actor.
`attack_speed_level`    | number        | The attack speed gained from each level up.
`pHspeed`               | number        | The horizontal velocity of the actor.
`pHmax`                 | number        | The maximum horizontal velocity of the actor.
`pVspeed`               | number        | The vertical velocity of the actor.
`pVmax`                 | number        | The maximum vertical velocity of the actor.
`pGravity1`             | number        | Gravity applied to the actor's `pVspeed`.
`pGravity1_base`        | number        | The starting `pGravity1`.
`pGravity2`             | number        | Gravity applied to the actor's `pGravity1`.
`pGravity2_base`        | number        | The starting `pGravity2`.
`pAccel`                | number        | The acceleration of the actor.
`pAccel_base`           | number        | The starting acceleration of the actor.
`pFriction`             | number        | The friction of the actor. <br>Affects `pHspeed`.
`level`                 | number        | The level of the actor.
`free`                  | bool          | `false` if the actor is grounded, and <br>`true` otherwise (in the air, climbing, etc.)
`team`                  | number        | The team the actor is on.
`invincible`            | number        | If more than `0`, the actor is "IMMUNE". <br>If more than `1000`, the actor is "INVINCIBLE". <br>Ticks down by `1` per frame. <br><br>This is a bool value when set by <br>Commando's roll for some reason.
`still_timer`           | number        | The amount of time the actor has been still (in frames) <br>(i.e., no moving, attacking, etc.) <br>Resets to `0` on acting.
`stunned`               | bool          | `true` if the actor is stunned.
]]



-- ========== Internal ==========

-- For `fire_explosion_local`
local explosion_mask        = gm.constants.sBite1Mask
local explosion_mask_width  = gm.sprite_get_width(explosion_mask)
local explosion_mask_height = gm.sprite_get_height(explosion_mask)



-- ========== Instance Methods ==========

--@section Instance Methods

methods_actor = {

    --@instance
    --@return       bool
    --[[
    Returns `true` if the actor is on the ground.
    ]]
    is_grounded = function(self)
        return (not Util.bool(self.free))
    end,


    --@instance
    --@return       bool
    --[[
    Returns `true` if the actor is climbing on a rope.
    ]]
    is_climbing = function(self)
        return gm.actor_state_is_climb_state(self.actor_state_current_id)
    end,


    --@instance
    --@return       Instance
    --@param        x                   | number    | The x coordinate of the origin.
    --@param        y                   | number    | The y coordinate of the origin.
    --@param        range               | number    | The range of the bullet (in pixels).
    --@param        direction           | number    | The angle to fire the bullet (in degrees).
    --@param        damage              | number    | The damage coefficient of the attack, <br>scaled off of the `actor`'s base damage. <br>`1` is 100% damage.
    --@optional     pierce_multiplier   | number    | Remaining damage is multiplied by this value per pierce. <br>If `nil` or `0`, no piercing happens.
    --@optional     hit_sprite          | sprite    | The sprite to draw on collision with an actor or wall. <br>`nil` by default (no sprite).
    --@optional     tracer              | Tracer    | The bullet tracer to use. <br>@link {`Tracer.NONE` | Tracer#constants} by default.
    --@optional     can_proc            | bool      | If `false` the attack will not proc. <br>`true` by default.
    --[[
    Fires a bullet attack from the actor, and returns the attack instance.
    `.attack_info` will return an AttackInfo.
    
    This can be called from host or client, and automatically syncs.
    The attack info can be modified before DamageCalculate callbacks run.
    ]]
    fire_bullet = function(self, x, y, range, direction, damage, pierce_multiplier, hit_sprite, tracer, can_proc)
        -- If `pierce_multiplier` is a number > 0,
        -- enable piercing for the attack
        local can_pierce = false
        if pierce_multiplier and (pierce_multiplier > 0) then can_pierce = true end

        -- Attack will proc by default
        if can_proc == nil then can_proc = true end

        local inst = Instance.wrap(
            gm._mod_attack_fire_bullet(
                self.value,
                x,
                y,
                range,
                direction,
                damage,
                hit_sprite or gm.constants.sNone,
                can_pierce,
                can_proc
            )
        )

        -- Set attack_info properties
        local attack_info = inst.attack_info    -- Autowraps as AttackInfo
        attack_info.damage_color = Color.WHITE_ALMOST
        if pierce_multiplier    then attack_info.damage_degrade = (1 - pierce_multiplier) end
        if tracer               then attack_info.tracer_kind = tracer end

        return inst
    end,


    --@instance
    --@return       Instance
    --@param        x                   | number    | The x coordinate of the origin.
    --@param        y                   | number    | The y coordinate of the origin.
    --@param        width               | number    | The width of the explosion, centered at `x` (in pixels).
    --@param        height              | number    | The height of the explosion, centered at `y` (in pixels).
    --@param        damage              | number    | The damage coefficient of the attack, <br>scaled off of the `actor`'s base damage. <br>`1` is 100% damage.
    --@optional     explosion_sprite    | sprite    | The sprite to use for the explosion. <br>`nil` by default (no sprite).
    --@optional     sparks_sprite       | sprite    | The sprite to draw on hit actors. <br>`nil` by default (no sprite).
    --@optional     can_proc            | bool      | If `false` the attack will not proc. <br>`true` by default.
    --[[
    Fires an explosion attack from the actor, and returns the attack instance.
    `.attack_info` will return an AttackInfo.

    This can be called from host or client, and automatically syncs.
    The attack info can be modified before DamageCalculate callbacks run.
    ]]
    fire_explosion = function(self, x, y, width, height, damage, explosion_sprite, sparks_sprite, can_proc)
        local id = self.value

        -- Attack will proc by default
        if can_proc == nil then can_proc = true end

        local inst = Instance.wrap(
            gm._mod_attack_fire_explosion(
                self.value,
                x,
                y,
                width,
                height,
                damage,
                explosion_sprite or gm.constants.sNone,
                sparks_sprite or gm.constants.sNone,
                can_proc
            )
        )

        -- Set attack_info properties
        local attack_info = inst.attack_info    -- Autowraps as AttackInfo
        attack_info.damage_color = Color.WHITE_ALMOST

        return inst
    end,


    --@instance
    --@return       Instance
    --@param        x                   | number    | The x coordinate of the origin.
    --@param        y                   | number    | The y coordinate of the origin.
    --@param        width               | number    | The width of the explosion, centered at `x` (in pixels).
    --@param        height              | number    | The height of the explosion, centered at `y` (in pixels).
    --@param        damage              | number    | The damage coefficient of the attack, <br>scaled off of the `actor`'s base damage. <br>`1` is 100% damage.
    --@optional     explosion_sprite    | sprite    | The sprite to use for the explosion. <br>`nil` by default (no sprite).
    --@optional     sparks_sprite       | sprite    | The sprite to draw on hit actors. <br>`nil` by default (no sprite).
    --@optional     can_proc            | bool      | If `false` the attack will not proc. <br>`true` by default.
    --[[
    Fires an explosion attack from the actor, and returns the attack instance.
    `.attack_info` will return an AttackInfo.

    This attack is not synced.
    The attack info can be modified before DamageCalculate callbacks run.
    ]]
    fire_explosion_local = function(self, x, y, width, height, damage, explosion_sprite, sparks_sprite, can_proc)
        local id = self.value

        -- Attack will proc by default
        if can_proc == nil then can_proc = true end

        gm.call("fire_explosion_local",
            self.cinstance, -- self
            nil,            -- other
            0,
            x,
            y,
            damage,
            sparks_sprite or gm.constants.sNone,
            2,
            width / explosion_mask_width,
            height / explosion_mask_height
        )
        local inst = Global.attack_bullet   -- The function doesn't return anything

        -- Set attack_info properties
        local attack_info = inst.attack_info    -- Autowraps as AttackInfo
        attack_info.damage_color = Color.WHITE_ALMOST
        attack_info.proc = can_proc

        -- Create explosion sprite manually
        if explosion_sprite then
            gm.instance_create(x, y, gm.constants.oEfExplosion).sprite_index = explosion_sprite
        end

        return inst
    end,


    --@instance
    --@return       Instance
    --@param        target              | Instance  | The target instance of the attack.
    --@param        damage              | number    | The damage coefficient of the attack, <br>scaled off of the `actor`'s base damage. <br>`1` is 100% damage.
    --@optional     direction           | number    | The angle of the attack (in degrees). <br>`0` by default.
    --@optional     x                   | number    | The x coordinate. <br>`target.x` by default.
    --@optional     y                   | number    | The y coordinate. <br>`target.y` by default.
    --@optional     hit_sprite          | sprite    | The sprite to draw on collision with an actor or wall. <br>`nil` by default (no sprite).
    --@optional     can_proc            | bool      | If `false` the attack will not proc. <br>`true` by default.
    --[[
    Fires a direct attack from the actor, and returns the attack instance.
    `.attack_info` will return an AttackInfo.

    This can be called from host or client, and automatically syncs.
    The attack info can be modified before DamageCalculate callbacks run.
    ]]
    fire_direct = function(self, target, damage, direction, x, y, hit_sprite, can_proc)
        local id = self.value

        -- Attack will proc by default
        if can_proc == nil then can_proc = true end

        local inst = Instance.wrap(
            gm._mod_attack_fire_direct(
                self.value,
                Wrap.unwrap(target),
                x or target.x,
                y or target.y,
                direction or 0,
                damage,
                hit_sprite or gm.constants.sNone,
                can_proc
            )
        )

        -- Set attack_info properties
        local attack_info = inst.attack_info    -- Autowraps as AttackInfo
        attack_info.damage_color = Color.WHITE_ALMOST

        return inst
    end,


    --@instance
    --@param        direction   | number    | The direction of knockback. <br>`-1` is left, and `1` is right. <br>Other values will stretch/compress the sprite horizontally.
    --@optional     duration    | number    | The duration of knockback (in frames). <br>`20` by default.
    --@optional     force       | number    | The force of knockback (in some unknown metric). <br>`3` by default.
    --@optional     kind        | number    | The @link {kind | Actor#KnockbackKind} of knockback. <br>`Actor.KnockbackKind.STANDARD` (`1`) by default.
    --[[
    Applies knockback (stun) to the actor.
    This can only be called from host, but automatically syncs.

    **Additional note**
    Seems to stack effects when called multiple times with different `kind`s.
    (Although they must be called in numerical order? Some combinations seem to not work either.)
    ]]
    apply_knockback = function(self, direction, duration, force, kind)
        gm.actor_knockback_inflict(
            self.value,
            kind or Actor.KnockbackKind.STANDARD,
            direction,
            duration,
            force
        )
    end,

    
    --@instance
    --@param        item        | Item      | The item to give.
    --@optional     count       | number    | The amount of stacks to give. <br>`1` by default.
    --@optional     kind        | number    | The @link {kind | Item#StackKind} of item. <br>`Item.StackKind.NORMAL` by default.
    --[[
    Gives stacks of the specified item to the actor.
    ]]
    item_give = function(self, item, count, kind)
        -- Argument check
        item = Wrap.unwrap(item)
        if type(item) ~= "number" then log.error("item_give: item is invalid", 2) end

        gm.item_give(self.value, item, count or 1, kind or Item.StackKind.NORMAL)
    end,


    --@instance
    --@param        item        | Item      | The item to take.
    --@optional     count       | number    | The amount of stacks to take. <br>`1` by default.
    --@optional     kind        | number    | The @link {kind | Item#StackKind} of item. <br>`Item.StackKind.NORMAL` by default.
    --[[
    Takes (removes) stacks of the specified item from the actor.
    ]]
    item_take = function(self, item, count, kind)
        -- Argument check
        item = Wrap.unwrap(item)
        if type(item) ~= "number" then log.error("item_give: item is invalid", 2) end

        gm.item_take(self.value, item, count or 1, kind or Item.StackKind.NORMAL)
    end,


    --@instance
    --@return       number
    --@param        item        | Item      | The item to check.
    --@optional     kind        | number    | The @link {kind | Item#StackKind} of item. <br>`Item.StackKind.NORMAL` by default.
    --[[
    Returns the number of stacks of the specified item the actor has.
    ]]
    item_count = function(self, item, kind)
        local id = self.value
        
        -- Argument check
        item = Wrap.unwrap(item)
        if type(item) ~= "number" then log.error("item_give: item is invalid", 2) end

        -- Build cache subtable if existn't
        local kind = kind or Item.StackKind.ANY
        if not __item_count_cache[id] then __item_count_cache[id] = {} end
        if not __item_count_cache[id][item] then __item_count_cache[id][item] = {} end

        -- Return from cache if stored
        if __item_count_cache[id][item][kind] then return __item_count_cache[id][item][kind] end

        local count = gm.item_count(id, item, kind or Item.StackKind.NORMAL)

        -- Store in cache and return
        __item_count_cache[id][item][kind] = count
        return count
    end,


    --@instance
    --@param        buff        | Buff      | The buff to apply.
    --@param        duration    | number    | The duration of the buff (in frames).
    --@optional     count       | number    | The amount of stacks to apply. <br>`1` by default.
    --[[
    Applies stacks of the specified buff to the actor.
    ]]
    buff_apply = function(self, buff, duration, count)
        -- Argument check
        buff = Wrap.unwrap(buff)
        if type(buff) ~= "number" then log.error("buff_apply: buff is invalid", 2) end
        if not duration then log.error("buff_apply: duration is missing", 2) end

        -- * This needs to be `cinstance` because the argument is
        -- passed directly to the on_apply callback, meaning that
        -- if it is an ID (number) it does *not* get wrapped as an Actor
        --      This does not apply to `buff_remove` or `item_give/take`
        --      since `id` is passed instead of the argument, so RoM
        --      recognizes it as a CInstance. Very weird circumstance.
        gm.apply_buff(self.cinstance, buff, duration, count or 1)

        -- Clamp to max stack or under
        -- Funny stuff happens if this is exceeded
        self.buff_stack:set(buff, math.min(self:buff_count(buff), Buff.wrap(buff).max_stack))
    end,


    --@instance
    --@param        buff        | Buff      | The buff to remove.
    --@optional     count       | number    | The amount of stacks to remove. <br>`1` by default.
    --[[
    Removes stacks of the specified buff from the actor.
    ]]
    buff_remove = function(self, buff, count)
        local actor_id = self.value
        count = count or 1

        -- Argument check
        buff = Wrap.unwrap(buff)
        if type(buff) ~= "number" then log.error("buff_remove: buff is invalid", 2) end

        local current_count = self:buff_count(buff)

        -- Remove buff entirely if count >= current_count
        if count >= current_count then
            gm.remove_buff(actor_id, buff)
            return
        end

        -- Decrease count in array
        -- Must manually call `recalculate_stats` when doing this
        self.buff_stack:set(buff, current_count - count)
        self:queue_recalculate_stats()

        -- Reset cached value
        if not __buff_count_cache[actor_id] then __buff_count_cache[actor_id] = {} end
        __buff_count_cache[actor_id][buff] = nil
    end,


    --@instance
    --@return       number
    --@param        buff        | Buff      | The buff to check.
    --[[
    Returns the number of stacks of the specified buff the actor has.
    ]]
    buff_count = function(self, buff)
        local id = self.value

        -- Argument check
        buff = Wrap.unwrap(buff)
        if type(buff) ~= "number" then log.error("buff_remove: buff is invalid", 2) end

        -- Build cache subtable if existn't
        if not __buff_count_cache[id] then __buff_count_cache[id] = {} end
        
        -- Return from cache if stored
        if __buff_count_cache[id][buff] then return __buff_count_cache[id][buff] end

        -- Get buff count from array
        local array = self.buff_stack
        if buff >= #array then return 0 end -- Return 0 for custom if array hasn't been resized yet
        local count = array:get(buff)

        -- Store in cache and return
        __buff_count_cache[id][buff] = count
        if count == nil then return 0 end
        return count
    end,


    --@instance
    --@return       Equipment or nil
    --[[
    Returns the actor's current equipment.
    ]]
    equipment_get = function(self)
        local equip = gm.equipment_get(self.value)
        if equip >= 0 then return Equipment.wrap(equip) end
        return nil
    end,


    --@instance
    --@param        equip       | Equipment | The equipment to set. <br>If `-1`, removes equipment.
    --[[
    Sets the actor's equipment.
    ]]
    equipment_set = function(self, equip)
        gm.equipment_set(self.value, Wrap.unwrap(equip))
    end,


    --@instance
    --[[
    Queues the actor's stats to be recalculated next frame.
    Prevents running `recalculate_stats` more than once per frame, so it's preferable over calling `recalculate_stats` directly.
    ]]
    queue_recalculate_stats = function(self)
        gm.actor_queue_dirty(self.value)
    end,


    --@instance
    --@param        state       | ActorState    | The state to enter.
    --[[
    Sets a new state for the actor.
    ]]
    enter_state = function(self, state)
        gm.actor_set_state(self.value, Wrap.unwrap(state))
    end,

}



-- ========== Metatables ==========

local wrapper_name = "Actor"

make_table_once("metatable_actor", {
    __index = function(proxy, k, id)
        -- Get wrapped value
        if k == "value" or k == "id" then return __proxy[proxy] end
        if k == "RAPI" then return wrapper_name end

        -- Check if this actor is valid
        -- (`id` may be passed from Player metatable
        -- to not have to access with proxy again)
        if not id then
            id = __proxy[proxy]
            if id == -4 then log.error("Actor does not exist", 2) end
        end

        -- Methods
        if methods_actor[k] then
            return methods_actor[k]
        end

        -- Pass to metatable_instance
        return metatable_instance.__index(proxy, k, id)
    end,


    __newindex = function(proxy, k, v)
        -- Pass to metatable_instance
        metatable_instance.__newindex(proxy, k, v)
    end,


    __eq = function(proxy, other)
        return metatable_instance.__eq(proxy, other)
    end,

    
    __metatable = "RAPI.Wrapper."..wrapper_name
})



-- ========== Hooks ==========

-- Reset cache when an item is given/taken

local hooks = {"item_give_internal", "item_take_internal"}

for _, hook in ipairs(hooks) do
    gm.pre_script_hook(gm.constants[hook], function(self, other, result, args)
        local actor_id  = Instance.wrap(args[1].value).id
        local item_id   = args[2].value

        -- Reset cached table for that item of the actor
        -- (The table contains cached values for every stack kind)
        if not __item_count_cache[actor_id] then __item_count_cache[actor_id] = {} end
        __item_count_cache[actor_id][item_id] = {}
    end)
end


-- Reset cache when a buff is applied

gm.pre_script_hook(gm.constants.apply_buff_internal, function(self, other, result, args)
    local actor_id  = Instance.wrap(args[1].value).id
    local buff_id   = args[2].value

    -- Reset cached value for that buff of the actor
    if not __buff_count_cache[actor_id] then __buff_count_cache[actor_id] = {} end
    __buff_count_cache[actor_id][buff_id] = nil
end)


-- Reset cache when a buff is removed
-- Adds an `on_remove` callback to every buff for this,
-- which allows for detecting passive buff expiry

gm.post_script_hook(gm.constants.buff_create, function(self, other, result, args)
    local buff = Buff.wrap(result.value)

    -- Add an `on_remove` callback to reset the
    -- cached value for that buff of the actor
    -- * This callback should never be removed, hence the namespace
    --      This is because buff_create will never run more than once
    --      for a buff, so if it is removed it cannot be readded
    Callback.add("__permanent", buff.on_remove, function(actor)
        local id = actor.value
        if not __buff_count_cache[id] then __buff_count_cache[id] = {} end
        __buff_count_cache[id][buff.value] = nil
    end, 1000000000)    -- Make sure this runs first
end)



-- ========== *_count_cache GC ==========

-- On room change, remove non-existent instances from `*_count_cache`

gm.post_script_hook(gm.constants.room_goto, function(self, other, result, args)
    -- Item
    for id, _ in pairs(__item_count_cache) do
        if not Instance.exists(id) then
            __item_count_cache[id] = nil
        end
    end

    -- Buff
    for id, _ in pairs(__buff_count_cache) do
        if not Instance.exists(id) then
            __buff_count_cache[id] = nil
        end
    end
end)


-- Remove `*_count_cache` on non-player kill

gm.post_script_hook(gm.constants.actor_set_dead, function(self, other, result, args)
    local actor_id = Instance.wrap(args[1].value).id

    -- Do not clear for player deaths
    local obj_ind = gm.variable_instance_get(actor_id, "object_index")
    if obj_ind ~= gm.constants.oP then
        __item_count_cache[actor_id] = nil
        __buff_count_cache[actor_id] = nil
    end
end)


-- Move `*_count_cache` to new instance

gm.post_script_hook(gm.constants.actor_transform, function(self, other, result, args)
    local actor_id  = Instance.wrap(args[1].value).id
    local new_id    = Instance.wrap(args[2].value).id

    -- Move item cache
    if __item_count_cache[actor_id] then
        __item_count_cache[new_id] = __item_count_cache[actor_id]
        __item_count_cache[actor_id] = nil
    end

    -- Move buff cache
    if __buff_count_cache[actor_id] then
        __buff_count_cache[new_id] = __buff_count_cache[actor_id]
        __buff_count_cache[actor_id] = nil
    end
end)



-- Public export
__class.Actor = Actor