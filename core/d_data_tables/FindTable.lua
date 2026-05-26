-- FindTable

--[[
Used for content lookup tables.
]]
---@class FindTableClass
FindTable = {}

local metatable


-- ========== Static Methods ==========

--[[
Returns a new FindTable.
]]
---@return FindTable
FindTable.new = function()
    return setmetatable({}, metatable)
end


-- ========== Wrapper Methods ==========

---@class FindTable
local methods = {}

--[[
Stores a value with `identifier` and `namespace` (and optionally `id`).
]]
---@param value any The value to set.
---@param identifier string The identifier of the value.
---@param namespace string The namespace of the value.
---@param id? number The numerical ID of the value.
methods.set = function(self, value, identifier, namespace, id)
    ---@class FindTableData
    local data = {
        value      = value,
        identifier = identifier,
        namespace  = namespace,
        id         = id,
    }

    local ns_table = self[namespace]
    if not ns_table then
        ns_table = {}
        self[namespace] = ns_table
    end
    ns_table[identifier] = data
    if id then self[id] = data end
end

--[[
Retrieves a value with `identifier` and `namespace`.

Behavior if the user did not provide a namespace:
- Check in the calling mod's namespace first.
- Check the rest of the namespaces in a non-deterministic order.

If you need to retrieve by `id`, simply do `<find_table>[<id>].value`.
]]
---@param identifier string The identifier of the value.
---@param namespace string The namespace of the value.
---@param namespace_is_specified boolean `true` if the user passed in a namespace.
---@return any
methods.get = function(self, identifier, namespace, namespace_is_specified)
    -- Namespace find
    local ns_table = self[namespace]
    if ns_table then
        local data = ns_table[identifier]
        if data then return data.value end
    end

    -- Global find (if namespace not provided)
    if not namespace_is_specified then
        for ns, ns_table in pairs(self) do
            if ns ~= namespace then
                ---@type FindTableData
                local data = ns_table[identifier]
                if data then return data.value end
            end
        end
    end
end

--[[
Retrieves a table of values with `namespace`.

Behavior if the user did not provide a namespace:
- Fetch from all namespaces, with calling mod's namespace first.
]]
---@param namespace string The namespace to retrieve from.
---@param namespace_is_specified boolean `true` if the user passed in a namespace.
---@return table
methods.get_all = function(self, namespace, namespace_is_specified)
    local t = {}

    -- Namespace find
    local ns_table = self[namespace]
    if ns_table then
        for identifier, data in pairs(ns_table) do
            table.insert(t, data.value)
        end
    end

    -- Global find (if namespace not provided)
    if not namespace_is_specified then
        for ns, ns_table in pairs(self) do
            if ns ~= namespace then
                for identifier, data in pairs(ns_table) do
                    table.insert(t, data.value)
                end
            end
        end
    end

    return t
end

--[[
Applies a function to all values. <br>
The function should accept `value` as the argument, and return the value to set.
]]
---@param fn function The function to apply.
methods.map = function(self, fn)
    for ns, ns_table in pairs(self) do
        for identifier, data in pairs(ns_table) do
            local new_value = fn(data.value)
            if new_value then ns_table[identifier].value = new_value end
        end
    end
end


-- ========== Metatables ==========

---@class FindTable
---@field [string] table<string, FindTableData>
---@field [number] FindTableData

W.FindTable = {
    __index = methods,
}
metatable = W.FindTable