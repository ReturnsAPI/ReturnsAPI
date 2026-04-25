return function()
    -- Single use; must run after (1)

    G.tests.counter = 0

    gm.function_dummy(123, 456, "wow")
    Tests.assert(G.tests.counter == 1, "`counter` is "..tostring(G.tests.counter))
    Tests.assert(G.tests.arg_n == 3, "`arg_n` is "..tostring(G.tests.arg_n))

    G.tests.post_hook:toggle(false)
    local enabled = G.tests.post_hook:is_enabled()
    Tests.assert(enabled == false, "`post_hook:is_enabled()` is "..tostring(enabled))

    gm.function_dummy()
    Tests.assert(G.tests.counter == 1, "`counter` is "..tostring(G.tests.counter))

    local out = G.tests.post_hook:remove()
    Tests.assert(type(out) == "function", "`out` is "..tostring(type(out)))
end