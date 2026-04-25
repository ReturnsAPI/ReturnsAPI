return function()
    -- Single use; must run before (2)

    G.tests.counter = 0
    G.tests.arg_n = 0

    local post_hook = Hook.add_post(RAPI_NAMESPACE, gm.constants.function_dummy, function(self, other, result, args)
        G.tests.counter = G.tests.counter + 1
        G.tests.arg_n = 0
        for i = 1, #args do
            G.tests.arg_n = G.tests.arg_n + 1
        end
        Tests.assert(args[3].value == "wow", "`args[3].value` is "..tostring(args[3].value))
    end)
    G.tests.post_hook = post_hook

    Tests.assert(post_hook.RAPI == "Hook", "`post_hook.RAPI` is "..tostring(post_hook.RAPI))

    local enabled = post_hook:is_enabled()
    Tests.assert(enabled == true, "`post_hook:is_enabled()` is "..tostring(enabled))
end