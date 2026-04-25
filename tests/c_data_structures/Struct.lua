return function()
    -- new (empty)
    local s = Struct.new()
    Tests.assert(type(s), "table")

    -- set / get
    s.a = 1
    s.b = 2
    Tests.assert(s.a, 1)
    Tests.assert(s.b, 2)

    -- overwrite
    s.a = 10
    Tests.assert(s.a, 10)

    -- new from table
    local s2 = Struct.new({ x = 5, y = 6 })
    Tests.assert(s2.x, 5)
    Tests.assert(s2.y, 6)

    -- get_keys
    local keys = s2:get_keys()
    Tests.assert(type(keys), "table")
    Tests.assert(#keys >= 2, true)

    -- length
    Tests.assert(#s2 >= 2, true)

    -- iteration
    local count = 0
    for k, v in pairs(s2) do
        if k and v then count = count + 1 end
    end
    Tests.assert(count >= 2, true)
end