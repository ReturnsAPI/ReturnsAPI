return function()
    local ct = CallbackTable.new()

    -- ========== Initial State ==========

    Tests.assert(ct.enabled_count == 0, "`enabled_count` is "..tostring(ct.enabled_count))
    Tests.assert(ct.next_id.value == 0, "`next_id.value` is "..tostring(ct.next_id.value))
    Tests.assert(#ct == 0, "`#ct` is "..tostring(#ct))


    -- ========== Add ==========

    local f1 = function() return 1 end
    local f2 = function() return 2 end
    local f3 = function() return 3 end

    local id1 = ct:add(f1, "A", 0)
    local id2 = ct:add(f2, "A", 1)
    local id3 = ct:add(f3, "B", 0)

    Tests.assert(id1 == 0, "`id1` is "..tostring(id1))
    Tests.assert(id2 == 1, "`id2` is "..tostring(id2))
    Tests.assert(id3 == 2, "`id3` is "..tostring(id3))

    Tests.assert(ct.next_id.value == 3, "`next_id.value` is "..tostring(ct.next_id.value))
    Tests.assert(ct.enabled_count == 3, "`enabled_count` is "..tostring(ct.enabled_count))
    Tests.assert(#ct == 3, "`#ct` is "..tostring(#ct))


    -- ========== Priority Ordering ==========

    -- Priority 0 should come before priority 1
    Tests.assert(ct[1].fn == f1 or ct[1].fn == f3,
        "`ct[1].fn` is "..tostring(ct[1].fn))
    Tests.assert(ct[2].fn == f1 or ct[2].fn == f3,
        "`ct[2].fn` is "..tostring(ct[2].fn))
    Tests.assert(ct[3].fn == f2,
        "`ct[3].fn` is "..tostring(ct[3].fn))


    -- ========== Toggle ==========

    ct:toggle(id1, false)
    Tests.assert(ct.enabled_count == 2,
        "`enabled_count` after disable is "..tostring(ct.enabled_count))
    Tests.assert(ct.id_lookup[id1].enabled == false,
        "`enabled` is "..tostring(ct.id_lookup[id1].enabled))

    ct:toggle(id1, true)
    Tests.assert(ct.enabled_count == 3,
        "`enabled_count` after enable is "..tostring(ct.enabled_count))
    Tests.assert(ct.id_lookup[id1].enabled == true,
        "`enabled` is "..tostring(ct.id_lookup[id1].enabled))


    -- ========== Remove ==========

    local removed = ct:remove(id2)

    Tests.assert(removed == f2,
        "`removed` is "..tostring(removed))
    Tests.assert(ct.id_lookup[id2] == nil,
        "`id_lookup[id2]` is "..tostring(ct.id_lookup[id2]))
    Tests.assert(#ct == 2,
        "`#ct` after remove is "..tostring(#ct))
    Tests.assert(ct.enabled_count == 2,
        "`enabled_count` after remove is "..tostring(ct.enabled_count))


    -- ========== Remove Non-existent ==========

    local removed_nil = ct:remove(999)
    Tests.assert(removed_nil == nil,
        "`removed_nil` is "..tostring(removed_nil))


    -- ========== Remove All (Namespace) ==========

    ct:remove_all("A")

    local remaining = 0
    for i = 1, #ct do
        if ct[i].namespace == "A" then
            remaining = remaining + 1
        end
    end

    Tests.assert(remaining == 0,
        "`remaining A namespace count` is "..tostring(remaining))


    -- ========== Enabled Count Consistency ==========

    local enabled_count = 0
    for i = 1, #ct do
        if ct[i].enabled then
            enabled_count = enabled_count + 1
        end
    end

    Tests.assert(enabled_count == ct.enabled_count,
        "`enabled_count mismatch` actual="..tostring(enabled_count)..
        " stored="..tostring(ct.enabled_count))


    -- Test counter sharing
    local counter = {value = 0}
    local ct1 = CallbackTable.new(counter)
    local ct2 = CallbackTable.new(counter)
    ct1:add(function() end, "namespace")
    ct2:add(function() end, "namespace")
    Tests.assert(counter.value == 2, "`counter.value` is "..tostring(counter.value))
end