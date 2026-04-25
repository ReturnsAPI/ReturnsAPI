-- CallbackTable

--[[
Used for storing callback functions, <br>
with a numerical priority system.
]]
---@class CallbackTable
CallbackTable = {}

local metatable


-- ========== Static Methods ==========

--[[
Returns a new CallbackTable.
]]
---@param counter? table<string, integer> A table containing `value = <integer>`. <br>Used to sync unique ID counters between CallbackTables. <br>`0` by default.
---@return CallbackTable
CallbackTable.new = function(counter)
    ---@class CallbackTable
    local t = {
        enabled_count  = 0,
        next_id        = counter or {value = 0},
        priority_count = {},
        id_lookup      = {},
    }
    return setmetatable(t, metatable)
end


-- ========== Wrapper Methods ==========

---@class CallbackTable
local methods = {}

--[[
Registers a callback function. <br>
Returns the unique ID assigned.
]]
---@param fn function The function to register.
---@param namespace string The namespace of the function.
---@param priority? integer The priority of the function. <br>`0` by default.
---@return integer id
methods.add = function(self, fn, namespace, priority)
    priority = priority or 0

    local next_id = self.next_id
    local id = next_id.value
    next_id.value = next_id.value + 1

    ---@class CallbackTableData
    local data = {
        id        = id,
        fn        = fn,
        namespace = namespace,
        priority  = priority,
        enabled   = true,
    }

    local priority_count = self.priority_count
    priority_count[priority] = priority_count[priority] or 0

    -- Get insertion index; right after the
    -- last function of the previous priority
    local index = 1
    for p, count in pairs(priority_count) do
        if p <= priority then
            index = index + count
        end
    end

    table.insert(self, index, data)
    self.id_lookup[id] = data
    priority_count[priority] = priority_count[priority] + 1
    
    self.enabled_count = self.enabled_count + 1

    return id
end

--[[
Toggles a callback function.
]]
---@param id integer The ID of the function to toggle.
---@param value boolean
methods.toggle = function(self, id, value)
    local data = self.id_lookup[id]
    if not data then return end

    if data.enabled and not value then
        data.enabled = false
        self.enabled_count = self.enabled_count - 1
    elseif not data.enabled and value then
        data.enabled = true
        self.enabled_count = self.enabled_count + 1
    end
end

--[[
Removes a callback function. <br>
Returns the removed function, or `nil` if it does not exist.
]]
---@param id integer The ID of the function to remove.
---@return function | nil
methods.remove = function(self, id)
    local data = self.id_lookup[id]
    if not data then return end
    self.id_lookup[id] = nil

    table.remove_value(self, data)

    local priority_count = self.priority_count
    local priority = data.priority
    priority_count[priority] = priority_count[priority] - 1

    if data.enabled then
        self.enabled_count = self.enabled_count - 1
    end

    return data.fn
end

--[[
Removes all callback functions in a namespace. <br>
Returns the number of functions removed.
]]
---@param namespace string The namespace to remove from.
---@return integer count
methods.remove_all = function(self, namespace)
    local priority_count = self.priority_count
    local i = #self
    local count = 0

    while i > 0 do
        local data = self[i]
        if data.namespace == namespace then
            table.remove(self, i)
            count = count + 1

            local priority = data.priority
            priority_count[priority] = priority_count[priority] - 1

            if data.enabled then
                self.enabled_count = self.enabled_count - 1
            end
        end
        i = i - 1
    end

    return count
end


-- ========== Metatables ==========

---@class CallbackTable
---@field [integer] CallbackTableData
---@field enabled_count integer Number of *currently enabled* functions.
---@field next_id table<string, integer> Contains `value`, which is the next unique ID available to assign.
---@field priority_count table<integer, integer> Stores the number of functions each priority has.
---@field id_lookup table<integer, CallbackTableData> Maps IDs to function data.

W.CallbackTable = {
    __index = methods,
}
metatable = W.CallbackTable