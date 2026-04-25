return function()
    local t = {
        abc = 123,
    }
    local p = new_proxy(t)

    local mtname = getmetatable(p)
    Tests.assert(mtname, mt_wrapper_name("Proxy"))

    Tests.assert(p.abc, 123)
    Tests.assert(p.def, nil)

    p.def = 456
    Tests.assert(p.def, 456)

    t.def = 789
    Tests.assert(p.def, 789)
end