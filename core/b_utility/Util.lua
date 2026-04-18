-- Util

---@class Util
Util = new_class()
C.Util = Util


-- ========== Static Methods ==========

--[[
Converts a numerical value into a bool,
returning `true` if > 0.5, and `false` otherwise.

Other cases:
Non-numerical, non-bool values will return `true`.
`nil` will return `false`.

Works just like [`GM.bool`](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Variable_Functions/bool.htm).
]]
---@param value any The value to convert.
---@return bool
Util.bool = function(value)
    if type(value) == "number" then return value > 0.5 end
    return (value and true) or false
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
(The actual value in practice will be much lower when accounting for the rest of the game.)
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