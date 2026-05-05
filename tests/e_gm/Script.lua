return function()
    -- .bind()
    local counter = 0

    local fn = function()
        counter = counter + 1
    end
    local scr = Script.bind(fn)

    Tests.assert(type(scr), "table")
    Tests.assert(scr.RAPI, "Script")
    Tests.assert(getmetatable(scr.value).__name, "sol.CScriptRef*")
    Tests.assert(scr.name, "function_dummy")

    local n = 10
    for i = 1, n do
        scr()
    end
    Tests.assert(counter, n)


    -- Check if wrapped when getting from struct
    local str = Global.__input_players[1]
    local scr = str.__profile_create
    Tests.assert(type(scr), "table")
    Tests.assert(scr.RAPI, "Script")
end