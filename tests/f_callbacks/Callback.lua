return function()
    -- add
    local hit_info_rapi = Table.set{
        "Struct",     -- May be either depending on if the latter two
        "AttackInfo", -- are implemented or not at the time of this test
        "HitInfo"
    }
    local hit = false
    local cb = Callback.add(RAPI_NAMESPACE, Callback.ON_HIT_PROC, function(attacker, target, hit_info)
        hit = true
        Tests.assert(getmetatable(attacker).__name, "sol.CInstance*")
        Tests.assert(getmetatable(target  ).__name, "sol.CInstance*")
        Tests.assert(hit_info_rapi[hit_info.RAPI], true)
    end)
    Tests.assert(cb.RAPI, "CallbackFunction")

    local p = gm.instance_find(gm.constants.oP, 0)
    Tests.assert(gm.instance_exists(p), 1)
    local i = gm.instance_create(p.x + 32, p.y, gm.constants.oDummy)
    Tests.assert(gm.instance_exists(i), 1)

    gm._mod_attack_fire_bullet(
        p, p.x, p.y,
        100, 0, 1,
        gm.constants.sNone,
        false, true
    )
    Tests.pause_for(1)
    Tests.assert(hit, true)
    cb:remove()


    -- add_SO
    -- TODO


    -- new
    local cbn = Callback.new(RAPI_NAMESPACE, "myCallback")
    local cb  = Callback.add(RAPI_NAMESPACE, cbn, function(a)
        Tests.assert(a, 123)
        return 456
    end)
    local ret = cbn:call(123)
    Tests.assert(ret, 456)
    cb:remove()

    Tests.assert(cbn.namespace, RAPI_NAMESPACE)
    Tests.assert(cbn.identifier, "myCallback")


    -- find
    local cbt1 = Callback.find("onStageStart", "ror", true)
    local cbt2 = Callback.find("onStageStart", nil, false)
    Tests.assert(cbt1.RAPI, "CallbackType")
    Tests.assert(cbt1.value, Callback.ON_STAGE_START)
    Tests.assert(cbt1, cbt2)

    Tests.assert(Callback.find("myCallback", RAPI_NAMESPACE, true), cbn)


    -- find_all
    local cbs = Callback.find_all("ror", true)
    Tests.assert(#cbs, 43)


    -- Calling in priority order
    local n = 0
    local cb1 = Callback.add(RAPI_NAMESPACE, Callback.ON_DEATH, 100, function(actor, out_of_bounds)
        Tests.assert(n, 1)
        n = n + 1
    end)
    local cb2 = Callback.add(RAPI_NAMESPACE, Callback.ON_DEATH, -100, function(actor, out_of_bounds)
        Tests.assert(n, 3)
        n = n + 1
    end)
    local cb3 = Callback.add(RAPI_NAMESPACE, Callback.ON_DEATH, function(actor, out_of_bounds)
        Tests.assert(n, 2)
        n = n + 1
    end)
    local cb4 = Callback.add(RAPI_NAMESPACE, Callback.ON_DEATH, 200, function(actor, out_of_bounds)
        Tests.assert(n, 0)
        n = n + 1
    end)

    local l = gm.instance_create(100, 100, gm.constants.oLizard)
    gm.call("actor_kill", l, l)
    Tests.assert(n, 4)
    cb1:remove()
    cb2:remove()
    cb3:remove()
    cb4:remove()
end