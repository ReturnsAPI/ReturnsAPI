return function()
    if not Proxy then
        Tests.assert(false, "Proxy does not exist")
        return
    end

    local t = {
        abc = 123,
    }
    local p = Proxy.new(t)

    local mtname = getmetatable(p)
    Tests.assert(mtname == mt_wrapper_name("Proxy"), "`__metatable` is "..tostring(mtname))

    Tests.assert(p.abc == 123, "`p.abc` is "..tostring(p.abc))
    Tests.assert(p.def == nil, "`p.def` is "..tostring(p.def))

    p.def = 456
    Tests.assert(p.def == 456, "`p.def` is "..tostring(p.def))

    t.def = 789
    Tests.assert(p.def == 789, "`p.def` is "..tostring(p.def))
end