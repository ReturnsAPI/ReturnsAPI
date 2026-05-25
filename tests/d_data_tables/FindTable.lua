return function()
    local ft = FindTable.new()

    -- set + get (same namespace)
    ft:set(123, "id1", "A")
    local value = ft:get("id1", "A", true)
    Tests.assert(value, 123)

    -- get (wrong namespace, specified)
    Tests.assert(ft:get("id1", "B", true), nil)

    -- get (global search)
    local global = ft:get("id1", nil, false)
    Tests.assert(value, 123)

    -- multiple namespaces
    ft:set(456, "id1", "B")
    local valA = ft:get("id1", "A", true)
    local valB = ft:get("id1", "B", true)

    Tests.assert(valA, 123)
    Tests.assert(valB, 456)

    -- get_all (specific namespace)
    local listA = ft:get_all("A", true)
    Tests.assert(#listA, 1)
    Tests.assert(listA[1], 123)

    -- get_all (global)
    local listAll = ft:get_all(nil, false)
    Tests.assert(#listAll, 2)

    -- map (modify values)
    ft:map(function(value)
        return value * 2
    end)
    Tests.assert(ft:get("id1", "A", true), 246)
    Tests.assert(ft:get("id1", "B", true), 912)

    -- map (return nil should not overwrite)
    ft:map(function(data)
        return nil
    end)

    Tests.assert(ft:get("id1", "A", true), 246)

    -- overwrite existing identifier
    ft:set(999, "id1", "A")
    Tests.assert(ft:get("id1", "A", true), 999)

    -- missing identifier
    Tests.assert(ft:get("does_not_exist", "A", true), nil)

    -- empty namespace behavior
    local empty = ft:get_all("Z", true)
    Tests.assert(#empty, 0)

    -- set/get by id
    local id = 1000
    ft:set(123, "foo", "bar", id)
    Tests.assert(ft[id].value, 123)
end