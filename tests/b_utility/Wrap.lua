return function()
    -- unwrap
    Tests.assert(Wrap.unwrap("abc"), "abc")

    local t = {}
    Tests.assert(Wrap.unwrap(t), t)

    local p = new_proxy(123)
    Tests.assert(Wrap.unwrap(p), 123)
end