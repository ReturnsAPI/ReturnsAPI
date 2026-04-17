return function()
    -- ===== Struct.new =====
    local s = Struct.new()
    Tests.assert(#s == 0, "`#Struct.new()` is "..tostring(#s))

    local s2 = Struct.new({ a = 1, b = 2 })
    Tests.assert(s2.a == 1, "`s2.a` is "..tostring(s2.a))
    Tests.assert(s2.b == 2, "`s2.b` is "..tostring(s2.b))

    -- ===== set / get =====
    s.x = 10
    s.y = 20

    Tests.assert(s.x == 10, "`s.x` is "..tostring(s.x))
    Tests.assert(s.y == 20, "`s.y` is "..tostring(s.y))

    -- ===== overwrite =====
    s.x = 99
    Tests.assert(s.x == 99, "`s.x after overwrite is "..tostring(s.x))

    -- ===== get_keys =====
    local keys = s:get_keys()
    local count = #keys
    Tests.assert(count == 2, "`#get_keys()` is "..tostring(count))

    -- ===== pairs =====
    local sum = 0
    local c = 0

    for k, v in pairs(s) do
        sum = sum + v
        c = c + 1
    end

    Tests.assert(c == 2, "`pairs count` is "..tostring(c))
    Tests.assert(sum == (99 + 20), "`pairs sum` is "..tostring(sum))

    -- ===== length =====
    Tests.assert(#s == 2, "`#s` is "..tostring(#s))

    -- ===== nested struct =====
    local nested = Struct.new({ inner = Struct.new({ v = 5 }) })
    Tests.assert(nested.inner.v == 5, "`nested.inner.v` is "..tostring(nested.inner.v))

    -- ===== clear via overwrite =====
    s = Struct.new()
    Tests.assert(#s == 0, "`#empty struct` is "..tostring(#s))

    -- TODO add test for script binding
end
