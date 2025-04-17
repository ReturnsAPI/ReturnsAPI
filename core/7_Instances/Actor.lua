-- Actor

-- "Child" class of Instance

Actor = new_class()

run_once(function()
    __item_count_cache = {} -- Stores results from `item_count` for each item and stack kind
    __buff_count_cache = {} -- Stores results from `buff_count` for each buff
end)



-- ========== Internal ==========

-- For `fire_explosion_local`
local explosion_mask        = gm.constants.sBite1Mask
local explosion_mask_width  = GM.sprite_get_width(explosion_mask)
local explosion_mask_height = GM.sprite_get_height(explosion_mask)



-- ========== Instance Methods ==========

methods_actor = {

    --$instance
    --$return       bool
    --[[
    Returns `true` if the actor is on the
    ground and is *not* climbing on a rope.
    ]]
    is_grounded = function(self)
        local holder = RValue.new_holder(3)
        holder[0] = RValue.new(self.x)
        holder[1] = RValue.new(self.y + 1)
        holder[2] = RValue.new(gm.constants.oB)
        local out = RValue.new(0)
        gmf.place_meeting(out, self.CInstance, nil, 3, holder)
        return (out.value == 1) and (not self:is_climbing())
    end,


    --$instance
    --$return       bool
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


    --$instance
    --$return       Instance
    --$param        x                   | number    | The x coordinate of the origin.
    --$param        y                   | number    | The y coordinate of the origin.
    --$param        range               | number    | The range of the bullet (in pixels).
    --$param        direction           | number    | The angle to fire the bullet (in degrees).
    --$param        damage              | number    | The damage coefficient of the attack, <br>scaled off of the `actor`'s base damage. <br>`1` is 100% damage.
    --$optional     pierce_multiplier   | number    | Remaining damage is multiplied by this value per pierce. <br>If `nil` or `0`, no piercing happens.
    --$optional     hit_sprite          | sprite    | The sprite to draw on collision with an actor or wall. <br>`nil` by default (no sprite).
    --$optional     tracer              | number    | The bullet tracer to use. <br>$`AttackInfo.Tracer.NONE`, AttackInfo#Tracer$ by default.
    --$optional     can_proc            | bool      | If `false` the attack will not proc. <br>`true` by default.
    --[[
    Fires a bullet attack from the actor, and returns the attack instance.
    `.attack_info` will return an AttackInfo.
    
    This can be called from host or client, and automatically syncs.
    ]]
    fire_bullet = function(self, x, y, range, direction, damage, pierce_multiplier, hit_sprite, tracer, can_proc)
        -- Return if wrapper is invalid
        local id = self.value
        if id == -4 then return end
        
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


    --$instance
    --$return       Instance
    --$param        x                   | number    | The x coordinate of the origin.
    --$param        y                   | number    | The y coordinate of the origin.
    --$param        width               | number    | The width of the explosion, centered at `x` (in pixels).
    --$param        height              | number    | The height of the explosion, centered at `y` (in pixels).
    --$param        damage              | number    | The damage coefficient of the attack, <br>scaled off of the `actor`'s base damage. <br>`1` is 100% damage.
    --$optional     explosion_sprite    | sprite    | The sprite to use for the explosion. <br>`nil` by default (no sprite).
    --$optional     sparks_sprite       | sprite    | The sprite to draw on hit actors. <br>`nil` by default (no sprite).
    --$optional     can_proc            | bool      | If `false` the attack will not proc. <br>`true` by default.
    --[[
    Fires an explosion attack from the actor, and returns the attack instance.
    `.attack_info` will return an AttackInfo.

    This can be called from host or client, and automatically syncs.
    ]]
    fire_explosion = function(self, x, y, width, height, damage, explosion_sprite, sparks_sprite, can_proc)
        -- Return if wrapper is invalid
        local id = self.value
        if id == -4 then return end

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


    --$instance
    --$return       Instance
    --$param        x                   | number    | The x coordinate of the origin.
    --$param        y                   | number    | The y coordinate of the origin.
    --$param        width               | number    | The width of the explosion, centered at `x` (in pixels).
    --$param        height              | number    | The height of the explosion, centered at `y` (in pixels).
    --$param        damage              | number    | The damage coefficient of the attack, <br>scaled off of the `actor`'s base damage. <br>`1` is 100% damage.
    --$optional     explosion_sprite    | sprite    | The sprite to use for the explosion. <br>`nil` by default (no sprite).
    --$optional     sparks_sprite       | sprite    | The sprite to draw on hit actors. <br>`nil` by default (no sprite).
    --$optional     can_proc            | bool      | If `false` the attack will not proc. <br>`true` by default.
    --[[
    Fires an explosion attack from the actor, and returns the attack instance.
    `.attack_info` will return an AttackInfo.

    This attack is not synced.
    ]]
    fire_explosion_local = function(self, x, y, width, height, damage, explosion_sprite, sparks_sprite, can_proc)
        -- Return if wrapper is invalid
        local id = self.value
        if id == -4 then return end

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


    --$instance
    --$return       Instance
    --$param        target              | Instance  | The target instance of the attack.
    --$param        damage              | number    | The damage coefficient of the attack, <br>scaled off of the `actor`'s base damage. <br>`1` is 100% damage.
    --$optional     direction           | number    | The angle of the attack (in degrees). <br>`0` by default.
    --$optional     x                   | number    | The x coordinate. <br>`target.x` by default.
    --$optional     y                   | number    | The y coordinate. <br>`target.y` by default.
    --$optional     hit_sprite          | sprite    | The sprite to draw on collision with an actor or wall. <br>`nil` by default (no sprite).
    --$optional     can_proc            | bool      | If `false` the attack will not proc. <br>`true` by default.
    --[[
    Fires a direct attack from the actor, and returns the attack instance.
    `.attack_info` will return an AttackInfo.

    This can be called from host or client, and automatically syncs.
    ]]
    fire_direct = function(self, target, damage, direction, x, y, hit_sprite, can_proc)
        -- Return if wrapper is invalid
        local id = self.value
        if id == -4 then return end

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

    
    --$instance
    --$param        item        | Item      | The item to give.
    --$optional     count       | number    | The amount of stacks to give. <br>`1` by default.
    --$optional     kind        | number    | The $kind, Item#StackKind$ of item. <br>`Item.StackKind.NORMAL` by default.
    --[[
    Gives stacks of the specified item to the actor.
    ]]
    item_give = function(self, item, count, kind)
        -- Return if wrapper is invalid
        local id = self.value
        if id == -4 then return end

        -- Argument check
        if not item then log.error("item_give: item is invalid", 2) end

        local holder = RValue.new_holder_scr(4)
        holder[0] = RValue.new(id, RValue.Type.REF)
        holder[1] = RValue.from_wrapper(item)
        holder[2] = RValue.new(count or 1)
        holder[3] = RValue.new(kind or Item.StackKind.NORMAL)
        gmf.item_give(nil, nil, RValue.new(0), 4, holder)
    end,


    --$instance
    --$param        item        | Item      | The item to take.
    --$optional     count       | number    | The amount of stacks to take. <br>`1` by default.
    --$optional     kind        | number    | The $kind, Item#StackKind$ of item. <br>`Item.StackKind.NORMAL` by default.
    --[[
    Takes (removes) stacks of the specified item from the actor.
    ]]
    item_take = function(self, item, count, kind)
        -- Return if wrapper is invalid
        local id = self.value
        if id == -4 then return end

        -- Argument check
        if not item then log.error("item_take: item is invalid", 2) end

        local holder = RValue.new_holder_scr(4)
        holder[0] = RValue.new(id, RValue.Type.REF)
        holder[1] = RValue.from_wrapper(item)
        holder[2] = RValue.new(count or 1)
        holder[3] = RValue.new(kind or Item.StackKind.NORMAL)
        gmf.item_take(nil, nil, RValue.new(0), 4, holder)
    end,


    --$instance
    --$return       number
    --$param        item        | Item      | The item to check.
    --$optional     kind        | number    | The $kind, Item#StackKind$ of item. <br>`Item.StackKind.NORMAL` by default.
    --[[
    Returns the number of stacks of the specified item the actor has.
    ]]
    item_count = function(self, item, kind)
        local id = self.value

        -- Return `0` if wrapper is invalid
        if id == -4 then return 0 end
        
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


    --$instance
    --$param        buff        | Buff      | The buff to apply.
    --$param        duration    | number    | The duration of the buff (in frames).
    --$optional     count       | number    | The amount of stacks to apply. <br>`1` by default.
    --[[
    Applies stacks of the specified buff to the actor.
    ]]
    buff_apply = function(self, buff, duration, count)
        -- Return if wrapper is invalid
        local id = self.value
        if id == -4 then return end

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


    --$instance
    --$param        buff        | Buff      | The buff to remove.
    --$optional     count       | number    | The amount of stacks to remove. <br>`1` by default.
    --[[
    Removes stacks of the specified buff from the actor.
    ]]
    buff_remove = function(self, buff, count)
        -- Return if wrapper is invalid
        local id = self.value
        if id == -4 then return end

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
        self:recalculate_stats()
    end,


    --$instance
    --$return       number
    --$param        buff        | Buff      | The buff to check.
    --[[
    Returns the number of stacks of the specified buff the actor has.
    ]]
    buff_count = function(self, buff)
        local id = self.value

        -- Return `0` if wrapper is invalid
        if id == -4 then return 0 end

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
    end

}



-- ========== Metatables ==========

make_table_once("metatable_actor", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" or k == "id" then return Proxy.get(proxy) end
        if k == "RAPI" then return getmetatable(proxy):sub(14, -1) end

        -- Methods
        if methods_actor[k] then
            return methods_actor[k]
        end

        -- Pass to metatable_instance
        return metatable_instance.__index(proxy, k)
    end,


    __newindex = function(proxy, k, v)
        -- Pass to metatable_instance
        metatable_instance.__newindex(proxy, k, v)
    end,

    
    __metatable = "RAPI.Wrapper.Actor"
})



-- ========== Hooks ==========

-- Reset cache when an item is given/taken

local hooks = {"item_give_internal", "item_take_internal"}

for _, hook in ipairs(hooks) do
    Memory.dynamic_hook(_ENV["!guid"], "Actor."..hook, "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants[hook]),
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

Memory.dynamic_hook(_ENV["!guid"], "Actor.apply_buff_internal", "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.apply_buff_internal),
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

Memory.dynamic_hook(_ENV["!guid"], "Actor.buff_create", "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.buff_create),
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

Memory.dynamic_hook(_ENV["!guid"], "Actor.room_goto", "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.room_goto),
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

Memory.dynamic_hook(_ENV["!guid"], "Instance.actor_set_dead", "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.actor_set_dead),
    -- Pre-hook
    {nil,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
        local args_typed = ffi.cast("struct RValue**", args:get_address())
    
        local actor_id = args_typed[0].i32
    
        -- Get object_index
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(actor_id, RValue.Type.REF)
        holder[1] = RValue.new("object_index")
        local out = RValue.new(0)
        gmf.variable_instance_get(out, nil, nil, 2, holder)
    
        -- Do not clear for player deaths
        if out.value ~= gm.constants.oP then
            __item_count_cache[actor_id] = nil
            __buff_count_cache[actor_id] = nil
        end
    end}
)


-- Move `_count_cache` to new instance

Memory.dynamic_hook(_ENV["!guid"], "Instance.actor_transform", "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.actor_transform),
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