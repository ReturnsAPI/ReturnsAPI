-- Util

---@class Util
Util = new_class()
C.Util = Util

local type      = type
local os_clock  = os.clock


-- ========== Static Methods ==========

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
    if type(n)  ~= "number"   then log.error("benchmark: n is invalid", 2) end
    if type(fn) ~= "function" then log.error("benchmark: fn is invalid", 2) end

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