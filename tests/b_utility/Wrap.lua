return function()
    -- unwrap
    Tests.assert(Wrap.unwrap("abc"), "abc")

    local t = {}
    Tests.assert(Wrap.unwrap(t), t)

    local p = new_proxy(123)
    Tests.assert(Wrap.unwrap(p), 123)

    -- wrap
    local arr = gm.array_create(0, 0)
    local wrap = Wrap.wrap(arr)
    Tests.assert(getmetatable(wrap.value).__name, "sol.RefDynamicArrayOfRValueLuaWrapper")
    Tests.assert(wrap.RAPI, "Array")
    Tests.assert(getmetatable(wrap), mt_wrapper_name("Array"))
end