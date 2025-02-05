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
        return gm.instance_exists(Proxy.get(self)) == 1
    end,


    destroy = function(self)
        if not self:exists() then return end
        local instance = Proxy.get(self)
        instance_data[instance.id] = nil
        gm.instance_destroy(instance)
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