return function()
    local ct = CallbackTable.new()

    -- add
    local id1 = ct:add(function() return 1 end, "A", 0)
    local id2 = ct:add(function() return 2 end, "A", 1)
    local id3 = ct:add(function() return 3 end, "B", 0)

    Tests.assert(type(id1), "number")
    Tests.assert(type(id2), "number")
    Tests.assert(type(id3), "number")

    -- enabled_count
    Tests.assert(ct.enabled_count, 3)

    -- id_lookup
    Tests.assert(ct.id_lookup[id1] ~= nil, true)
    Tests.assert(ct.id_lookup[id2] ~= nil, true)
    Tests.assert(ct.id_lookup[id3] ~= nil, true)

    -- toggle (disable)
    ct:toggle(id1, false)
    Tests.assert(ct.id_lookup[id1].enabled, false)
    Tests.assert(ct.enabled_count, 2)

    -- toggle (enable)
    ct:toggle(id1, true)
    Tests.assert(ct.id_lookup[id1].enabled, true)
    Tests.assert(ct.enabled_count, 3)

    -- remove
    local fn = ct:remove(id2)
    Tests.assert(type(fn), "function")
    Tests.assert(ct.id_lookup[id2], nil)
    Tests.assert(ct.enabled_count, 2)

    -- remove (non-existent)
    Tests.assert(ct:remove(9999), nil)

    -- priority_count
    Tests.assert(ct.priority_count[0] >= 1, true)

    -- remove_all
    local removed = ct:remove_all("A")
    Tests.assert(removed >= 1, true)

    -- after remove_all
    for _, data in ipairs(ct) do
        Tests.assert(data.namespace ~= "A", true)
    end

    -- next_id increments properly
    local id4 = ct:add(function() end, "C")
    Tests.assert(id4 > id3, true)

    -- shared counter
    local counter = {value = 0}
    local ct1 = CallbackTable.new(counter)
    local ct2 = CallbackTable.new(counter)

    local a = ct1:add(function() end, "X")
    local b = ct2:add(function() end, "Y")

    Tests.assert(b, a + 1)
end