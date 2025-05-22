-- Utility

Util = new_class()



-- ========== Static Methods ==========

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
--@return       function or table
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