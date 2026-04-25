return function()
    -- new
    local l = List.new({1, 2, 3})
    Tests.assert(#l, 3)
    Tests.assert(l[1], 1)

    -- add
    l:add(4, 5)
    Tests.assert(#l, 5)
    Tests.assert(l[5], 5)

    -- get / set
    l:set(0, 10)
    Tests.assert(l:get(0), 10)
    Tests.assert(l:get(100), nil)

    -- insert
    l:insert(1, 99)
    Tests.assert(l[2], 99)

    -- delete
    l:delete(1)
    Tests.assert(l[2] ~= 99, true)

    -- delete_value
    l:add(42)
    l:delete_value(42)
    Tests.assert(l:contains(42), false)

    -- contains / find
    Tests.assert(l:contains(10), true)
    Tests.assert(l:find(10), 0)
    Tests.assert(l:find(999), nil)

    -- clear
    l:clear()
    Tests.assert(#l, 0)

    -- exists / destroy
    local l2 = List.new()
    Tests.assert(l2:exists(), true)
    l2:destroy()
    Tests.assert(l2:exists(), false)

    -- sort
    local s = List.new({3,1,2})
    s:sort()
    Tests.assert(s[1], 1)
    Tests.assert(s[3], 3)

    s:sort(true)
    Tests.assert(s[1], 3)

    -- iteration
    local sum = 0
    for _, v in ipairs(List.new({1,2,3})) do
        sum = sum + v
    end
    Tests.assert(sum, 6)
end