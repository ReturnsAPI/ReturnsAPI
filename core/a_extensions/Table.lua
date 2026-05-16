-- Table

--[[
Extensions to Lua's `table`.
]]
---@class Table
Table = {}
C.Table = Table

local tostring      = tostring
local debug_getinfo = debug.getinfo
local string_sub    = string.sub
local util_type     ---@type function


-- ========== Internal ==========

local indent_amount = 4
local prefix = "| "

local function stringify(t, indent)
    local str = ""
    local max_index = 0

    local indent_str = ""
    for i = 1, indent do indent_str = indent_str.." " end

    -- Indexed values
    if t[1] then
        for i, v in ipairs(t) do
            local tostr = tostring(v)
            local value = " = "..tostr

            local _type = util_type(v)
            if _type == "table" then
                value = ":\n"..stringify(v, indent + indent_amount)
            elseif _type == "string" then
                value = " = \""..tostr.."\""
            end

            str = str.."\n"..prefix..indent_str..i..value
            max_index = i
        end
    end

    -- Key-value pairs
    for k, v in pairs(t) do

        -- Do not print keys that were covered in ipairs
        if type(k) ~= "number" or k > max_index then
            local tostr = tostring(v)
            local value = " = "..tostr

            local _type = util_type(v)
            if _type == "table" then
                value = ":\n"..stringify(v, indent + indent_amount)
            elseif _type == "string" then
                value = " = \""..tostr.."\""
            end

            str = str.."\n"..prefix..indent_str..k..value
        end
    end

    -- Remove initial "\n" if it exists
    return (#str > 0 and string_sub(str, 2, -1)) or str
end


-- ========== Static Methods ==========

--[[
Prints the contents of a table recursively.
]]
---@param t table The table to print.
Table.print = function(t)
    if not util_type then util_type = Util.type end

    local info = debug_getinfo(2, "Sl")
    print(string.format(
        "\n| From '%s' (line %d)\n%s",
        info.short_src,
        info.currentline,
        stringify(t, 0))
    )
end

--[[
Returns the key of the value to search for, <br>
or `nil` if it does not exist.
]]
---@param t table The table to search through.
---@param value any The value to search for.
---@return any
Table.find = function(t, value)
    if not t then throw("t is nil") end
    for k, v in pairs(t) do
        if v == value then return k end
    end
    return nil
end

--[[
Removes the first occurence of the <br>
specified value from the table.
]]
---@param t table The table to search through.
---@param value any The value to remove.
Table.remove_value = function(t, value)
    if not t then throw("t is nil") end
    for i, v in ipairs(t) do
        if v == value then
            table.remove(t, i)
            return
        end
    end
end

--[[
Returns a shallow copy of the table.
]]
---@param t table The table to copy.
---@return table
Table.shallow_copy = function(t)
    if not t then throw("t is nil") end
    local t2 = {}
    for k, v in pairs(t) do
        t2[k] = v
    end
    return t2
end

--[[
Merges a variable number of dictionary tables (in order) into `t`. <br>
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
Merges a variable number of dictionary tables (in order) into a new one.

This is a variant of `merge` that returns a <br>
new table instead of modifying an existing one.
]]
---@param ... table The tables to merge.
---@return table
Table.merge_new = function(...)
    local t = {}
    for _, t2 in ipairs{...} do
        for k, v in pairs(t2) do
            t[k] = v
        end
    end
    return t
end

--[[
Appends a variable number of array tables (in order) to `t`.
]]
---@param t table The table to append to.
---@param ... table The tables to append.
Table.append = function(t, ...)
    local i = #t + 1
    for _, t2 in ipairs{...} do
        for __, v in ipairs(t2) do
            t[i] = v
            i = i + 1
        end
    end
end

--[[
Appends a variable number of array tables (in order) to a new one.

This is a variant of `append` that returns a <br>
new table instead of modifying an existing one.
]]
---@param ... table The tables to append.
Table.append_new = function(...)
    local t, i = {}, 1
    for _, t2 in ipairs{...} do
        for __, v in ipairs(t2) do
            t[i] = v
            i = i + 1
        end
    end
    return t
end

--[[
Returns a set from a list of keys. <br>
**set** - table where `k = true` for all `k` in the list
]]
---@param t table The list of keys.
---@return table<any, true> set
Table.set = function(t)
    local set = {}
    for _, k in ipairs(t) do
        set[k] = true
    end
    return set
end

--[[
Returns an enum from a list of keys. <br>
**enum** - table where `k = <number>` for all `k` in the list
]]
---@param t table The list of keys.
---@param start? float The starting value for the first element. <br>`1` by default.
---@param add? float Increment for each key. <br>`1` by default.
---@param mult? float Multiplier for each key (applied *after* `add`). <br>`1` by default.
---@return table<any, float> enum
Table.enum = function(t, start, add, mult)
    start = start or 1
    add   = add   or 1
    mult  = mult  or 1

    local enum = {}
    for _, k in ipairs(t) do
        enum[k] = start
        start = (start + add) * mult
    end
    return enum
end


-- Insert into ReturnAPI's `table`

table.find          = Table.find
table.remove_value  = Table.remove_value
table.shallow_copy  = Table.shallow_copy
table.merge         = Table.merge
table.merge_new     = Table.merge_new
table.append        = Table.append
table.append_new    = Table.append_new
table.set           = Table.set
table.enum          = Table.enum