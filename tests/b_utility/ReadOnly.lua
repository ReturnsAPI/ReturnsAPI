return function()
    local t = {
        abc = 123,
    }
    local r = ReadOnly.new(t)

    local mtname = getmetatable(r)
    Tests.assert(mtname, mt_wrapper_name("ReadOnly"))

    Tests.assert(r.abc, 123)
    Tests.assert(r.def, nil)

    ---@type boolean, string
    local status, err = pcall(function() r.abc = 123 end)
    pcall(function() r.def = 456 end)
    Tests.assert(r.abc, 123)
    Tests.assert(r.def, nil)
    Tests.assert(err:find("Table is read") ~= nil, true)
end