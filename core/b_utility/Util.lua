-- Util

---@class Util
Util = new_class()
C.Util = Util

local type         = type
local tostring     = tostring
local getmetatable = debug.getmetatable
local os_clock     = os.clock
local string_sub   = string.sub
local string_find  = string.find
local print_raw    = _rom_print_raw   ---@type function
local util_tostr                    ---@type function
local str_pad_r    = String.pad_right

local sol_types = G.sol_types


-- ========== Private Methods ==========

-- This is faster than iterative `select(i, ...)`, <br>
-- and *much* faster than `table.pack/unpack`
local function tostring_args(n, prefix, arg, ...)
    local out
    if prefix then out = prefix..util_tostr(arg)
    else out = util_tostr(arg)
    end

    if n == 1 then return out end
    return out, tostring_args(n - 1, nil, ...)
end

--[[
Returns a version of print prefixed with the given guid.
]]
---@param guid string
---@return function
Util.internal.make_print = function(guid)
    return function(...)
        local n = select("#", ...)
        if n <= 0 then
            print_raw(guid..": ")
            return
        end
        print_raw(tostring_args(n, guid..": ", ...))
    end
end

local function object_get_name(inst)
    if inst.object_index then
        return gm.object_get_name(inst.object_index)
    end
    return inst
end

local indent = "    "

local function log_struct(struct)
    struct = Struct.wrap(struct)

    local str = ""
    local keys = struct:get_keys()
    for _, key in ipairs(keys) do
        str = str.."\n| "..indent..str_pad_r(key, 32).." = "..util_tostr(struct[key])
    end
    return str
end

local function log_array(array)
    array = Array.wrap(array)

    local str = ""
    local padding = #tostring(#array) + 2
    for i, v in ipairs(array) do
        str = str.."\n| "..indent..str_pad_r("["..(i - 1).."]", padding).."  "..util_tostr(v)
    end
    return str
end


-- ========== Static Methods ==========

--[[
Returns a table containing the following keys:
- `guid`
- `namespace`
- `path`
]]
---@param identifier string The guid or ReturnsAPI namespace of the mod.
---@return table | nil
Util.get_mod_info = function(identifier)
    local data = P.mod_data[identifier]
    if data then
        return {
            guid      = data.env["!guid"],
            namespace = data.namespace,
            path      = data.path,
        }
    end
end

--[[
Prints a variable number of arguments. <br>
Works just like regular `print`, but prints RAPI wrapper types instead of "table".
]]
---@param ... any
Util.print = function(...) end
Util.print = Util.internal.make_print(_ENV["!guid"])
-- Each mod gets their own version with their guid binded on import.

--[[
Returns the type of the value as a string. <br>
RAPI wrappers (which are just Lua tables) will have their type returned instead of "table".
]]
---@param value any The value to get the type of.
---@param is_wrapper? boolean If `true`, will return a bool as a second argument, <br>which will be `true` if the type is a RAPI wrapper.
---@return string
Util.type = function(value, is_wrapper)
    local _type, arg2 = type(value), false
    
    local has_RAPI = false
    if _type == "table" then
        has_RAPI = true
    elseif _type == "userdata" then
        local mt = getmetatable(value)
        if mt and sol_types[mt.__name] then
            has_RAPI = true
        end
    end

    if has_RAPI then
        local rapi = value.RAPI
        if rapi then _type = rapi end
        arg2 = true
    end
    if is_wrapper then return _type, args2 end
    return _type
end

--[[
Returns the string representation of the value. <br>
Works just like regular `tostring`, but "table" substrings <br>
are replaced with the appropriate RAPI wrapper type (if applicable).
]]
---@param value The value to get a string representation of.
---@return string
Util.tostring = function(value)
    local _type = type(value)

    local has_RAPI = false
    if _type == "table" then
        has_RAPI = true
    elseif _type == "userdata" then
        local mt = getmetatable(value)
        if mt and sol_types[mt.__name] then
            has_RAPI = true
        end
    end
        
    if has_RAPI then
        local rapi = value.RAPI
        if  rapi
        and rapi ~= "Vector" then
            local s = tostring(value)
            local index = string_find(s, ":")
            return rapi..string_sub(tostring(value), index, -1)
        end
    end
    return tostring(value)
end
util_tostr = Util.tostring

--[[
Converts a numerical value into a bool, <br>
returning `true` if > 0.5, and `false` otherwise.

Other cases: <br>
- Non-numerical, non-bool values will return `true`.
- `nil` will return `false`.

Works just like [`GM.bool`](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Variable_Functions/bool.htm).
]]
---@param value any The value to convert.
---@return bool
Util.bool = function(value)
    if type(value) == "number" then return value > 0.5 end
    return (value and true) or false
end

--[[
Benchmarks a function and prints the results (in milliseconds, up to 7 decimal places). <br>
Each frame is 16.66~ ms (although much of that is taken up by the game itself). <br>
Note: 'total time' will always be a whole number.
]]
---@param n integer The number of calls to make.
---@param fn function The function to benchmark.
---@param ... any A variable number of arguments to pass.
Util.benchmark = function(n, fn, ...)
    if type(n)  ~= "number"   then throw("n is invalid") end
    if type(fn) ~= "function" then throw("fn is invalid") end

    local total = 0
    local start
    for i = 1, n do
        start = os_clock()
        fn(...)
        total = total + (os_clock() - start)
    end

    local total_ms = total * 1000
    local avg_ms = total_ms / n

    local out = {
        "\n| Benchmark results:",
        string.format("\n|   %d calls", n),
        string.format("\n|   %.7f ms total time", total_ms),
        string.format("\n|   %.7f ms average time", avg_ms),
        string.format("\n|     (%.2f %% of frame time)", avg_ms / (16 + 2/3) * 100),
    }
    print(table.concat(out))
end

--[[
Prints the values of a hook to the console.

E.g.,
```lua
gm.post_script_hook(gm.constants.damager_calculate_damage, function(self, other, result, args)
    Util.log_hook(self, other, result, args)
end)

Hook.add_post(gm.constants.damager_calculate_damage, function(self, other, result, args)
    Util.log_hook(self, other, result, args)
end)
```
]]
---@param self any The `self` argument of the hook.
---@param other any The `other` argument of the hook.
---@param result any The `result` argument of the hook.
---@param args any The `args` argument of the hook.
Util.log_hook = function(self, other, result, args)
    -- Output
    local output = ""

    local info = debug.getinfo(2, "Sl")
    output = output.."\n| From '"..info.short_src.."' (line "..info.currentline..")\n| "

    -- self
    output = output.."\n| [self]    "
    self = Wrap.unwrap(self)
    if gm.is_struct(self) then
        output = output.."struct"..log_struct(self)
    else
        local status, ret = pcall(object_get_name, self)
        output = output..((status and tostring(ret)) or tostring(self))
    end

    -- other
    output = output.."\n| [other]   "
    other = Wrap.unwrap(other)
    if gm.is_struct(other) then
        output = output.."struct"..log_struct(other)
    else
        local status, ret = pcall(object_get_name, other)
        output = output..((status and tostring(ret)) or tostring(other))
    end

    -- result
    if result then
        output = output.."\n| [result]  "
        result = Wrap.unwrap(result.value)
        if gm.is_struct(result) then
            output = output.."struct"..log_struct(result)
        elseif gm.is_array(result) then
            output = output.."array"..log_array(result)
        else
            local status, ret = pcall(object_get_name, result)
            output = output..((status and tostring(ret)) or tostring(result))
        end
    end

    -- args
    if args then
        output = output.."\n| \n| [args]"
        for i, arg in ipairs(args) do
            arg = Wrap.unwrap(arg.value)
            if gm.is_struct(arg) then
                output = output.."\n| struct"..log_struct(arg)
            elseif gm.is_array(arg) then
                output = output.."\n| array"..log_array(arg)
            else
                local status, ret = pcall(object_get_name, arg)
                output = output.."\n| "..((status and tostring(ret)) or tostring(arg))
            end
        end
    end

    print(output)
end

--@static
--[[
Prints the results of `gm.debug_get_callstack()`, <br>
in order of most (top) to least (bottom) recent calls.
]]
Util.gm_trace = function()
    local array = Array.wrap(gm.debug_get_callstack())
    array:print()
end


-- ========== Deprecated Methods ==========

--@static
--@return       bool
--@param        n           | number    | The chance to succeed, between `0` and `1`.
--[[
**[!] DEPRECATED; recommended to call and check `math.random` instead.**

Rolls for a binary outcome. <br>
Returns `true` on success, and `false` otherwise.
]]
---@deprecated
---@param n number The chance to succeed, between `0` and `1`.
Util.chance = function(n)
    return math.random() <= n
end

--[[
**[!] DEPRECATED; use `Table.print` instead.**

Prints the contents of a table recursively.
]]
---@deprecated
---@param t table The table to print.
Util.table_print = function(t)
    log.warning("`Util.table_print` is deprecated; use `Table.print` instead.")
end

--[[
**[!] DEPRECATED; use `Table.find` instead.**

Returns `true` if the table contains the value, and `false` otherwise.
]]
---@deprecated
---@param t table
---@param value any
---@return boolean
Util.table_has = function(t, value)
    if not t then return log.error("Util.table_has: t is nil", 2) end
    for k, v in pairs(t) do
        if v == value then return true end
    end
    return false
end

--[[
**[!] DEPRECATED; use `Table.find` instead.**

Returns the key of the value to search for, <br>
or `nil` if it does not exist.

If multiple of the specified value exists, <br>
the first key found will be returned.
]]
---@deprecated
---@param t table
---@param value any
---@return any
Util.table_find = function(t, value)
    if not t then return log.error("Util.table_find: t is nil", 2) end
    for k, v in pairs(t) do
        if v == value then return k end
    end
    return nil
end

--[[
**[!] DEPRECATED; use `Table.remove_value` instead.**

Removes the first occurence of the specified <br>
value from a numerically-indexed table.
]]
---@deprecated
---@param t table
---@param value any
Util.table_remove_value = function(t, value)
    if not t then return log.error("Util.table_remove_value: t is nil", 2) end
    for i, v in ipairs(t) do
        if v == value then
            table.remove(t, i)
            return
        end
    end
end

--[[
**[!] DEPRECATED; recommended to iterate with `pairs/ipairs` instead.**

Returns a table of keys of the specified table.
]]
---@deprecated
---@param t table
---@return table keys
Util.table_get_keys = function(t)
    if not t then return log.error("Util.table_get_keys: t is nil", 2) end
    local keys = {}
    for k, _ in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end

--[[
**[!] DEPRECATED; use `Table.merge_new` and `Table.append_new` instead.**

Returns a new table containing the values from input tables. <br>
The tables are merged in order.

Combining two number indexed tables will order them in the order that they were inputted. <br>
When mixing number indexed and string keys, the indexed values will come first in order, while string keys will come after unordered. <br>
Multiple tables with the same string key will take the value of the last table in argument order.
]]
---@deprecated
---@param ... table
---@return table
Util.table_merge = function(...)
    local new = {}
    for _, t in ipairs{...} do
        for k, v in pairs(t) do
            if tonumber(k) then
                while new[k] do k = k + 1 end
            end
            new[k] = v
        end
    end
    return new
end

--[[
**[!] DEPRECATED; use `Table.merge` instead.**

Appends keys from `src` to `dest`. <br>
Existing keys will be overwritten.
]]
---@deprecated
---@param dest table
---@param src table
Util.table_append = function(dest, src)
    if not dest then return log.error("Util.table_append: dest is nil", 2) end
    if not src  then return log.error("Util.table_append: src is nil",  2) end
    for k, v in pairs(src) do
        dest[k] = v
    end
end

--[[
**[!] DEPRECATED; use `Table.append` instead.**

Inserts a table of values (`src`) to `dest`. <br>
Both should be *numerically-indexed* tables.
]]
---@deprecated
---@param dest table
---@param src table
Util.table_insert = function(dest, src)
    if not dest then return log.error("Util.table_insert: dest is nil", 2) end
    if not src  then return log.error("Util.table_insert: src is nil",  2) end
    for _, v in ipairs(src) do
        table.insert(dest, v)
    end
end

--[[
**[!] DEPRECATED; use `Table.shallow_copy` instead.**

Returns a shallow copy of the table.
]]
---@deprecated
---@param t table
---@return table
Util.table_shallow_copy = function(src)
    if not src then return log.error("Util.table_shallow_copy: src is nil", 2) end
    local t = {}
    for k, v in pairs(src) do
        t[k] = v
    end
    return t
end

--[[
**[!] DEPRECATED**

Returns a string encoding of a *numerically-indexed* table. <br>
The table should contain only basic Lua types (`bool`, `number`, `string`, `table`, `nil`).
]]
---@deprecated
---@param t table
---@return string encoding
Util.table_to_string = function(t)
    local str = ""
    for i = 1, #table_ do
        local v = table_[i]
        if type(v) == "table" then str = str.."[[||"..Util.table_to_string(v).."||]]||"
        else str = str..tostring(v).."||"
        end
    end
    return string.sub(str, 1, -3)
end

--[[
**[!] DEPRECATED**

Returns the table from a string encoding.
]]
---@deprecated
---@param encoding string
---@return table
Util.string_to_table = function(encoding)
    local raw = gm.string_split(encoding, "||")
    local parsed = {}
    local i = 0
    while i < #raw do
        i = i + 1
        if raw[i] == "[[" then  -- table
            local inner = raw[i + 1].."||"
            local j = i + 2
            local open = 1
            while true do
                if raw[j] == "[[" then open = open + 1
                elseif raw[j] == "]]" then open = open - 1
                end
                if open <= 0 then break end
                inner = inner..raw[j].."||"
                j = j + 1
            end
            table.insert(parsed, Util.string_to_table(string.sub(inner, 1, -3)))
            i = j
        else
            local value = raw[i]
            if tonumber(value) then value = tonumber(value)
            elseif value == "true" then value = true
            elseif value == "false" then value = false
            elseif value == "nil" then value = nil
            end
            table.insert(parsed, value)
        end
    end
    return parsed
end

--[[
**[!] DEPRECATED**

A version of `setmetatable()` that allows for Lua 5.2's `__gc` metamethod.
]]
---@deprecated
---@param t table
---@param mt table
---@return table t
Util.setmetatable_gc = function(t, mt)
    -- `setmetatable` but with `__gc` metamethod enabled
    if mt.__gc then
        -- Create new userdata, and set its `__gc` to call `mt`'s version
        local cproxy = newproxy(true)
        getmetatable(cproxy).__gc = function(self) mt.__gc(t) end
        t[cproxy] = true    -- This will show up in keys
                            -- You can mostly get around this by overriding
                            -- __pairs and __ipairs though, which Array and
                            -- Struct already do for iteration
    end
    return setmetatable(t, mt)
end

--[[
**[!] DEPRECATED; use `Table.set` instead.**

Returns a set from a list of keys <br>
(i.e., table where `k = true` for all `k` in the list).
]]
---@deprecated
---@param t table
---@return table set
Util.set = function(t)
    local set = {}
    for _, k in ipairs(t) do
        set[k] = true
    end
    return set
end

--[[
**[!] DEPRECATED; use `Table.enum` instead.**

Returns an enum from a list of keys <br>
(i.e., table where `k = <number>` for all `k` in the list).
]]
---@deprecated
---@param t table
---@param start? float
---@param add? float
---@param mult? float
---@return table enum
Util.enum = function(t, start, add, mult)
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

--@static
--@return       string
--@param        str         | string    | The string to pad.
--@param        length      | number    | The desired string length.
--@optional     char        | string    | The character to use. <br>`" "` (space) by default.
--[[
**[!] DEPRECATED; use `String.pad_left` instead.**

Returns a string with character padding on the
left side to match the desired string length.
]]
---@deprecated
---@param s string The table to pad.
---@param length integer The desired string length.
---@param char string The character to use. <br>`" "` (space) by default.
---@return string
Util.pad_string_left = function(str, length, char)
    str = tostring(str)
    char = char or " "
    local len = length - #str
    for i = 1, len do
        str = char..str
    end
    return str
end


--@static
--@return       string
--@param        str         | string    | The string to pad.
--@param        length      | number    | The desired string length.
--@optional     char        | string    | The character to use. <br>`" "` (space) by default.
--[[
**[!] DEPRECATED; use `String.pad_right` instead.**

Returns a string with character padding on the
right side to match the desired string length.
]]
---@deprecated
---@param s string The table to pad.
---@param length integer The desired string length.
---@param char string The character to use. <br>`" "` (space) by default.
---@return string
Util.pad_string_right = function(str, length, char)
    str = tostring(str)
    char = char or " "
    local len = length - #str
    for i = 1, len do
        str = str..char
    end
    return str
end


--[[
**[!] DEPRECATED; use `String.pad_left_to_width` instead.**

Returns a string with character padding on the <br>
left side to match the desired pixel width. <br>
Width information is based on the current font.
]]
---@deprecated
---@param str string The table to pad.
---@param width float The desired pixel width.
---@param char string The character to use. <br>`" "` (space) by default.
---@return string
Util.pad_string_left_to_width = function(str, width, char)
    str = tostring(str)
    char = char or " "

    local str_width  = gm.scribble_get_width(str)
    local char_width = gm.scribble_get_width(char)

    while str_width < width do
        str = char..str
        str_width = str_width + char_width
    end

    return str
end

--[[
**[!] DEPRECATED; use `String.pad_right_to_width` instead.**

Returns a string with character padding on the <br>
right side to match the desired pixel width. <br>
Width information is based on the current font.
]]
---@deprecated
---@param str string The table to pad.
---@param width float The desired pixel width.
---@param char string The character to use. <br>`" "` (space) by default.
---@return string
Util.pad_string_right_to_width = function(str, width, char)
    str = tostring(str)
    char = char or " "

    local str_width  = gm.scribble_get_width(str)
    local char_width = gm.scribble_get_width(char)

    while str_width < width do
        str = str..char
        str_width = str_width + char_width
    end

    return str
end