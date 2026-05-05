return function()
    -- GM
    local og_n = GM.instance_number(gm.constants.oB)
    Tests.assert(type(og_n), "number")

    local a = GM.instance_create(0, 0, gm.constants.oB)
    local b = GM.instance_create(0, 0, gm.constants.oB)
    local n = GM.instance_number(gm.constants.oB)
    Tests.assert(n, og_n + 2)

    local a_mt
    if type(a) == "table" then
        Tests.assert(a.RAPI, "Instance")
        a_mt = getmetatable(a.value).__name
    else a_mt = getmetatable(a).__name
    end
    Tests.assert(a_mt, "sol.CInstance*")

    GM.instance_destroy(a)
    local n = GM.instance_number(gm.constants.oB)
    Tests.assert(n, og_n + 1)

    GM.instance_destroy(b)
    local n = GM.instance_number(gm.constants.oB)
    Tests.assert(n, og_n)

    local var = "AAAAHHHRGH!"
    Tests.assert(GM.variable_global_get(var), nil)
    GM.variable_global_set(var, 123)
    Tests.assert(GM.variable_global_get(var), 123)
    GM.variable_global_set(var, nil)
    Tests.assert(GM.variable_global_get(var), nil)


    -- GM.SO
    Tests.start_run()
    local p = GM.instance_find(gm.constants.oP, 0)
    local l = GM.instance_create(p.x, p.y, gm.constants.oLizard)
    GM.SO.actor_death(l, l, true)
end