-- Actor

return

Actor = new_class()

local item_count_cache = {}



-- ========== Instance Methods ==========

local out = gmf.rvalue_new(0)

methods_actor = {

    kill = function(self)
        if self.value == -4 then return end
        self.value:actor_kill()
    end,


    item_give = function(self, item, count, kind)
        gm.item_give(self.value, Wrap.unwrap(item), count or 1, kind or Item.StackKind.NORMAL)
    end,


    item_take = function(self, item, count, kind)
        gm.item_take(self.value, Wrap.unwrap(item), count or 1, kind or Item.StackKind.NORMAL)
    end,


    item_count = function(self, item, kind)
        local id = self.value.id
        local item = Wrap.unwrap(item)
        local kind = kind or Item.StackKind.ANY
        if not item_count_cache[id] then item_count_cache[id] = {} end
        if not item_count_cache[id][item] then item_count_cache[id][item] = {} end
        if item_count_cache[id][item][kind] then return item_count_cache[id][item][kind] end
        local count = gm.item_count(self.value, item, kind)
        item_count_cache[id][item][kind] = count
        return count
    end,


    item_count_NONCACHED = function(self, item, kind)
        return gm.item_count(self.value, Wrap.unwrap(item), kind or Item.StackKind.ANY)
    end,


    item_count_GMF = function(self, item, kind)
        local holder = ffi.new("struct RValue[3]")  -- args holder

        -- actor
        print(self)
        -- holder[0] = ffi.cast("struct CInstance *", self)
        -- holder[0] = gm.CInstance.instance_id_to_CInstance_ffi[self.i32]
        -- holder[0] = ffi.new("struct RValue")
        -- holder[0].type = 6
        -- holder[0].yy_object_base = ffi.cast("struct YYObjectBase *", self)
        -- holder[0].cinstance = ffi.cast("struct CInstance *", self.cinstance)

        -- item
        holder[1] = gmf.rvalue_new(item)

        -- kind
        holder[2] = gmf.rvalue_new(kind or Item.StackKind.ANY)

        gmf.item_count(out, nil, nil, 3, holder)
        return rvalue_to_lua(out)
    end,


    debug = function(self)
        local holder = ffi.new("struct RValue[2]")  -- args holder

        holder[0] = gmf.rvalue_new(gm.constants.oP)
        holder[1] = gmf.rvalue_new(0)

        gmf.instance_find(out, nil, nil, 2, holder)
        return out
    end,


    debug2 = function(self)
        local holder = ffi.new("struct RValue[2]")  -- args holder

        holder[0] = gmf.rvalue_new(gm.constants.oP)
        holder[1] = gmf.rvalue_new(0)

        gmf.instance_find(out, nil, nil, 2, holder)
        


        local holder = ffi.new("struct RValue[3]")

        -- actor
        holder[0] = ffi.new("struct RValue")
        holder[0].type = 6
        holder[0].yy_object_base = ffi.cast("struct YYObjectBase *", out.yy_object_base)
        holder[0].cinstance = ffi.cast("struct CInstance *", out.cinstance)

        -- item
        holder[1] = gmf.rvalue_new(0)

        -- kind
        holder[2] = gmf.rvalue_new(3)

        gmf.item_count(out, nil, nil, 3, holder)
        return rvalue_to_lua(out)
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
        local actor, is_instance_id = rvalue_to_lua(args_typed[0])
        if not is_instance_id then actor = actor.id end
        local item  = rvalue_to_lua(args_typed[1])
        local count = rvalue_to_lua(args_typed[2])
        local kind  = rvalue_to_lua(args_typed[3])

        if not item_count_cache[actor] then item_count_cache[actor] = {} end
        item_count_cache[actor][item] = {}
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
        local actor, is_instance_id = rvalue_to_lua(args_typed[0])
        if not is_instance_id then actor = actor.id end
        local item  = rvalue_to_lua(args_typed[1])
        local count = rvalue_to_lua(args_typed[2])
        local kind  = rvalue_to_lua(args_typed[3])

        if not item_count_cache[actor] then item_count_cache[actor] = {} end
        item_count_cache[actor][item] = {}
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