return function()
    -- Go back to title screen
    -- From `gml_Object_oPauseMenu_Other_10`
    gm.run_destroy()
    gm.clean_instances(false)
    gm.save_save()
    gm.room_goto_w(gm.constants.rStart)

    Tests.pause(function()
        -- Resume when on title screen
        if gm.bool(gm.instance_exists(gm.constants.oStartMenu)) then
            Tests.resume()
        end
    end)

    Tests.assert()

    -- TESTING; used later
    -- -- Go to CSS
    -- -- From `gml_Object_oStartMenu_Create_0`
    -- gm.variable_global_set("coop", 0)
    -- gm.variable_global_set("__gamemode_current", 0)
    -- gm.game_lobby_start()
    -- gm.room_goto_w(gm.constants.rSelect)

    -- Tests.pause(function()
    --     -- Resume when on CSS
    --     if gm.bool(gm.instance_exists(gm.constants.oSelectMenu)) then
    --         Tests.resume()
    --     end
    -- end)

    -- -- Start a run
    -- local s = gm.instance_find(gm.constants.oSelectMenu, 0)
    -- s.run_start(s, s)

    -- Tests.pause(function() end)
end