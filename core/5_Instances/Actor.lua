-- Actor

Actor = new_class()

local item_count_cache = {}



-- ========== Instance Methods ==========

methods_actor = {

    kill = function(self)
        if self.value == -4 then return end
        self:actor_kill()
    end,


    item_give = function(self, item, count, kind)
        if self.value == -4 then return end
        local holder = ffi.new("struct RValue*[4]")
        holder[0] = RValue.new(self.value, RValue.Type.REF)
        holder[1] = RValue.from_wrapper(item)
        holder[2] = RValue.new(count or 1)
        holder[3] = RValue.new(kind or Item.StackKind.NORMAL)
        gmf.item_give(nil, nil, RValue.new(0), 4, holder)
    end,


    item_take = function(self, item, count, kind)
        if self.value == -4 then return end
        local holder = ffi.new("struct RValue*[4]")
        holder[0] = RValue.new(self.value, RValue.Type.REF)
        holder[1] = RValue.from_wrapper(item)
        holder[2] = RValue.new(count or 1)
        holder[3] = RValue.new(kind or Item.StackKind.NORMAL)
        gmf.item_take(nil, nil, RValue.new(0), 4, holder)
    end,


    item_count = function(self, item, kind)
        local id = self.value
        if id == -4 then return 0 end

        -- Build cache subtable if existn't
        local item = Wrap.unwrap(item)
        local kind = kind or Item.StackKind.ANY
        if not item_count_cache[id] then item_count_cache[id] = {} end
        if not item_count_cache[id][item] then item_count_cache[id][item] = {} end
        if item_count_cache[id][item][kind] then return item_count_cache[id][item][kind] end

        local holder = ffi.new("struct RValue*[3]")
        holder[0] = RValue.new(id, RValue.Type.REF)
        holder[1] = RValue.from_wrapper(item)
        holder[2] = RValue.new(kind or Item.StackKind.NORMAL)
        local out = RValue.new(0)
        gmf.item_count(nil, nil, out, 3, holder)
        local ret = RValue.to_wrapper(out)
        item_count_cache[id][item][kind] = ret
        return ret
    end

}



-- ========== Metatables ==========

metatable_actor = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(t) end
        if k == "RAPI" then return getmetatable(t):sub(14, -1) end

        -- Methods
        if methods_actor[k] then
            return methods_actor[k]
        end

        -- Pass to metatable_instance
        return metatable_instance.__index(t, k)
    end,


    __newindex = function(t, k, v)
        -- Pass to metatable_instance
        metatable_instance.__newindex(t, k, v)
    end,

    
    __metatable = "RAPI.Wrapper.Actor"
}



-- ========== Hooks ==========

-- Reset cache when an item is given/taken

memory.dynamic_hook("RAPI.Actor.item_give_internal", "void*", {"void*", "void*", "void*", "int", "void*"}, memory.pointer.new(tonumber(ffi.cast("int64_t", gmf.item_give_internal))),
    -- Pre-hook
    function(ret_val, self, other, result, arg_count, args)
        local arg_count = arg_count:get()
        local args_typed = ffi.cast("struct RValue**", args:get_address())

        -- Get args
        local actor = RValue.to_wrapper(args_typed[0])
        local item  = RValue.to_wrapper(args_typed[1])
        -- local count = RValue.to_wrapper(args_typed[2])
        -- local kind  = RValue.to_wrapper(args_typed[3])

        local id = actor.value
        if not item_count_cache[id] then item_count_cache[id] = {} end
        item_count_cache[id][item] = {}
    end,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
    end
)

memory.dynamic_hook("RAPI.Actor.item_take_internal", "void*", {"void*", "void*", "void*", "int", "void*"}, memory.pointer.new(tonumber(ffi.cast("int64_t", gmf.item_take_internal))),
    -- Pre-hook
    function(ret_val, self, other, result, arg_count, args)
        local arg_count = arg_count:get()
        local args_typed = ffi.cast("struct RValue**", args:get_address())

        -- Get args
        local actor = RValue.to_wrapper(args_typed[0])
        local item  = RValue.to_wrapper(args_typed[1])
        -- local count = RValue.to_wrapper(args_typed[2])
        -- local kind  = RValue.to_wrapper(args_typed[3])

        local id = actor.value
        if not item_count_cache[id] then item_count_cache[id] = {} end
        item_count_cache[id][item] = {}
    end,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
    end
)



-- ========== _count_cache GC ==========

-- TODO replace with memory.dynamic_hook

gm.post_script_hook(gm.constants.room_goto, function(self, other, result, args)
    -- On room change, remove non-existent instances from cache
    for k, v in pairs(item_count_cache) do
        if gm.instance_exists(k) == 0 then
            item_count_cache[k] = nil
        end
    end
end)


gm.post_script_hook(gm.constants.actor_set_dead, function(self, other, result, args)
    -- Remove cache on non-player kill
    local actor = args[1].value
    if actor.object_index ~= gm.constants.oP then
        item_count_cache[actor.id] = nil
    end
end)


gm.post_script_hook(gm.constants.actor_transform, function(self, other, result, args)
    -- Move cache to new instance
    local id = args[1].value.id
    if item_count_cache[id] then
        item_count_cache[args[2].value.id] = item_count_cache[id]
        item_count_cache[id] = nil
    end
end)



_CLASS["Actor"] = Actor