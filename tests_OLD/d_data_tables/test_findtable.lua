return function()
    local ft = FindTable.new()

    -- ========== Initial State ==========

    Tests.assert(type(ft) == "table", "`ft` type is "..tostring(type(ft)))


    -- ========== Set & Get (Same Namespace) ==========

    ft:set(123, "id1", "A")

    local v = ft:get("id1", "A", true)
    Tests.assert(v ~= nil and v.value == 123,
        "`get(id1, A)` is "..tostring(v and v.value))

    Tests.assert(v.identifier == "id1",
        "`identifier` is "..tostring(v and v.identifier))
    Tests.assert(v.namespace == "A",
        "`namespace` is "..tostring(v and v.namespace))


    -- ========== Overwrite Value ==========

    ft:set(456, "id1", "A")

    local v2 = ft:get("id1", "A", true)
    Tests.assert(v2 ~= nil and v2.value == 456,
        "`overwrite value` is "..tostring(v2 and v2.value))


    -- ========== Multiple Namespaces ==========

    ft:set(111, "shared", "A")
    ft:set(222, "shared", "B")

    local va = ft:get("shared", "A", true)
    local vb = ft:get("shared", "B", true)

    Tests.assert(va.value == 111,
        "`shared in A` is "..tostring(va and va.value))
    Tests.assert(vb.value == 222,
        "`shared in B` is "..tostring(vb and vb.value))


    -- ========== Global Lookup (Namespace Not Specified) ==========

    local vg = ft:get("shared", "A", false)

    Tests.assert(vg ~= nil,
        "`global get(shared)` returned nil")

    Tests.assert(vg.value == 111 or vg.value == 222,
        "`global get(shared)` is "..tostring(vg and vg.value))


    -- ========== Missing Value ==========

    local missing = ft:get("does_not_exist", "A", true)
    Tests.assert(missing == nil,
        "`missing value` is "..tostring(missing))


    -- ========== get_all (Specific Namespace) ==========

    local allA = ft:get_all("A", true)

    local countA = 0
    for _, v in ipairs(allA) do
        if v.namespace == "A" then countA = countA + 1 end
    end

    Tests.assert(#allA == countA,
        "`get_all(A)` count mismatch: "..tostring(#allA))


    -- ========== get_all (Global) ==========

    local allGlobal = ft:get_all("A", false)

    local foundA, foundB = false, false
    for _, v in ipairs(allGlobal) do
        if v.namespace == "A" then foundA = true end
        if v.namespace == "B" then foundB = true end
    end

    Tests.assert(foundA == true,
        "`get_all global` missing namespace A")
    Tests.assert(foundB == true,
        "`get_all global` missing namespace B")


    -- ========== map ==========

    ft:map(function(data)
        data.value = data.value * 2
        return data
    end)

    local m1 = ft:get("id1", "A", true)
    Tests.assert(m1.value == 456 * 2,
        "`map result id1` is "..tostring(m1.value))

    local m2 = ft:get("shared", "B", true)
    Tests.assert(m2.value == 222 * 2,
        "`map result shared B` is "..tostring(m2.value))


    -- ========== map (return nil should not overwrite) ==========

    local before = ft:get("shared", "A", true)

    ft:map(function(data)
        if data.identifier == "shared" then
            return nil
        end
        return data
    end)

    local after = ft:get("shared", "A", true)

    Tests.assert(after == before,
        "`map nil overwrite` changed value unexpectedly")


    -- ========== Data Integrity ==========

    for ns, ns_table in pairs(ft) do
        for id, data in pairs(ns_table) do
            Tests.assert(data.identifier == id,
                "`identifier mismatch` expected "..tostring(id)..
                " got "..tostring(data.identifier))

            Tests.assert(data.namespace == ns,
                "`namespace mismatch` expected "..tostring(ns)..
                " got "..tostring(data.namespace))
        end
    end
end
