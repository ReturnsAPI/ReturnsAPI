return function()
    -- find
    local t = { a = 1, b = 2, c = 3 }
    Tests.assert(Table.find(t, 2), "b")
    Tests.assert(Table.find(t, 4), nil)

    local arr = { 10, 20, 30 }
    Tests.assert(Table.find(arr, 20), 2)

    -- remove_value
    local t2 = { 1, 2, 3, 2 }
    Table.remove_value(t2, 2)
    Tests.assert(#t2, 3)
    Tests.assert(t2[1], 1)
    Tests.assert(t2[2], 3)
    Tests.assert(t2[3], 2)

    local t3 = { 1, 2, 3 }
    Table.remove_value(t3, 5)
    Tests.assert(#t3, 3)

    -- shallow_copy
    local src = { a = 1, b = { 2 } }
    local copy = Table.shallow_copy(src)

    Tests.assert(copy.a, 1)
    Tests.assert(copy.b, src.b) -- shallow reference

    copy.a = 5
    Tests.assert(src.a, 1)

    -- merge
    local m = { a = 1 }
    Table.merge(m, { b = 2 }, { a = 3 })
    Tests.assert(m.a, 3)
    Tests.assert(m.b, 2)

    -- merge_new
    local m2 = Table.merge_new({ a = 1 }, { b = 2 }, { a = 5 })
    Tests.assert(m2.a, 5)
    Tests.assert(m2.b, 2)

    -- append
    local a1 = { 1, 2 }
    Table.append(a1, { 3, 4 }, { 5 })
    Tests.assert(#a1, 5)
    Tests.assert(a1[3], 3)
    Tests.assert(a1[5], 5)

    -- append_new
    local a2 = Table.append_new({ 1, 2 }, { 3 }, { 4, 5 })
    Tests.assert(#a2, 5)
    Tests.assert(a2[1], 1)
    Tests.assert(a2[5], 5)

    -- set
    local s = Table.set({ "a", "b", "c" })
    Tests.assert(s.a, true)
    Tests.assert(s.b, true)
    Tests.assert(s.c, true)
    Tests.assert(s.d, nil)

    -- enum
    local e1 = Table.enum({ "a", "b", "c" })
    Tests.assert(e1.a, 1)
    Tests.assert(e1.b, 2)
    Tests.assert(e1.c, 3)

    local e2 = Table.enum({ "x", "y", "z" }, 0, 2, 1)
    Tests.assert(e2.x, 0)
    Tests.assert(e2.y, 2)
    Tests.assert(e2.z, 4)

    local e3 = Table.enum({ "p", "q" }, 1, 1, 2)
    Tests.assert(e3.p, 1)
    Tests.assert(e3.q, 4)
end