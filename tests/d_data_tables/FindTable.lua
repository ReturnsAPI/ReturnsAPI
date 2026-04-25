return function()
    local ft = FindTable.new()

    -- set + get (same namespace)
    ft:set(123, "id1", "A")
    local data = ft:get("id1", "A", true)

    Tests.assert(type(data), "table")
    Tests.assert(data.value, 123)
    Tests.assert(data.identifier, "id1")
    Tests.assert(data.namespace, "A")

    -- get (wrong namespace, specified)
    Tests.assert(ft:get("id1", "B", true), nil)

    -- get (global search)
    local global = ft:get("id1", "B", false)
    Tests.assert(global.value, 123)

    -- multiple namespaces
    ft:set(456, "id1", "B")
    local valA = ft:get("id1", "A", true)
    local valB = ft:get("id1", "B", true)

    Tests.assert(valA.value, 123)
    Tests.assert(valB.value, 456)

    -- get_all (specific namespace)
    local listA = ft:get_all("A", true)
    Tests.assert(#listA, 1)
    Tests.assert(listA[1].value, 123)

    -- get_all (global)
    local listAll = ft:get_all("A", false)
    Tests.assert(#listAll >= 2, true)

    -- map (modify values)
    ft:map(function(data)
        data.value = data.value * 2
        return data
    end)

    Tests.assert(ft:get("id1", "A", true).value, 246)
    Tests.assert(ft:get("id1", "B", true).value, 912)

    -- map (return nil should not overwrite)
    ft:map(function(data)
        return nil
    end)

    Tests.assert(ft:get("id1", "A", true).value, 246)

    -- overwrite existing identifier
    ft:set(999, "id1", "A")
    Tests.assert(ft:get("id1", "A", true).value, 999)

    -- missing identifier
    Tests.assert(ft:get("does_not_exist", "A", true), nil)

    -- empty namespace behavior
    local empty = ft:get_all("Z", true)
    Tests.assert(#empty, 0)
end