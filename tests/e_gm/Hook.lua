return function()
    -- Post-hook
    local counter = 0
    local arg_n

    local post_hook = Hook.add_post(RAPI_NAMESPACE, gm.constants.function_dummy, function(self, other, result, args)
        counter = counter + 1
        arg_n = 0
        for i = 1, #args do
            arg_n = arg_n + 1
        end

        Tests.assert(args[3].value, "wow")

        result.value = 789
    end)

    Tests.assert(post_hook.RAPI, "Hook")
    Tests.assert(post_hook:is_enabled(), true)

    Tests.pause(function() Tests.resume() end)  -- Pause for 1 frame

    local result = gm.function_dummy(123, 456, "wow")
    Tests.assert(counter, 1)
    Tests.assert(arg_n, 3)
    Tests.assert(result, 789)

    post_hook:toggle(false)
    Tests.assert(post_hook:is_enabled(), false)
    gm.function_dummy(123, 456, "wow")
    Tests.assert(counter, 1)
    post_hook:toggle(true)

    local post_hook_2 = Hook.add_post(RAPI_NAMESPACE, gm.constants.function_dummy, function(self, other, result, args)
        Tests.assert(result.value, 789)
    end)
    gm.function_dummy(123, 456, "wow")
    post_hook_2:remove()

    local id = P.proxy[post_hook]
    local enabled_count = P.hook_id_to_table[id].enabled_count
    local out = post_hook:remove()
    Tests.assert(type(out), "function")
    Tests.assert(P.hook_id_to_table[id].enabled_count, enabled_count - 1)


    -- Pre-hook
    local counter = 0
    local arg_n

    local pre_hook = Hook.add_pre(RAPI_NAMESPACE, gm.constants.function_dummy, function(self, other, result, args)
        counter = counter + 1
        arg_n = 0
        for i = 1, #args do
            arg_n = arg_n + 1
        end

        Tests.assert(args[3].value, "wow")
        
        args[1].value = 1000
    end)

    Tests.assert(pre_hook.RAPI, "Hook")
    Tests.assert(pre_hook:is_enabled(), true)

    Tests.pause(function() Tests.resume() end)  -- Pause for 1 frame

    local result = gm.function_dummy(123, 456, "wow")
    Tests.assert(counter, 1)
    Tests.assert(arg_n, 3)

    pre_hook:toggle(false)
    Tests.assert(pre_hook:is_enabled(), false)
    gm.function_dummy(123, 456, "wow")
    Tests.assert(counter, 1)
    pre_hook:toggle(true)

    local post_hook = Hook.add_post(RAPI_NAMESPACE, gm.constants.function_dummy, function(self, other, result, args)
        Tests.assert(args[1].value, 1000)
    end)
    gm.function_dummy(123, 456, "wow")
    post_hook:remove()

    local id = P.proxy[pre_hook]
    local enabled_count = P.hook_id_to_table[id].enabled_count
    local out = pre_hook:remove()
    Tests.assert(type(out), "function")
    Tests.assert(P.hook_id_to_table[id].enabled_count, enabled_count - 1)

    local pre = Hook.add_pre(RAPI_NAMESPACE, gm.constants.instance_create, function(self, other, result, args)
        return false
    end)
    Tests.pause(function() Tests.resume() end)

    local n = gm.instance_number(gm.constants.oLizard)
    gm.instance_create(100, 100, gm.constants.oLizard)
    Tests.assert(gm.instance_number(gm.constants.oLizard), n)
    pre:remove()
end