-- Actor

-- "Child" class of Instance

Actor = new_class()

local item_count_cache = {}  -- Stores results from `item_count` for each item and stack kind
local buff_count_cache = {}  -- Stores results from `buff_count` for each buff

-- Stores callback IDs of `on_remove` callbacks added to every buff
-- This is for tracking when a buff passively expires for cache resetting
-- Hotloading removes these stored callbacks before adding them again
if not __buff_cache_onremove then __buff_cache_onremove = {} end    -- Preserve on hotload



-- ========== Instance Methods ==========

methods_actor = {
    
    --$instance
    --$param        item        | Item      | The item to give.
    --$optional     count       | number    | The amount of stacks to give. <br>`1` by default.
    --$optional     kind        | number    | The $kind, Item#StackKind$ of item. <br>`Item.StackKind.NORMAL` by default.
    --[[
    Gives stacks of the specified item to the actor.
    ]]
    item_give = function(self, item, count, kind)
        -- Return if wrapper is invalid
        if self.value == -4 then return end

        local holder = RValue.new_holder_scr(4)
        holder[0] = RValue.new(self.value, RValue.Type.REF)
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
        if self.value == -4 then return end

        local holder = RValue.new_holder_scr(4)
        holder[0] = RValue.new(self.value, RValue.Type.REF)
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

        -- Build cache subtable if existn't
        local item = Wrap.unwrap(item)
        local kind = kind or Item.StackKind.ANY
        if not item_count_cache[id] then item_count_cache[id] = {} end
        if not item_count_cache[id][item] then item_count_cache[id][item] = {} end

        -- Return from cache if stored
        if item_count_cache[id][item][kind] then return item_count_cache[id][item][kind] end

        local holder = RValue.new_holder_scr(3)
        holder[0] = RValue.new(id, RValue.Type.REF)
        holder[1] = RValue.new(item)
        holder[2] = RValue.new(kind or Item.StackKind.NORMAL)
        local out = RValue.new(0)
        gmf.item_count(nil, nil, out, 3, holder)
        local ret = out.value

        -- Store in cache and return
        item_count_cache[id][item][kind] = ret
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
        if self.value == -4 then return end

        -- Arg check
        if not duration then log.error("buff_apply: duration is missing", 2) end

        local holder = RValue.new_holder_scr(4)
        holder[0] = RValue.new(self.value, RValue.Type.REF)
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
        if self.value == -4 then return end

        local current_count = self:buff_count(buff)

        -- Remove buff entirely if count >= current_count
        if (not count) or count >= current_count then
            local holder = RValue.new_holder_scr(2)
            holder[0] = RValue.new(self.value, RValue.Type.REF)
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

        -- Build cache subtable if existn't
        local buff = Wrap.unwrap(buff)
        if not buff_count_cache[id] then buff_count_cache[id] = {} end
        
        -- Return from cache if stored
        if buff_count_cache[id][buff] then return buff_count_cache[id][buff] end

        -- Get buff count from array
        local count = self.buff_stack:get(buff)

        -- Store in cache and return
        buff_count_cache[id][buff] = count
        if count == nil then return 0 end
        return count
    end,

}



-- ========== Metatables ==========

metatable_actor = {
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
}



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
            if not item_count_cache[actor_id] then item_count_cache[actor_id] = {} end
            item_count_cache[actor_id][item_id] = {}
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
        if not buff_count_cache[actor_id] then buff_count_cache[actor_id] = {} end
        buff_count_cache[actor_id][buff_id] = nil
    end,

    -- Post-hook
    nil}
)


-- Reset cache when a buff is removed
-- Adds an `on_remove` callback to every buff to detect this

Actor.internal.initialize = function()
    -- Remove previously added callbacks
    for _, id in ipairs(__buff_cache_onremove) do
        Callback.remove(id)
    end
    __buff_cache_onremove = {}


    -- For all buffs, add an `on_remove` callback
    -- to reset the cached value for that buff of the actor
    for buff_id, buff in ipairs(Class.Buff) do
        table.insert(__buff_cache_onremove, Callback.add(_ENV["!guid"], buff:get(11), function(actor)
            local id = actor.value
            if not buff_count_cache[id] then buff_count_cache[id] = {} end
            buff_count_cache[id][buff_id - 1] = nil
        end, 1000000000))   -- Make sure this runs first
    end
end

memory.dynamic_hook("RAPI.Actor.buff_create", "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.buff_create),
    -- Pre-hook
    {nil,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
        if Initialize.has_started() then
            local buff = Buff.wrap(RValue.to_wrapper(ffi.cast("struct RValue*", result:get_address())))

            -- For newly created buffs, add an `on_remove` callback
            -- to reset the cached value for that buff of the actor
            table.insert(__buff_cache_onremove, Callback.add(_ENV["!guid"], buff.on_remove, function(actor)
                local id = actor.value
                if not buff_count_cache[id] then buff_count_cache[id] = {} end
                buff_count_cache[id][buff.value] = nil
            end, 1000000000))   -- Make sure this runs first
        end
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
        for id, _ in pairs(item_count_cache) do
            if not Instance.exists(id) then
                item_count_cache[id] = nil
            end
        end

        -- Buff
        for id, _ in pairs(buff_count_cache) do
            if not Instance.exists(id) then
                buff_count_cache[id] = nil
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

        -- Get object_index
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(actor_id, RValue.Type.REF)
        holder[1] = RValue.new("object_index")
        local out = RValue.new(0)
        gmf.variable_instance_get(out, nil, nil, 2, holder)

        -- Do not clear for player deaths
        if out.value ~= gm.constants.oP then
            item_count_cache[actor_id] = nil
            buff_count_cache[actor_id] = nil
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
        if item_count_cache[actor_id] then
            item_count_cache[new_id] = item_count_cache[actor_id]
            item_count_cache[actor_id] = nil
        end

        -- Move buff cache
        if buff_count_cache[actor_id] then
            buff_count_cache[new_id] = buff_count_cache[actor_id]
            buff_count_cache[actor_id] = nil
        end
    end}
)



__class.Actor = Actor