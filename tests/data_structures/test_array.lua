return function()
    -- ===== Array.new / size =====
    local arr = Array.new(3, 0)
    Tests.assert(arr:size() == 3, "`Array.new(3, 0):size()` is "..tostring(arr:size()))

    -- ===== get / set =====
    arr:set(0, 10)
    arr:set(1, 20)
    arr:set(2, 30)

    Tests.assert(arr:get(0) == 10, "`get(0)` is "..tostring(arr:get(0)))
    Tests.assert(arr:get(1) == 20, "`get(1)` is "..tostring(arr:get(1)))
    Tests.assert(arr:get(2) == 30, "`get(2)` is "..tostring(arr:get(2)))

    Tests.assert(arr:get(3) == nil, "`get(3)` is "..tostring(arr:get(3)))
    Tests.assert(arr:get(-1) == nil, "`get(-1)` is "..tostring(arr:get(-1)))

    -- ===== push =====
    arr:push(40, 50)
    Tests.assert(arr:size() == 5, "`size()` after push is "..tostring(arr:size()))
    Tests.assert(arr:get(3) == 40, "`get(3)` after push is "..tostring(arr:get(3)))
    Tests.assert(arr:get(4) == 50, "`get(4)` after push is "..tostring(arr:get(4)))

    -- ===== pop =====
    local v = arr:pop()
    Tests.assert(v == 50, "`pop()` returned "..tostring(v))
    Tests.assert(arr:size() == 4, "`size()` after pop is "..tostring(arr:size()))

    -- ===== insert =====
    arr:insert(1, 15)
    Tests.assert(arr:get(1) == 15, "`get(1)` after insert is "..tostring(arr:get(1)))
    Tests.assert(arr:size() == 5, "`size()` after insert is "..tostring(arr:size()))

    -- ===== delete =====
    arr:delete(1)
    Tests.assert(arr:get(1) == 20, "`get(1)` after delete is "..tostring(arr:get(1)))
    Tests.assert(arr:size() == 4, "`size()` after delete is "..tostring(arr:size()))

    -- ===== delete_value =====
    arr:delete_value(20)
    local found = arr:find(20)
    Tests.assert(found == nil, "`find(20)` after delete_value is "..tostring(found))

    -- ===== clear =====
    arr:clear()
    Tests.assert(arr:size() == 0, "`size()` after clear is "..tostring(arr:size()))

    -- ===== contains =====
    local arr2 = Array.new(0, 0)
    arr2:push(1, 2, 3)

    local c = arr2:contains(2)
    Tests.assert(c == true, "`contains(2)` is "..tostring(c))

    c = arr2:contains(5)
    Tests.assert(c == false, "`contains(5)` is "..tostring(c))

    -- ===== find =====
    local idx = arr2:find(1)
    Tests.assert(idx == 0, "`find(1)` is "..tostring(idx))

    idx = arr2:find(3)
    Tests.assert(idx == 2, "`find(3)` is "..tostring(idx))

    idx = arr2:find(10)
    Tests.assert(idx == nil, "`find(10)` is "..tostring(idx))

    -- ===== resize =====
    arr2:resize(5)
    Tests.assert(arr2:size() == 5, "`size()` after resize(5) is "..tostring(arr2:size()))

    arr2:resize(2)
    Tests.assert(arr2:size() == 2, "`size()` after resize(2) is "..tostring(arr2:size()))

    -- ===== sort =====
    local arr3 = Array.new(0, 0)
    arr3:push(3, 1, 2)

    arr3:sort(false)
    Tests.assert(arr3:get(0) == 1, "`sort asc get(0)` is "..tostring(arr3:get(0)))
    Tests.assert(arr3:get(1) == 2, "`sort asc get(1)` is "..tostring(arr3:get(1)))
    Tests.assert(arr3:get(2) == 3, "`sort asc get(2)` is "..tostring(arr3:get(2)))

    arr3:sort(true)
    Tests.assert(arr3:get(0) == 3, "`sort desc get(0)` is "..tostring(arr3:get(0)))
    Tests.assert(arr3:get(1) == 2, "`sort desc get(1)` is "..tostring(arr3:get(1)))
    Tests.assert(arr3:get(2) == 1, "`sort desc get(2)` is "..tostring(arr3:get(2)))

    -- ===== metamethods =====
    local arr4 = Array.new(0, 0)
    arr4:push(10, 20, 30)

    Tests.assert(#arr4 == 3, "`#arr4` is "..tostring(#arr4))

    Tests.assert(arr4[1] == 10, "`arr4[1]` is "..tostring(arr4[1]))
    Tests.assert(arr4[2] == 20, "`arr4[2]` is "..tostring(arr4[2]))
    Tests.assert(arr4[3] == 30, "`arr4[3]` is "..tostring(arr4[3]))

    arr4[2] = 99
    Tests.assert(arr4:get(1) == 99, "`set via [] failed, get(1)` is "..tostring(arr4:get(1)))

    -- ipairs
    local sum = 0
    for _, v in ipairs(arr4) do
        sum = sum + v
    end
    Tests.assert(sum == (10 + 99 + 30), "`ipairs sum` is "..tostring(sum))

    -- pairs
    local count = 0
    for _, _ in pairs(arr4) do
        count = count + 1
    end
    Tests.assert(count == 3, "`pairs count` is "..tostring(count))
end
