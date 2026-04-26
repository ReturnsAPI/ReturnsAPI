return function()
    Tests.assert(Global.abcde, nil)
    Global.abcde = 123
    Tests.assert(Global.abcde, 123)
    Global.abcde = nil
    Tests.assert(Global.abcde, nil)

    -- wrap behavior
    local arr = Global.class_item
    Tests.assert(type(arr), "table")
    Tests.assert(arr.RAPI, "Array")

    -- unwrap behavior
    Global.abcde = Array.new()
    local arr = gm.variable_global_get("abcde")
    Tests.assert(getmetatable(arr).__name, "sol.RefDynamicArrayOfRValueLuaWrapper")
    Global.abcde = nil
end