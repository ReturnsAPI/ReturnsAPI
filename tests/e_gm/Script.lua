return function()
    -- .bind()
    local counter = 0
    local sum

    local fn = function(arg1, arg2)
        counter = counter + 1
        sum = arg1 + arg2
    end
    local scr = Script.bind(fn)

    Tests.assert(type(scr), "userdata")
    Tests.assert(scr.RAPI, "Script")
    Tests.assert(getmetatable(scr).__name, "sol.CScriptRef*")
    Tests.assert(scr.name, "function_dummy")

    local n = 10
    for i = 1, n do
        scr(10, 20)
    end
    Tests.assert(counter, n)
    Tests.assert(sum, 30)


    -- Check if wrapped when getting from struct
    local str = Global.__input_players[1]
    local scr = str.__profile_create
    Tests.assert(type(scr), "userdata")
    Tests.assert(scr.RAPI, "Script")


    -- Test instance script
    local p = gm.instance_find(gm.constants.oP, 0)
    local d = gm.instance_find(gm.constants.oDirectorControl, 0)
    Tests.assert(gm.instance_exists(p), 1)
    Tests.assert(gm.instance_exists(d), 1)

    d.player_level_up()
    Tests.assert(d.player_level, 2)
end