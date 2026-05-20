return function()
    Tests.assert(Global.abcde, nil)
    Global.abcde = 123
    Tests.assert(Global.abcde, 123)
    Global.abcde = nil
    Tests.assert(Global.abcde, nil)

    local arr = Global.class_item
    Tests.assert(type(arr), "userdata")
    Tests.assert(arr.RAPI, "Array")

    -- unwrap behavior
    Global.abcde = Array.new()
    local arr = gm.variable_global_get("abcde")
    Tests.assert(getmetatable(arr).__name, "sol.RefDynamicArrayOfRValueLuaWrapper")

    local list = List.new()
    Global.abcde = list
    local l = gm.variable_global_get("abcde")
    Tests.assert(l, list.value)
    list:destroy()

    Global.abcde = nil
end