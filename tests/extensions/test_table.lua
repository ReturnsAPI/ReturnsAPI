return function()
    local a = {
        abc = 123,
    }
    local b = {
        abc = 456,
        def = 789,
    }

    Table.merge(a, b)
    Tests.assert(a.abc == 456, "`a.abc` is "..tostring(a.abc))
    Tests.assert(a.def == 789, "`a.def` is "..tostring(a.def))
end