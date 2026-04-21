return function()
    local og_n = GM.instance_number(gm.constants.oB)
    Tests.assert(type(og_n) == "number", "`og_n` is of type '"..type(og_n).."'")

    local a = GM.instance_create(0, 0, gm.constants.oB)
    local b = GM.instance_create(0, 0, gm.constants.oB)
    local n = GM.instance_number(gm.constants.oB)
    Tests.assert(n == og_n + 2, "`n` is "..tostring(n)..", `og_n` is "..tostring(og_n))

    local a_mt
    if type(a) == "table" then
        Tests.assert(a.RAPI == "Instance", "`a.RAPI` is '"..tostring(a.RAPI).."'")
        a_mt = getmetatable(a.value).__name
    else a_mt = getmetatable(a).__name
    end
    Tests.assert(a_mt == "sol.CInstance*", "`a_mt` is '"..tostring(a_mt).."'")

    GM.instance_destroy(a)
    local n = GM.instance_number(gm.constants.oB)
    Tests.assert(n == og_n + 1, "`n` is "..tostring(n)..", `og_n` is "..tostring(og_n))

    GM.instance_destroy(b)
    local n = GM.instance_number(gm.constants.oB)
    Tests.assert(n == og_n, "`n` is "..tostring(n)..", `og_n` is "..tostring(og_n))

    local var = "AAAAHHHRGH!"
    Tests.assert(GM.variable_global_get(var) == nil, "`variable_global_get` is "..tostring(GM.variable_global_get(var)))
    GM.variable_global_set(var, 123)
    Tests.assert(GM.variable_global_get(var) == 123, "`variable_global_get` is "..tostring(GM.variable_global_get(var)))
    GM.variable_global_set(var, nil)
    Tests.assert(GM.variable_global_get(var) == nil, "`variable_global_get` is "..tostring(GM.variable_global_get(var)))
end