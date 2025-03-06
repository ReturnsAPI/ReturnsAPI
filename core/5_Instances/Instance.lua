-- Instance

Instance = new_class()

local instance_data = {}
local wrapper_cache = setmetatable({}, {__mode = "v"})
local get_data_cache = setmetatable({}, {__mode = "k"})



-- ========== Internal ==========

-- For internal use; skips type checks if valid instance is guaranteed
-- Additionally, can specify metatable to use instead of having to check
-- Use `check_if_player` if unsure if actor is a player or not
Instance.internal.wrap = function(instance, mt, check_if_player)
    local id = instance.id
    if wrapper_cache[id] then return wrapper_cache[id] end

    if not mt then
        mt = metatable_instance
        local object_index = instance.object_index
        if object_index == gm.constants.oP then
            mt = metatable_player
        elseif gm.object_is_ancestor(object_index, gm.constants.pActor) == 1 then
            mt = metatable_actor
        end
    end

    if check_if_player then
        if instance.object_index == gm.constants.oP then
            mt = metatable_player
        end
    end

    local wrapper = Proxy.new(instance, mt)
    wrapper_cache[id] = wrapper
    return wrapper
end



-- ========== Static Methods ==========

-- $static
-- $aref        exists-static
-- $return      bool
-- $param       instance    | Instance  | The instance to check.
--[[
Returns `true` if the instance exists, and `false` otherwise.
Also exists as an $instance method, Instance#exists-instance$.
]]--
Instance.exists = function(instance)
    instance = Wrap.unwrap(instance)
    if type(instance) == "string" then return false end
    return gm.instance_exists(instance) == 1
end


-- $static
-- $return      Instance
-- $param       instance    | Instance  | The instance to check.
--[[
Returns the first instance of the specified object,
or an invalid instance (value of -4).
]]--
Instance.find = function(...)
    local t = {...}     -- Variable number of object_indexes

    -- If argument is a non-wrapper table, use it as the loop table
    if type(t[1]) == "table" and (not t[1].RAPI) then t = t[1] end

    -- Loop through object_indexes
    for _, object in ipairs(t) do
        object = Wrap.unwrap(object)
        local inst = gm.instance_find(object, 0)

        -- <Insert custom object finding here>

        if inst ~= -4 then
            return Instance.internal.wrap(inst)
        end
    end

    -- No instance found
    return Instance.wrap_invalid()
end


-- $static
-- $return      table, bool
-- $param       ...         |           | A variable amount of objects to check. <br>Alternatively, a table containing them can be provided.
--[[
Returns a table of all instances of the specified object,
and a boolean that is `true` if the table is *not* empty.
]]--
Instance.find_all = function(...)
    local t = {...}     -- Variable number of object_indexes

    -- If argument is a non-wrapper table, use it as the loop table
    if type(t[1]) == "table" and (not t[1].RAPI) then t = t[1] end

    local insts = {}

    -- Loop through object_indexes
    for _, object in ipairs(t) do
        object = Wrap.unwrap(object)
        local count = gm._mod_instance_number(object)
        for n = 0, count - 1 do
            local inst = gm.instance_find(object, n)
            table.insert(insts, Instance.internal.wrap(inst))
        end

        -- <Insert custom object finding here>
    end

    return insts, #insts > 0
end


-- $static
-- $return      number
-- $param       object      | Object    | The object to check.
--[[
Returns the instance count of the specified object.
]]--
Instance.count = function(object)
    return gm._mod_instance_number(object)
end


-- $static
-- $return      Instance
-- $param       instance    | CInstance | The instance to wrap.
--[[
Returns an Instance wrapper containing the provided instance.
]]--
Instance.wrap = function(instance)
    instance = Wrap.unwrap(instance)
    if type(instance) == "number" then instance = gm.CInstance.instance_id_to_CInstance[instance] end
    if userdata_type(instance) ~= "sol.CInstance*" then return Instance.wrap_invalid() end
    return Instance.internal.wrap(instance)
end


-- $static
-- $return      Instance
--[[
Returns an Instance wrapper containing a non-existent instance (specifically, the value `-4`).
]]--
Instance.wrap_invalid = function()
    return Proxy.new(-4, metatable_instance)
end


-- Substitute for Wrap.wrap, since if Arrays are not being wrapped
-- in RAPI, the only thing left in there is Instance wrapping
Instance.try_wrap = function(value)
    if userdata_type(value) == "sol.CInstance*" then return Instance.internal.wrap(value) end
    return value
end


Instance.get_data = function(instance, subtable, namespace, default_namespace)
    -- DEBUG: Print size of get_data_cache
    -- local count = 0
    -- for k, v in pairs(get_data_cache) do count = count + 1 end
    -- print("#get_data_cache: "..count)

    instance = Wrap.unwrap(instance)

    -- Caching .id
    -- Dunno if this really saves anything though
    local id = get_data_cache[instance]
    if not id then
        id = instance.id
        get_data_cache[instance] = id

    -- else print("Got from cache!")
    end

    subtable = subtable or "__main"
    namespace = namespace or "RAPI" -- Internal RAPI calling of this is not namespace-bound
    if not instance_data[id] then instance_data[id] = {} end
    if not instance_data[id][namespace] then instance_data[id][namespace] = {} end
    if not instance_data[id][namespace][subtable] then instance_data[id][namespace][subtable] = {} end
    return instance_data[id][namespace][subtable]
end


-- Instance.debug_print_cache = function()
--     for k, v in pairs(wrapper_cache) do
--         print(k, v)
--     end
-- end



-- ========== Instance Methods ==========

methods_instance = {

    -- $instance
    -- $aref        exists-instance
    -- $return      bool
    -- $param       instance    | Instance  | The instance to check.
    --[[
    Returns `true` if the instance exists, and `false` otherwise.
    Also exists as a $static method, Instance#exists-static$.
    ]]--
    exists = function(self)
        return gm.instance_exists(self.value) == 1
    end,


    -- $instance
    --[[
    Destroys the instance.
    ]]--
    destroy = function(self)
        if not self:exists() then return end
        instance_data[self.value.id] = nil
        gm.instance_destroy(self.value)
    end,


    -- $instance
    -- $return      bool
    -- $param       other       | Instance  | The other instance to check.
    --[[
    Returns `true` if this instance is the same one as `other`.
    ]]--
    same = function(self, other)
        -- if not self:exists() then return false end   -- From benchmarking - Largely increased performance cost for this
        return self.value == Wrap.unwrap(other)
    end,


    -- $instance
    -- $return      bool
    -- $param       object      | Object    | The object to check.
    -- $optional    x           | number    | The x position to check at. <br>Uses this instance's current position by default.
    -- $optional    y           | number    | The other instance to check. <br>Uses this instance's current position by default.
    --[[
    Returns `true` if this instance is colliding with *any* instance of the specified object.
    ]]--
    is_colliding = function(self, object, x, y)
        -- if not self:exists() then return false end
        if self.value == -4 then return false end
        object = Wrap.unwrap(object)
        return self.value:place_meeting(x or self.x, y or self.y, object) == 1
    end

}



-- ========== Metatables ==========

metatable_instance = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(t) end
        if k == "RAPI" then return getmetatable(t):sub(14, -1) end

        -- Methods
        if methods_instance[k] then
            return methods_instance[k]
        end

        -- Get instance variable
        return Wrap.wrap(gm.variable_instance_get(Proxy.get(t), k))
    end,


    __newindex = function(t, k, v)
        -- Set instance variable
        gm.variable_instance_set(Proxy.get(t), k, Wrap.unwrap(v))
    end,

    
    __metatable = "RAPI.Wrapper.Instance"
}



-- ========== instance_data GC ==========

-- TODO replace with memory.dynamic_hook

gm.post_script_hook(gm.constants.room_goto, function(self, other, result, args)
    -- On room change, remove non-existent instances from `instance_data`
    for k, v in pairs(instance_data) do
        if gm.instance_exists(k) == 0 then
            instance_data[k] = nil
        end
    end
end)


gm.post_script_hook(gm.constants.actor_set_dead, function(self, other, result, args)
    -- Remove `instance_data` on non-player kill
    local actor = args[1].value
    if actor.object_index ~= gm.constants.oP then
        instance_data[actor.id] = nil
    end
end)


gm.post_script_hook(gm.constants.actor_transform, function(self, other, result, args)
    -- Move `instance_data` to new instance
    local id = args[1].value.id
    if instance_data[id] then
        instance_data[args[2].value.id] = instance_data[id]
        instance_data[id] = nil
    end
end)



_CLASS["Instance"] = Instance