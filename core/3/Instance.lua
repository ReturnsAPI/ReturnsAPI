-- Instance

Instance = {}

local instance_data = {}



-- ========== Static Methods ==========

Instance.wrap = function(instance)
    return Proxy.new(Wrap.unwrap(instance), metatable_instance)
end


Instance.get_data = function(namespace, instance, subtable)
    instance = Wrap.unwrap(instance)
    subtable = subtable or "__main"
    if not instance_data[instance.id] then instance_data[instance.id] = {} end
    if not instance_data[instance.id][namespace] then instance_data[instance.id][namespace] = {} end
    if not instance_data[instance.id][namespace][subtable] then instance_data[instance.id][namespace][subtable] = {} end
    return instance_data[instance.id][namespace][subtable]
end



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
        if not self:exists() then return false end
        return self.value == Wrap.unwrap(other)
    end,

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