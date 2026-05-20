return function()
    -- add
    local t1, t2 = gm.variable_global_get("_current_frame"), nil
    Alarm.add(RAPI_NAMESPACE, 5, function(a, b)
        Tests.assert(a, 1)
        Tests.assert(b, 2)
        t2 = gm.variable_global_get("_current_frame")
    end, 1, 2)
    Tests.pause_for(6)
    Tests.assert(type(t2), "number")
    local diff = t2 - t1
    Tests.assert(diff == 5 or diff == 6, true)  -- Alarm can vary by 1 frame depending on when it's added

    -- remove
    local unran = true
    local a = Alarm.add(RAPI_NAMESPACE, 1, function()
        unran = false
    end)
    Alarm.remove(a)
    Tests.pause_for(2)
    Tests.assert(unran, true)
end