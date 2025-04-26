-- Utility

Util = new_class()

run_once(function()
    __gc_proxies = setmetatable({}, {__mode = "k"})
    __gc_proxies_2 = setmetatable({}, {__mode = "kv"})
end)



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@param        ...         |           | A variable amount of arguments to print.
--[[
Prints a variable number of arguments.
Works just like regular `print`, but prints wrapper types instead of "table".

Automatically replaces `print()` with this on `.auto()` import;
the original is saved as `lua_print()`.
]]
Util.print = function(...)
    local args = table.pack(...)
    for i = 1, args.n do
        args[i] = Util.tostring(args[i])
    end
    print(table.unpack(args))
end


--@static
--@return       string, [bool]
--@param        value       |           | The value to check.
--@optional     is_RAPI?    | bool      | If `true`, will return a bool as a second argument. <br>It will be `true` if the type is a RAPI wrapper, and `false` otherwise.
--[[
Returns the type of the value as a string.
Wrappers (which are just tables) will have their type returned instead of "table".

Automatically replaces `type()` with this on `.auto()` import;
the original is saved as `lua_type()`.
]]
Util.type = function(value, is_RAPI)
    local _type = type(value)
    arg2 = false    -- is_RAPI? bool
    if _type == "table" then
        local RAPI = value.RAPI
        if RAPI then _type = RAPI end
        arg2 = true
    end
    if is_RAPI then return _type, arg2 end
    return _type
end


--@static
--@return       string
--@param        value       |           | The value to make a string representation of.
--[[
Returns the string representation of the value.
Works just like regular `tostring`, but "table" substrings
are replaced with the appropriate wrapper type (if applicable).

Automatically replaces `tostring()` with this on `.auto()` import;
the original is saved as `lua_tostring()`.
]]
Util.tostring = function(value)
    if type(value) == "table" and value.RAPI then
        return value.RAPI..tostring(value):sub(6, -1)
    end
    return tostring(value)
end


--@static
--[[
Prints the results of `GM.debug_get_callstack()`.
The value at the top was the most recent previous call.
]]
Util.gm_trace = function(value)
    local out = RValue.new(0)
    gmf.debug_get_callstack(out, nil, nil, 0, nil)
    local array = RValue.to_wrapper(out)
    array:print()
end


--@static
--@return       bool
--@param        value       |           | The value to convert.
--[[
Converts a numerical value into a bool,
returning `true` if > 0.5, and `false` otherwise.

Other cases:
Non-numerical, non-bool values will return `true`.
`nil` will return `false`.

Works just like [`GM.bool`](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Variable_Functions/bool.htm).
]]
Util.bool = function(value)
    if type(value) == "number" then return value > 0.5 end
    return (value and true) or false
end


--@static
--@return       bool
--@param        n           | number    | The chance to succeed, between `0` and `1`.
--[[
Rolls for a binary outcome.
Returns `true` on success, and `false` otherwise.
]]
Util.chance = function(n)
    return math.random() <= n
end


--@static
--@return       number
--@param        x           | number    | The value to ease, between `0` and `1`.
--@optional     n           | number    | The easing power. <br>`2` (quadratic) by default.
--[[
Returns an ease-in value for a given value `x` between `0` and `1`.
]]
Util.ease_in = function(x, n)
    return x^(n or 2)
end


--@static
--@return       number
--@param        x           | number    | The value to ease, between `0` and `1`.
--@optional     n           | number    | The easing power. <br>`2` (quadratic) by default.
--[[
Returns an ease-out value for a given value `x` between `0` and `1`.
]]
Util.ease_out = function(x, n)
    return 1 - (1 - x)^(n or 2)
end


--@static
--@return       bool
--@param        table       | table     | The table to search through.
--@param        value       |           | The value to search for.
--[[
Returns `true` if the table contains the value, and `false` otherwise.
]]
Util.table_has = function(t, value)
    for k, v in pairs(t) do
        if v == value then return true end
    end
    return false
end


--@static
--@return       string
--@param        table       | table     | The table to search through.
--@param        value       |           | The value to search for.
--[[
Returns the key of the value to search for.
]]
Util.table_find = function(t, value)
    for k, v in pairs(t) do
        if v == value then return k end
    end
    return nil
end


--@static
--@param        table       | table     | The table to search through.
--@param        value       |           | The value to remove.
--[[
Removes the first occurence of the specified value from the table.
]]
Util.table_remove_value = function(t, value)
    for k, v in pairs(t) do
        if v == value then
            t[k] = nil
            return
        end
    end
end


--@static
--@return       table
--@param        table       | table     | The table to get the keys of.
--[[
Returns a table of keys of the specified table.
]]
Util.table_get_keys = function(t)
    local keys = {}
    for k, v in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end


--@static
--@return       table
--@param        ...         |           | A variable amount of tables to combine.
--[[
Returns a new table containing the values from input tables.
The tables are merged in order.

Combining two number indexed tables will order them in the order that they were inputted.
When mixing number indexed and string keys, the indexed values will come first in order, while string keys will come after unordered.
Multiple tables with the same string key will take the value of the last table in argument order.
]]
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


--@static
--@param        dest        | table     | The original table to append to.
--@param        src         | table     | The table to append.
--[[
Appends keys from `src` to `dest`.
Existing keys will be overwritten.
]]
Util.table_append = function(dest, src)
    for k, v in pairs(src) do
        dest[k] = v
    end
end


--@static
--@param        dest        | table     | The original table to append to.
--@param        src         | table     | The table to append.
--[[
Inserts a table of values (`src`) to `dest`.
Both should be numerically-indexed tables.
]]
Util.table_insert = function(dest, src)
    for _, v in ipairs(src) do
        table.insert(dest, v)
    end
end


--@static
--@return       string
--@param        table       | table     | The table to encode.
--[[
Returns a string encoding of a *numerically-indexed* table.
The table should contain only basic Lua types (`bool`, `number`, `string`, `table`, `nil`).
]]
Util.table_to_string = function(table_)
    local str = ""
    for i = 1, #table_ do
        local v = table_[i]
        if type(v) == "table" then str = str.."[[||"..Util.table_to_string(v).."||]]||"
        else str = str..tostring(v).."||"
        end
    end
    return string.sub(str, 1, -3)
end


--@static
--@return       table
--@param        string      | string     | The string to decode.
--[[
Returns the table from a @link {string encoding | Util#table_to_string}.
]]
Util.string_to_table = function(string_)
    local raw = gm.string_split(string_, "||")
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


--@static
--@return       table
--@param        table       | table     | 
--@param        metatable   | table     | The metatable to assign to the table.
--[[
A version of `setmetatable()` that allows for Lua 5.2's `__gc` metamethod.
]]
Util.setmetatable_gc = function(t, mt)
    -- `setmetatable` but with `__gc` metamethod enabled
    if mt.__gc then
        local cproxy = newproxy(true)
        getmetatable(cproxy).__gc = function(self) mt.__gc(t) end
        t[cproxy] = true    -- This will show up in keys
                            -- You can mostly get around this by overriding
                            -- __pairs and __ipairs though, which Array and
                            -- Struct already does for iteration
    end
    return setmetatable(t, mt)
end

-- This method doesn't seem to work correctly:
-- Util.setmetatable_gc = function(t, mt)
--     -- `setmetatable` but with `__gc` metamethod enabled
--     if mt.__gc then
--         local cproxy = newproxy(true)
--         __gc_proxies[t] = cproxy
--         __gc_proxies_2[cproxy] = t
--         print("make __gc", cproxy, __gc_proxies_2[cproxy])
--         getmetatable(cproxy).__gc = function(self)
--             print("__gc", self, __gc_proxies_2[self])
--             mt.__gc(__gc_proxies_2[self])   -- Cannot reference `t` directly since
--                                             -- closures count as strong references
--         end
--     end
--     return setmetatable(t, mt)
-- end


--@static
--@return       number
--@param        stack_count | number    | The stack count.
--@param        chance      | number    | The proc chance/scaling/etc. *per stack*, between `0` and `1`.
--@optional     base_chance | number    | A base value (between `0` and `1`), should the additional <br>stack value be different from the first stack.
--[[
Returns the % chance (between `0` and `1`) of the stack count using a variant of hyperbolic scaling.
The first stack will always equal the stack %, and not slightly under (as is with the normal hyperbolic formula used).
]]
Util.mixed_hyperbolic = function(stack_count, chance, base_chance)
    -- Allows for calculating hyperbolic scaling with a different 1st-stack chance
    -- Also makes the 1st-stack equal the provided chance instead of being slightly under
    --      E.g., Tougher Times 1st-stack in RoR2 gives around 13% block chance (not 15%)
    local base_chance = base_chance or chance
    local diff = base_chance - chance
    local stacks_chance = chance * stack_count
    return math.max(stacks_chance / (stacks_chance + 1), chance) + diff
end


--@static
--@param        n       | number    | The number of calls to make.
--@param        fn      | function  | The function to call.
--@optional     ...     |           | A variable number of arguments to pass.
--[[
Benchmarks a function and prints the results (in milliseconds, up to 7 decimal places).
The amount of milliseconds per frame is 16.66~ ms.

"Leeway" here is a measure of how many times the function can be called
per frame *in a vacuum* before stuttering starts to occur.
]]
Util.benchmark = function(n, fn, ...)
    -- Adapted from here:
    -- https://docs.otland.net/lua-guide/auxiliary/benchmarking
    local unit = 'milliseconds'
    local multiplier = 1000
    local decPlaces = 7
    local elapsed = 0
    for i = 1, n do
        local now = os.clock()
        fn(...)
        elapsed = elapsed + (os.clock() - now)
    end
    print(string.format('\n  Benchmark results:\n  - %d function calls\n  - %.'..decPlaces..'f %s elapsed\n  - %.'..decPlaces..'f %s avg execution time.\n  - Leeway: '..(16.667 / ((elapsed / n) * multiplier)), n, elapsed * multiplier, unit, (elapsed / n) * multiplier, unit))
end


--@static
--@return       strings
--@param        str         | string    | The string to pad.
--@param        length      | number    | The desired string length.
--@optional     char        | string    | The character to use. <br>`" "` (space) by default.
--[[
Returns a string with character padding on the
left side to match the desired string length.
]]
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
--@return       strings
--@param        str         | string    | The string to pad.
--@param        length      | number    | The desired string length.
--@optional     char        | string    | The character to use. <br>`" "` (space) by default.
--[[
Returns a string with character padding on the
right side to match the desired string length.
]]
Util.pad_string_right = function(str, length, char)
    str = tostring(str)
    char = char or " "
    local len = length - #str
    for i = 1, len do
        str = str..char
    end
    return str
end


--@static
--@return       strings
--@param        fn          | function or table  | A function or table of functions.
--[[
Returns back the function (or table of functions) with JIT compilation disabled.
Use in tandem with ImGui callbacks.
]]
Util.jit_off = function(fn)
    if type(fn) == "table" then
        for _, f in ipairs(fn) do jit.off(f) end
    else jit.off(fn)
    end
    return fn
end



-- Public export
__class.Util = Util