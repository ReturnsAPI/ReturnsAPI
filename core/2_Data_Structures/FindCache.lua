-- FindCache
-- Cache structure for resource lookups

local mt

FindCache = {
    --[[
    Returns a new find cache.
    ]]
    new = function()
        return setmetatable({}, mt)
    end
}

mt = {__index = {

    --[[
    Set a value in cache.  
    If the value is a non-wrapper table, automatically populates  
    with the properties `identifier` and `namespace` (and `id` optionally).  
    ]]
    set = function(self, value, identifier, namespace, id)
        -- Create namespace cache if existn't
        self[namespace] = self[namespace] or {}

        -- Auto-add some properties if non-wrapper table
        if Util.type(value) == "table" then
            value.identifier = identifier
            value.namespace  = namespace
            value.id         = id
        end

        -- Set value
        self[namespace][identifier] = value
        if id then self[id] = value end
    end,


    --[[
    Get a value from cache.  
    If no namespace is provided, checks all of them in a non-deterministic* order.  
    * Guaranteed to check in the calling mod's namespace first.  
    If a number is passed, get by numerical ID.  
    ]]
    get = function(self, identifier, namespace, namespace_is_specified)
        -- Get by numerical ID
        if type(identifier) == "number" then
            return self[identifier]
        end

        -- Check in namespace table
        if self[namespace] then
            local cached = self[namespace][identifier]
            if cached then return cached end
        end

        -- Global find (no explicit namespace argument)
        -- Check in all remaining namespace tables
        if not namespace_is_specified then
            for ns, ns_table in pairs(self) do
                if  type(ns) ~= "number"
                and ns ~= namespace then
                    local cached = ns_table[identifier]
                    if cached then return cached end
                end
            end
        end
    end,


    --[[
    Get a table of values from specified namespace cache.  
    If no namespace is provided, checks all of them in a non-deterministic* order.  
    * Guaranteed to check in the calling mod's namespace first.  
    If `key` is provided, the values will be the key's values.  
    ]]
    get_all = function(self, namespace, namespace_is_specified, key)
        local t = {}

        -- Get all in namespace table
        if self[namespace] then
            for identifier, value in pairs(self[namespace]) do
                if key then table.insert(t, value[key])
                else        table.insert(t, value)
                end
            end
        end

        -- Global get (no explicit namespace argument)
        -- Get in all remaining namespace tables
        if not namespace_is_specified then
            for ns, ns_table in pairs(self) do
                if  type(ns) ~= "number"
                and ns ~= namespace then
                    for identifier, value in pairs(ns_table) do
                        if key then table.insert(t, value[key])
                        else        table.insert(t, value)
                        end
                    end
                end
            end
        end

        return t
    end,


    --[[
    Apply a function to all cached values.  
    The function should accept `value` as the only argument, and return the new value to set.  
    ]]
    map = function(self, fn)
        -- Loop through all namespace tables
        -- and replace elements with `fn(value)` if there is a return value
        for ns, ns_table in pairs(self) do

            -- Numerical ID
            if type(ns) == "number" then
                self[ns] = fn(ns_table) or self[ns]

            -- Namespace table
            else
                for identifier, value in pairs(ns_table) do
                    ns_table[identifier] = fn(value) or ns_table[identifier]
                end
            end
        end
    end

}}