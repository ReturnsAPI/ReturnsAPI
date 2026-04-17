-- return function()
--     local a = {
--         abc = 123,
--     }
--     local b = {
--         abc = 456,
--         def = 789,
--     }

--     Table.merge(a, b)
--     Tests.assert(a.abc == 456, "`a.abc` is "..tostring(a.abc))
--     Tests.assert(a.def == 789, "`a.def` is "..tostring(a.def))
-- end

return function()
    if not Table then
        Tests.assert(false, "Table does not exist")
        return
    end

    -- ===== Table.find =====
    local t1 = { a = 1, b = 2, c = 3 }

    local r = Table.find(t1, 1)
    Tests.assert(r == "a", "`find(t1, 1)` is "..tostring(r))

    r = Table.find(t1, 2)
    Tests.assert(r == "b", "`find(t1, 2)` is "..tostring(r))

    r = Table.find(t1, 3)
    Tests.assert(r == "c", "`find(t1, 3)` is "..tostring(r))

    r = Table.find(t1, 4)
    Tests.assert(r == nil, "`find(t1, 4)` is "..tostring(r))

    -- duplicate values
    local t2 = { x = 5, y = 5 }
    r = Table.find(t2, 5)
    Tests.assert(r == "x" or r == "y", "`find(t2, 5)` is "..tostring(r))

    -- ===== Table.merge =====
    local t3 = { a = 1, b = 2 }
    Table.merge(t3, { b = 3, c = 4 })

    Tests.assert(t3.a == 1, "`merge` result a is "..tostring(t3.a))
    Tests.assert(t3.b == 3, "`merge` result b is "..tostring(t3.b))
    Tests.assert(t3.c == 4, "`merge` result c is "..tostring(t3.c))

    -- multiple tables
    local t4 = { a = 1 }
    Table.merge(t4, { b = 2 }, { c = 3 })

    Tests.assert(t4.b == 2, "`merge` result b is "..tostring(t4.b))
    Tests.assert(t4.c == 3, "`merge` result c is "..tostring(t4.c))

    -- ===== Table.combine =====
    local t5 = Table.combine({ a = 1 }, { b = 2 }, { a = 3 })

    Tests.assert(t5.a == 3, "`combine(...).a` is "..tostring(t5.a))
    Tests.assert(t5.b == 2, "`combine(...).b` is "..tostring(t5.b))

    -- ensure original tables unchanged
    local src1 = { a = 1 }
    local src2 = { b = 2 }
    local t6 = Table.combine(src1, src2)

    Tests.assert(src1.a == 1, "`combine` modified src1.a to "..tostring(src1.a))
    Tests.assert(src2.b == 2, "`combine` modified src2.b to "..tostring(src2.b))

    -- ===== Table.shallow_copy =====
    local t7 = { a = 1, b = 2 }
    local copy = Table.shallow_copy(t7)

    Tests.assert(copy.a == 1, "`shallow_copy(t7).a` is "..tostring(copy.a))
    Tests.assert(copy.b == 2, "`shallow_copy(t7).b` is "..tostring(copy.b))

    -- ensure different reference
    copy.a = 10
    Tests.assert(t7.a == 1, "`t7.a` after modifying copy is "..tostring(t7.a))

    -- shallow behavior
    local nested = { x = 1 }
    local t8 = { a = nested }
    local copy2 = Table.shallow_copy(t8)

    copy2.a.x = 5
    Tests.assert(t8.a.x == 5, "`nested value after shallow_copy is "..tostring(t8.a.x))

    -- empty table
    local t9 = {}
    local copy3 = Table.shallow_copy(t9)

    Tests.assert(next(copy3) == nil, "`shallow_copy(empty)` is not empty")
end