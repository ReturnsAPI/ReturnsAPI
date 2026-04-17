return function()
    if not ReadOnly then
        Tests.assert(false, "ReadOnly does not exist")
        return
    end

    local t = {
        abc = 123,
    }
    local r = ReadOnly.new(t)

    local mtname = getmetatable(r)
    Tests.assert(mtname == mt_wrapper_name("ReadOnly"), "`__metatable` is "..tostring(mtname))

    Tests.assert(r.abc == 123, "`r.abc` is "..tostring(r.abc))
    Tests.assert(r.def == nil, "`r.def` is "..tostring(r.def))

    ---@type boolean, string
    local status, err = pcall(function() r.abc = 123 end)
    pcall(function() r.def = 456 end)
    Tests.assert(r.abc == 123, "`r.abc` is "..tostring(r.abc))
    Tests.assert(r.def == nil, "`r.def` is "..tostring(r.def))
    Tests.assert(err:find("Table is read"), "`err` is '"..tostring(err).."'")
end