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

    Tests.pause_for(1)

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

    Tests.pause_for(1)

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
    Tests.pause_for(1)

    local n = gm.instance_number(gm.constants.oLizard)
    gm.instance_create(100, 100, gm.constants.oLizard)
    Tests.assert(gm.instance_number(gm.constants.oLizard), n)
    pre:remove()
    gm.instance_destroy(gm.constants.oLizard)


    -- Object event hooks
    local counter = 0

    local o1 = Hook.add_pre(RAPI_NAMESPACE, "gml_Object_oLizard_Create_0", function(self, other)
        Tests.assert(counter, 0)
        counter = 1
    end)
    local o2 = Hook.add_post(RAPI_NAMESPACE, "gml_Object_oLizard_Create_0", function(self, other)
        Tests.assert(counter, 1)
        counter = 2
    end)
    Tests.pause_for(1)

    gm.instance_create(100, 100, gm.constants.oLizard)
    Tests.assert(counter, 2)
    gm.instance_destroy(gm.constants.oLizard)

    local id = P.proxy[o1]
    local enabled_count = P.hook_id_to_table[id].enabled_count
    o1:remove()
    Tests.assert(P.hook_id_to_table[id].enabled_count, enabled_count - 1)
    o2:remove()


    -- Test if table reuse system works
    local holder
    local d2_ran = false

    local d1 = Hook.add_post(RAPI_NAMESPACE, gm.constants.function_dummy, function(self, other, result, args)
        holder = args
        gm.instance_create(100, 200, gm.constants.oLizard)
        Tests.assert(d2_ran, true)
        Tests.assert(args[1].value, 123)
        Tests.assert(args[2].value, 456)
        Tests.assert(args[3].value, "abc")
        Tests.assert(args[4], nil)
    end)
    local d2 = Hook.add_post(RAPI_NAMESPACE, gm.constants.instance_create, function(self, other, result, args)
        if args[3].value ~= gm.constants.oLizard then return end
        d2_ran = true
        Tests.assert(args ~= holder, true)
        Tests.assert(args[1].value, 100)
        Tests.assert(args[2].value, 200)
        Tests.assert(args[4], nil)
    end)
    Tests.pause_for(1)

    gm.function_dummy(123, 456, "abc")
    gm.instance_destroy(gm.constants.oLizard)
    d1:remove()
    d2:remove()


    -- Test if args and result are wrapped
    local cre, prh, poh
    cre = Hook.add_post(RAPI_NAMESPACE, gm.constants.array_create, function(self, other, result, args)
        if ran1 then return end
        ran1 = true
        local arr = result.value
        Tests.assert(type(arr), "userdata")
        Tests.assert(arr.RAPI, "Array")
        cre:remove()
    end)
    prh = Hook.add_pre(RAPI_NAMESPACE, gm.constants.array_set, function(self, other, result, args)
        if ran2 then return end
        ran2 = true
        local arr = args[1].value
        Tests.assert(type(arr), "userdata")
        Tests.assert(arr.RAPI, "Array")
        prh:remove()
    end)
    poh = Hook.add_post(RAPI_NAMESPACE, gm.constants.array_set, function(self, other, result, args)
        if ran3 then return end
        ran3 = true
        local arr = args[1].value
        Tests.assert(type(arr), "userdata")
        Tests.assert(arr.RAPI, "Array")
        poh:remove()
    end)
    Tests.pause_for(1)

    -- The test may also be executed by the game doing
    -- array stuff elsewhere during the 1 frame, which is fine
    local arr = gm.array_create(0, 0)
    gm.array_set(arr, 0, 123)
    cre:remove()
    prh:remove()
    poh:remove()
end