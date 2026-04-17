-- Table

--[[
Extensions to Lua's `table`.
]]
---@class Table
Table = {}
C.Table = Table


-- ========== Static Methods ==========

--[[
Returns the key of the value to search for, <br>
or `nil` if it does not exist.
]]
---@param t table The table to search through.
---@param value any The value to search for.
---@return any
Table.find = function(t, value)
    if not t then return log.error("Table.has: `t` is nil", 2) end
    for k, v in pairs(t) do
        if v == value then return k end
    end
    return nil
end

--[[
Merges a variable number of tables (in order) into `t`. <br>
Existing keys in `t` will be overwritten.
]]
---@param t table The table to merge into.
---@param ... table The tables to merge.
Table.merge = function(t, ...)
    for _, t2 in ipairs{...} do
        for k, v in pairs(t2) do
            t[k] = v
        end
    end
end

--[[
Combines a variable number of tables (in order) into a new one.

This is a variant of `merge` that returns a <br>
new table instead of modifying an existing one.
]]
---@param ... table The tables to combine.
---@return table
Table.combine = function(...)
    local t = {}
    Table.merge(t, ...)
    return t
end

--[[
Returns a shallow copy of the table.
]]
---@param t table The tables to copy.
---@return table
Table.shallow_copy = function(t)
    if not t then return log.error("Table.shallow_copy: `t` is nil", 2) end
    local t = {}
    for k, v in pairs(src) do
        t[k] = v
    end
    return t
end


-- Insert into ReturnAPI's `table`

table.find          = Table.find
table.merge         = Table.merge
table.combine       = Table.combine
table.shallow_copy  = Table.shallow_copy