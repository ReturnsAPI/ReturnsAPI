-- Instance

Instance = {}

local instance_data = {}
local wrapper_cache = setmetatable({}, {__mode = "v"})



-- ========== Internal ==========

-- For internal use; skips type checks if valid instance is guaranteed
-- Additionally, can specify metatable to use instead of having to check
-- Use `check_if_player` if unsure if actor is a player or not
Instance_wrap_internal = function(instance, mt, check_if_player)
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

Instance.wrap = function(instance, instance_type)
    instance = Wrap.unwrap(instance)
    if type(instance) == "number" then instance = gm.CInstance.instance_id_to_CInstance[instance] end
    if type(instance) ~= "userdata" then return Instance.wrap_invalid() end
    return Instance_wrap_internal(instance)
end


Instance.wrap_invalid = function()
    return Proxy.new(-4, metatable_instance)
end


Instance.get_data = function(namespace, instance, subtable)
    instance = Wrap.unwrap(instance)
    local id = instance.id
    subtable = subtable or "__main"
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

    exists = function(self)
        return gm.instance_exists(self.value) == 1
    end,


    destroy = function(self)
        if not self:exists() then return end
        instance_data[self.value.id] = nil
        gm.instance_destroy(self.value)
    end,


    same = function(self, other)
        -- if not self:exists() then return false end   -- From benchmarking - Largely increased performance cost for this
        return self.value == Wrap.unwrap(other)
    end,


    is_colliding = function(self, object, x, y)
        if not self:exists() then return false end
        object = Wrap.unwrap(object)
        return self.value:place_meeting(x or self.x, y or self.y, object) == 1
    end

}



-- ========== Metatables ==========

metatable_instance = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(t) end

        -- Methods
        if methods_instance[k] then
            return methods_instance[k]
        end

        -- Get instance variable
        return gm.variable_instance_get(Proxy.get(t), k)
    end,


    __newindex = function(t, k, v)
        -- Set instance variable
        gm.variable_instance_set(Proxy.get(t), k, v)
    end,

    
    __metatable = "Instance"
}



return Instance