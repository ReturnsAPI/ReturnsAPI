return function()
    -- ===== List.new / size =====
    local list = List.new()
    Tests.assert(list:size() == 0, "`List.new():size()` is "..tostring(list:size()))

    local list2 = List.new({1, 2, 3})
    Tests.assert(list2:size() == 3, "`List.new({1,2,3}):size()` is "..tostring(list2:size()))

    -- ===== add =====
    list:add(10, 20, 30)
    Tests.assert(list:size() == 3, "`size()` after add is "..tostring(list:size()))
    Tests.assert(list:get(0) == 10, "`get(0)` is "..tostring(list:get(0)))
    Tests.assert(list:get(1) == 20, "`get(1)` is "..tostring(list:get(1)))
    Tests.assert(list:get(2) == 30, "`get(2)` is "..tostring(list:get(2)))

    -- ===== get / set =====
    list:set(1, 99)
    Tests.assert(list:get(1) == 99, "`get(1)` after set is "..tostring(list:get(1)))

    Tests.assert(list:get(3) == nil, "`get(3)` is "..tostring(list:get(3)))
    Tests.assert(list:get(-1) == nil, "`get(-1)` is "..tostring(list:get(-1)))

    -- ===== insert =====
    list:insert(1, 50)
    Tests.assert(list:get(1) == 50, "`get(1)` after insert is "..tostring(list:get(1)))
    Tests.assert(list:size() == 4, "`size()` after insert is "..tostring(list:size()))

    -- ===== delete =====
    list:delete(1)
    Tests.assert(list:get(1) == 99, "`get(1)` after delete is "..tostring(list:get(1)))
    Tests.assert(list:size() == 3, "`size()` after delete is "..tostring(list:size()))

    -- ===== delete_value =====
    list:delete_value(99)
    local idx = list:find(99)
    Tests.assert(idx == nil, "`find(99)` after delete_value is "..tostring(idx))

    -- ===== clear =====
    list:clear()
    Tests.assert(list:size() == 0, "`size()` after clear is "..tostring(list:size()))

    -- ===== contains =====
    local list3 = List.new({1, 2, 3})

    local c = list3:contains(2)
    Tests.assert(c == true, "`contains(2)` is "..tostring(c))

    c = list3:contains(5)
    Tests.assert(c == false, "`contains(5)` is "..tostring(c))

    -- ===== find =====
    local f = list3:find(1)
    Tests.assert(f == 0, "`find(1)` is "..tostring(f))

    f = list3:find(3)
    Tests.assert(f == 2, "`find(3)` is "..tostring(f))

    f = list3:find(10)
    Tests.assert(f == nil, "`find(10)` is "..tostring(f))

    -- ===== sort =====
    local list4 = List.new({3, 1, 2})

    list4:sort(false)
    Tests.assert(list4:get(0) == 1, "`sort asc get(0)` is "..tostring(list4:get(0)))
    Tests.assert(list4:get(1) == 2, "`sort asc get(1)` is "..tostring(list4:get(1)))
    Tests.assert(list4:get(2) == 3, "`sort asc get(2)` is "..tostring(list4:get(2)))

    list4:sort(true)
    Tests.assert(list4:get(0) == 3, "`sort desc get(0)` is "..tostring(list4:get(0)))
    Tests.assert(list4:get(1) == 2, "`sort desc get(1)` is "..tostring(list4:get(1)))
    Tests.assert(list4:get(2) == 1, "`sort desc get(2)` is "..tostring(list4:get(2)))

    -- ===== metamethods =====
    local list5 = List.new({10, 20, 30})

    Tests.assert(#list5 == 3, "`#list5` is "..tostring(#list5))

    Tests.assert(list5[1] == 10, "`list5[1]` is "..tostring(list5[1]))
    Tests.assert(list5[2] == 20, "`list5[2]` is "..tostring(list5[2]))
    Tests.assert(list5[3] == 30, "`list5[3]` is "..tostring(list5[3]))

    list5[2] = 99
    Tests.assert(list5:get(1) == 99, "`set via [] failed, get(1)` is "..tostring(list5:get(1)))

    -- ipairs
    local sum = 0
    for _, v in ipairs(list5) do
        sum = sum + v
    end
    Tests.assert(sum == (10 + 99 + 30), "`ipairs sum` is "..tostring(sum))

    -- pairs
    local count = 0
    for _, _ in pairs(list5) do
        count = count + 1
    end
    Tests.assert(count == 3, "`pairs count` is "..tostring(count))

    -- ===== exists / destroy =====
    local list6 = List.new()
    local e = list6:exists()
    Tests.assert(e == true, "`exists()` before destroy is "..tostring(e))

    list6:destroy()
    e = list6:exists()
    Tests.assert(e == false, "`exists()` after destroy is "..tostring(e))
end
