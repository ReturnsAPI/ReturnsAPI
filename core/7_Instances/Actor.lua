-- Actor

--[[
Actor wrappers are "children" of @link {`Instance` | Instance}, and can use their properties and instance methods.
]]

Actor = new_class()

run_once(function()
    __item_count_cache = {} -- Stores results from `item_count` for each item and stack kind
    __buff_count_cache = {} -- Stores results from `buff_count` for each buff
end)



-- ========== Enums ==========

--@section Enums

--@enum
Actor.KnockbackKind = ReadOnly.new({
    NONE        = 0,    -- Does nothing; do not use
    STANDARD    = 1,    -- Applies stun; actor cannot move horizontally or act, but can jump
    FREEZE      = 2,    -- Frozen color shader vfx; actor cannot move horizontally, but can jump and attack; actor also slides with less friction
    DEEPFREEZE  = 3,    -- Ice cube vfx; actor cannot move horizontally, but can jump and attack; actor also slides with less friction
    PULL        = 4     -- STANDARD, but in the opposite direction
})



-- ========== Properties ==========

--@section Properties

--[[
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
        local holder = RValue.new_holder_scr(1)
        holder[0] = RValue.new(self.actor_state_current_id)
        local out = RValue.new(0)
        gmf.actor_state_is_climb_state(nil, nil, out, 1, holder)
        return RValue.to_wrapper(out)
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
        local id = self.value
        
        -- If `pierce_multiplier` is a number > 0,
        -- enable piercing for the attack
        local can_pierce = false
        if pierce_multiplier and (pierce_multiplier > 0) then can_pierce = true end

        -- Attack will proc by default
        if can_proc == nil then can_proc = true end

        local holder = RValue.new_holder_scr(9)
        holder[0] = RValue.new(id, RValue.Type.REF)
        holder[1] = RValue.new(x)
        holder[2] = RValue.new(y)
        holder[3] = RValue.new(range)
        holder[4] = RValue.new(direction)
        holder[5] = RValue.new(damage)
        holder[6] = RValue.new(hit_sprite or gm.constants.sNone)
        holder[7] = RValue.new(can_pierce)
        holder[8] = RValue.new(can_proc)
        local out = RValue.new(0)
        gmf._mod_attack_fire_bullet(nil, nil, out, 9, holder)
        local inst = RValue.to_wrapper(out)

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

        local holder = RValue.new_holder_scr(9)
        holder[0] = RValue.new(id, RValue.Type.REF)
        holder[1] = RValue.new(x)
        holder[2] = RValue.new(y)
        holder[3] = RValue.new(width)
        holder[4] = RValue.new(height)
        holder[5] = RValue.new(damage)
        holder[6] = RValue.new(explosion_sprite or gm.constants.sNone)
        holder[7] = RValue.new(sparks_sprite or gm.constants.sNone)
        holder[8] = RValue.new(can_proc)
        local out = RValue.new(0)
        gmf._mod_attack_fire_explosion(nil, nil, out, 9, holder)
        local inst = RValue.to_wrapper(out)

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

        local holder = RValue.new_holder_scr(8)
        holder[0] = RValue.new(0)
        holder[1] = RValue.new(x)
        holder[2] = RValue.new(y)
        holder[3] = RValue.new(damage)
        holder[4] = RValue.new(sparks_sprite or gm.constants.sNone)
        holder[5] = RValue.new(2)
        holder[6] = RValue.new(width / explosion_mask_width)
        holder[7] = RValue.new(height / explosion_mask_height)
        gmf.fire_explosion_local(self.CInstance, nil, RValue.new(0), 8, holder)
        local inst = Global.attack_bullet   -- The function doesn't return anything

        -- Set attack_info properties
        local attack_info = inst.attack_info    -- Autowraps as AttackInfo
        attack_info.damage_color = Color.WHITE_ALMOST
        attack_info.proc = can_proc

        -- Create explosion sprite manually
        if explosion_sprite then
            local holder = RValue.new_holder_scr(3)
            holder[0] = RValue.new(x)
            holder[1] = RValue.new(y)
            holder[2] = RValue.new(gm.constants.oEfExplosion)
            local out = RValue.new(0)
            gmf.instance_create(nil, nil, out, 3, holder)
            local ef_inst = RValue.to_wrapper(out)
            ef_inst.sprite_index = explosion_sprite
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

        -- Make sure `target` is wrapped
        if type(target) ~= "table" then target = Instance.wrap(target) end

        -- Attack will proc by default
        if can_proc == nil then can_proc = true end

        local holder = RValue.new_holder_scr(8)
        holder[0] = RValue.new(id, RValue.Type.REF)
        holder[1] = RValue.from_wrapper(target)
        holder[2] = RValue.new(x or target.x)
        holder[3] = RValue.new(y or target.y)
        holder[4] = RValue.new(direction or 0)
        holder[5] = RValue.new(damage)
        holder[6] = RValue.new(hit_sprite or gm.constants.sNone)
        holder[7] = RValue.new(can_proc)
        local out = RValue.new(0)
        gmf._mod_attack_fire_direct(nil, nil, out, 8, holder)
        local inst = RValue.to_wrapper(out)

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
    Applies knockback to the actor.
    
    This can be called multiple times to stack effects from different `kind`s
    (although it seems that they must be called in numerical order).
    ]]
    apply_knockback = function(self, direction, duration, force, kind)
        local holder = RValue.new_holder_scr(5)
        holder[0] = RValue.new(self.value, RValue.Type.REF)
        holder[1] = RValue.new(kind or Actor.KnockbackKind.STANDARD)
        holder[2] = RValue.new(direction)
        holder[3] = RValue.new(duration)
        holder[4] = RValue.new(force)
        gmf.actor_knockback_inflict(nil, nil, RValue.new(0), 5, holder)
    end,

    
    --@instance
    --@param        item        | Item      | The item to give.
    --@optional     count       | number    | The amount of stacks to give. <br>`1` by default.
    --@optional     kind        | number    | The @link {kind | Item#StackKind} of item. <br>`Item.StackKind.NORMAL` by default.
    --[[
    Gives stacks of the specified item to the actor.
    ]]
    item_give = function(self, item, count, kind)
        local id = self.value

        -- Argument check
        if not item then log.error("item_give: item is invalid", 2) end

        local holder = RValue.new_holder_scr(4)
        holder[0] = RValue.new(id, RValue.Type.REF)
        holder[1] = RValue.from_wrapper(item)
        holder[2] = RValue.new(count or 1)
        holder[3] = RValue.new(kind or Item.StackKind.NORMAL)
        gmf.item_give(nil, nil, RValue.new(0), 4, holder)
    end,


    --@instance
    --@param        item        | Item      | The item to take.
    --@optional     count       | number    | The amount of stacks to take. <br>`1` by default.
    --@optional     kind        | number    | The @link {kind | Item#StackKind} of item. <br>`Item.StackKind.NORMAL` by default.
    --[[
    Takes (removes) stacks of the specified item from the actor.
    ]]
    item_take = function(self, item, count, kind)
        local id = self.value

        -- Argument check
        if not item then log.error("item_take: item is invalid", 2) end

        local holder = RValue.new_holder_scr(4)
        holder[0] = RValue.new(id, RValue.Type.REF)
        holder[1] = RValue.from_wrapper(item)
        holder[2] = RValue.new(count or 1)
        holder[3] = RValue.new(kind or Item.StackKind.NORMAL)
        gmf.item_take(nil, nil, RValue.new(0), 4, holder)
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
        if not item then log.error("item_count: item is invalid", 2) end

        -- Build cache subtable if existn't
        local item = Wrap.unwrap(item)
        local kind = kind or Item.StackKind.ANY
        if not __item_count_cache[id] then __item_count_cache[id] = {} end
        if not __item_count_cache[id][item] then __item_count_cache[id][item] = {} end

        -- Return from cache if stored
        if __item_count_cache[id][item][kind] then return __item_count_cache[id][item][kind] end

        local holder = RValue.new_holder_scr(3)
        holder[0] = RValue.new(id, RValue.Type.REF)
        holder[1] = RValue.new(item)
        holder[2] = RValue.new(kind or Item.StackKind.NORMAL)
        local out = RValue.new(0)
        gmf.item_count(nil, nil, out, 3, holder)
        local ret = out.value

        -- Store in cache and return
        __item_count_cache[id][item][kind] = ret
        return ret
    end,


    --@instance
    --@param        buff        | Buff      | The buff to apply.
    --@param        duration    | number    | The duration of the buff (in frames).
    --@optional     count       | number    | The amount of stacks to apply. <br>`1` by default.
    --[[
    Applies stacks of the specified buff to the actor.
    ]]
    buff_apply = function(self, buff, duration, count)
        local id = self.value

        -- Argument check
        if not buff then log.error("buff_apply: buff is invalid", 2) end
        if not duration then log.error("buff_apply: duration is missing", 2) end

        local holder = RValue.new_holder_scr(4)
        holder[0] = RValue.new(id, RValue.Type.REF)
        holder[1] = RValue.from_wrapper(buff)
        holder[2] = RValue.new(duration)
        holder[3] = RValue.new(count or 1)
        gmf.apply_buff(nil, nil, RValue.new(0), 4, holder)

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
        local id = self.value

        -- Argument check
        if not buff then log.error("buff_remove: buff is invalid", 2) end

        local current_count = self:buff_count(buff)

        -- Remove buff entirely if count >= current_count
        if (not count) or count >= current_count then
            local holder = RValue.new_holder_scr(2)
            holder[0] = RValue.new(id, RValue.Type.REF)
            holder[1] = RValue.from_wrapper(buff)
            gmf.remove_buff(nil, nil, RValue.new(0), 2, holder)
            return
        end

        -- Decrease count in array
        -- Must manually call `recalculate_stats` when doing this
        self.buff_stack:set(buff, current_count - count)
        self:queue_dirty()
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
        if not buff then log.error("buff_count: buff is invalid", 2) end

        -- Build cache subtable if existn't
        local buff = Wrap.unwrap(buff)
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
    --[[
    Queues the actor's stats to be recalculated next frame.
    Prevents running `recalculate_stats` more than once per frame, so it's preferable over calling `recalculate_stats` directly.
    ]]
    queue_recalculate_stats = function(self)
        local holder = RValue.new_holder_scr(1)
        holder[0] = RValue.new(self.value, RValue.Type.REF)
        gmf.actor_queue_dirty(nil, nil, RValue.new(0), 1, holder)
    end,


    --@instance
    --@return       Equipment or nil
    --[[
    Returns the player's current equipment.
    Always `nil` for non-player actors.
    ]]
    equipment_get = function(self)
        return nil
    end

}



-- ========== Metatables ==========

local metatable_name = "Actor"

make_table_once("metatable_actor", {
    __index = function(proxy, k, id)
        -- Get wrapped value
        if k == "value" or k == "id" then return __proxy[proxy] end
        if k == "RAPI" then return metatable_name end

        -- Check if this actor is valid
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

    
    __metatable = "RAPI.Wrapper."..metatable_name
})



-- ========== Hooks ==========

-- Reset cache when an item is given/taken

local hooks = {"item_give_internal", "item_take_internal"}

for _, hook in ipairs(hooks) do
    memory.dynamic_hook("RAPI.Actor."..hook, "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants[hook]),
        -- Pre-hook
        {function(ret_val, self, other, result, arg_count, args)
            local args_typed = ffi.cast("struct RValue**", args:get_address())
    
            -- Get args
            local actor_id  = args_typed[0].i32
            local item_id   = args_typed[1].value
    
            -- Reset cached table for that item of the actor
            -- (The table contains cached values for every stack kind)
            if not __item_count_cache[actor_id] then __item_count_cache[actor_id] = {} end
            __item_count_cache[actor_id][item_id] = {}
        end,

        -- Post-hook
        nil}
    )
end


-- Reset cache when a buff is applied

memory.dynamic_hook("RAPI.Actor.apply_buff_internal", "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.apply_buff_internal),
    -- Pre-hook
    {function(ret_val, self, other, result, arg_count, args)
        local args_typed = ffi.cast("struct RValue**", args:get_address())
    
        -- Get args
        local actor_id  = args_typed[0].i32
        local buff_id   = args_typed[1].value
    
        -- Reset cached value for that buff of the actor
        if not __buff_count_cache[actor_id] then __buff_count_cache[actor_id] = {} end
        __buff_count_cache[actor_id][buff_id] = nil
    end,

    -- Post-hook
    nil}
)


-- Reset cache when a buff is removed
-- Adds an `on_remove` callback to every buff for this,
-- which allows for detecting passive buff expiry

memory.dynamic_hook("RAPI.Actor.buff_create", "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.buff_create),
    -- Pre-hook
    {nil,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
        local buff = Buff.wrap(RValue.to_wrapper(ffi.cast("struct RValue*", result:get_address())))
    
        -- Add an `on_remove` callback to reset the
        -- cached value for that buff of the actor
        Callback.add(_ENV["!guid"], buff.on_remove, function(actor)
            local id = actor.value
            if not __buff_count_cache[id] then __buff_count_cache[id] = {} end
            __buff_count_cache[id][buff.value] = nil
        end, 1000000000)    -- Make sure this runs first
    end}
)



-- ========== _count_cache GC ==========

-- On room change, remove non-existent instances from `_count_cache`

memory.dynamic_hook("RAPI.Actor.room_goto", "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.room_goto),
    -- Pre-hook
    {nil,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
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
    end}
)


-- Remove `_count_cache` on non-player kill

memory.dynamic_hook("RAPI.Instance.actor_set_dead", "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.actor_set_dead),
    -- Pre-hook
    {nil,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
        local args_typed = ffi.cast("struct RValue**", args:get_address())
    
        local actor_id = args_typed[0].i32
    
        -- Do not clear for player deaths
        local obj_ind = gm.variable_instance_get(actor_id, "object_index")
        if obj_ind ~= gm.constants.oP then
            __item_count_cache[actor_id] = nil
            __buff_count_cache[actor_id] = nil
        end
    end}
)


-- Move `_count_cache` to new instance

memory.dynamic_hook("RAPI.Instance.actor_transform", "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.actor_transform),
    -- Pre-hook
    {nil,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
        local args_typed = ffi.cast("struct RValue**", args:get_address())
    
        local actor_id = args_typed[0].i32
        local new_id = args_typed[1].i32
    
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
    end}
)



-- Public export
__class.Actor = Actor