return function()
    -- new
    local a = Array.new({1, 2, 3})
    Tests.assert(#a, 3)
    Tests.assert(a[1], 1)
    Tests.assert(a[3], 3)

    local b = Array.new(3, 5)
    Tests.assert(#b, 3)
    Tests.assert(b[1], 5)

    -- get / set
    a:set(0, 10)
    Tests.assert(a:get(0), 10)
    Tests.assert(a:get(100), nil)

    -- push / pop
    a:push(4, 5)
    Tests.assert(#a, 5)
    Tests.assert(a[5], 5)

    local v = a:pop()
    Tests.assert(v, 5)
    Tests.assert(#a, 4)

    -- insert
    a:insert(1, 99)
    Tests.assert(a[2], 99)

    -- delete
    a:delete(1)
    Tests.assert(a[2] ~= 99, true)

    -- delete_value
    a:push(42)
    a:delete_value(42)
    Tests.assert(a:contains(42), false)

    -- contains / find
    Tests.assert(a:contains(10), true)
    Tests.assert(a:find(10), 0)
    Tests.assert(a:find(999), nil)

    -- resize
    a:resize(2)
    Tests.assert(#a, 2)

    -- clear
    a:clear()
    Tests.assert(#a, 0)

    -- sort
    local s = Array.new({3, 1, 2})
    s:sort()
    Tests.assert(s[1], 1)
    Tests.assert(s[3], 3)

    s:sort(true)
    Tests.assert(s[1], 3)

    -- pairs / ipairs
    local sum = 0
    for _, v in ipairs(Array.new({1,2,3})) do
        sum = sum + v
    end
    Tests.assert(sum, 6)
end