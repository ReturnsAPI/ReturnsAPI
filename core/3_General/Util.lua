-- Utility

Util = new_class()



-- ========== Static Methods ==========

Util.bool = function(value)
    if type(value) == "number" then return value > 0.5 end
    return value
end


Util.chance = function(n)
    return math.random() <= n
end


Util.ease_in = function(x, n)
    return x^(n or 2)
end


Util.ease_out = function(x, n)
    return 1 - (1 - x)^(n or 2)
end


Util.table_has = function(t, value)
    for k, v in pairs(t) do
        if v == value then return true end
    end
    return false
end


Util.table_find = function(t, value)
    for k, v in pairs(t) do
        if v == value then return k end
    end
    return nil
end


Util.table_remove_value = function(t, value)
    for k, v in pairs(t) do
        if v == value then
            t[k] = nil
            return
        end
    end
end


Util.table_get_keys = function(t)
    local keys = {}
    for k, v in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end


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


Util.allow_gc_metamethod = function(table_)
    -- Allow `table_` to call its `__gc` metamethod on being garbage collected
    local prox = newproxy(true)
    getmetatable(prox).__gc = function() getmetatable(table_).__gc(table) end
    table_[prox] = true
end


Util.setmetatable_gc = function(t, mt)
    -- `setmetatable` but with `__gc` metamethod enabled
    local prox = newproxy(true)
    getmetatable(prox).__gc = function() mt.__gc(t) end
    t[prox] = true
    return setmetatable(t, mt)
end


Util.mixed_hyperbolic = function(stack_count, chance, base_chance)
    -- Allows for calculating hyperbolic scaling with a different 1st-stack chance
    -- Also makes the 1st-stack equal the provided chance instead of being slightly under
    --      E.g., Tougher Times 1st-stack in RoR2 gives around 13% block chance (not 15%)
    local base_chance = base_chance or chance
    local diff = base_chance - chance
    local stacks_chance = chance * stack_count
    return math.max(stacks_chance / (stacks_chance + 1), chance) + diff
end


--$static
--$param        n       | number    | The number of calls to make.
--$param        fn      | function  | The function to call.
--$optional     ...     |           | A variable number of arguments to pass.
--[[
Benchmarks a function and prints the results (in milliseconds, up to 5 decimal places).
The amount of milliseconds per frame is 16.66~ ms.
]]
Util.benchmark = function(n, fn, ...)
    -- Adapted from here:
    -- https://docs.otland.net/lua-guide/auxiliary/benchmarking
    local unit = 'milliseconds'
    local multiplier = 1000
    local decPlaces = 5
    local elapsed = 0
    for i = 1, n do
        local now = os.clock()
        fn(...)
        elapsed = elapsed + (os.clock() - now)
    end
    print(string.format('\n  Benchmark results:\n  - %d function calls\n  - %.'..decPlaces..'f %s elapsed\n  - %.'..decPlaces..'f %s avg execution time.\n  - Leeway: '..(16.667 / ((elapsed / n) * multiplier)), n, elapsed * multiplier, unit, (elapsed / n) * multiplier, unit))
end



_CLASS["Util"] = Util