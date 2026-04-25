return function()
    -- new
    local m = Map.new({ a = 1, b = 2 })
    Tests.assert(m.a, 1)
    Tests.assert(m.b, 2)

    -- set / get
    m:set("c", 3)
    Tests.assert(m:get("c"), 3)
    Tests.assert(m.c, 3)

    -- overwrite
    m:set("a", 10)
    Tests.assert(m.a, 10)

    -- size
    Tests.assert(#m, 3)

    -- delete
    m:delete("b")
    Tests.assert(m.b, nil)

    -- clear
    m:clear()
    Tests.assert(#m, 0)

    -- exists / destroy
    local m2 = Map.new()
    Tests.assert(m2:exists(), true)
    m2:destroy()
    Tests.assert(m2:exists(), false)

    -- iteration
    local m3 = Map.new({ x = 1, y = 2 })
    local count = 0
    for k, v in pairs(m3) do
        if k and v then count = count + 1 end
    end
    Tests.assert(count, 2)
end