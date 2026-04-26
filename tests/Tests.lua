-- Tests

---@class Tests
Tests = {}
TG = {} -- Test globals <br>Table is only rebuilt on RAPI hotload

local test_fns = {} ---@type table<integer, function>

local running = 0   -- The index of the current test function. <br>Non-zero if the test suite is currently running.
local co            ---@type thread Coroutine of the current test function.
local pause_fn      ---@type function The current function pausing the coroutine; runs every frame. <br>`co` will resume when conditions have met; call `Tests.resume()`.

local assert_success    ---@type string ✓✗•
local assert_err        ---@type table<integer, string>
local msgs              ---@type table<integer, string>

-- Test functions are executed in this loop
-- Allows for pausing in a test file until
-- conditions are met, and then resuming the test
gm.post_script_hook(gm.constants.__input_system_tick, function(self, other, result, args)
    if running <= 0 then return end

    if pause_fn then
        pause_fn()
        return
    end

    if not co then
        -- Handle end of test suite
        if running > #test_fns then
            running = 0

            -- Go back to title screen
            -- From `gml_Object_oPauseMenu_Other_10`
            gm.run_destroy()
            gm.clean_instances(false)
            gm.save_save()
            gm.room_goto_w(gm.constants.rStart)
            return
        end

        -- Initialize test session for current function
        co = coroutine.create(test_fns[running].fn)
        assert_success = ""
        assert_err = {}
        msgs = {}
    end

    local success, err = coroutine.resume(co)
    if not success then
        table.insert(assert_err, err)
    end

    if coroutine.status(co) == "dead" then
        -- Display results for test session
        local data = test_fns[running]

        local out_msgs = ""
        if data.msgs then
            for i, msg in ipairs(data.msgs) do
                out_msgs = out_msgs.."\n|   • "..msg
            end
        end

        local out_err = ""
        for i, err in ipairs(assert_err) do
            out_err = out_err.."\n".."|   ✗ "..err
        end

        local out = string.format(
            "\n| %s%s\n| \n| [%s]%s",
            data.filename,
            out_msgs,
            assert_success,
            out_err
        )

        if #assert_err > 0 then
            log.warning(out)
            running = 10000 -- Abort further tests
        else
            print(out)
        end

        running = running + 1
        co = nil
    end
end)

-- Big Red Button
gui.add_to_menu_bar(function()
    if ImGui.Button("Run test suite") then
        if running <= 0 then
            running = 1
        end
    end
end)

-- Collect all test file functions
local dirs = path.get_directories(path.combine(PATH, "tests"))
for _, dir in ipairs(dirs) do
    local files = path.get_files(dir)
    for _, file in ipairs(files) do
        local filename = path.filename(file)
        local ret = {require(file)}
        local fn = (type(ret[1]) == "function" and ret[1]) or ret[2]
        if fn then
            table.insert(test_fns, {
                filename = filename,
                fn       = fn,
                msgs     = type(ret[1]) == "table" and ret[1],
            })
        end
    end
end


-- ========== Static Methods ==========

---@param value any The value to assert.
---@param expected value The expected value for `value`.
function Tests.assert(value, expected)
    if value == expected then
        assert_success = assert_success.."✓"
        return
    end

    assert_success = assert_success.."."
    local err = string.format(
        "Line %d: got %s (expected %s)",
        debug.getinfo(2, "l").currentline,
        tostring(value),
        tostring(expected)
    )
    table.insert(assert_err, err)
end

--[[
Pause the current test.
]]
---@param fn The pause function to run.
function Tests.pause(fn)
    if not fn then throw("fn not provided") end
    pause_fn = fn
    coroutine.yield(co)
end

--[[
Resume a paused test. <br>
Should be called in the pause function when done.
]]
function Tests.resume()
    pause_fn = nil
end

--[[
Shortcut function for going to the title screen.
]]
function Tests.goto_title()
    -- Go to title screen
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
end

--[[
Shortcut function for starting a new run. <br>
Always passes through the title screen first.
]]
function Tests.start_run()
    Tests.goto_title()

    -- Go to CSS
    -- From `gml_Object_oStartMenu_Create_0`
    gm.variable_global_set("coop", 0)
    gm.variable_global_set("__gamemode_current", 0)
    gm.game_lobby_start()
    gm.room_goto_w(gm.constants.rSelect)

    Tests.pause(function()
        -- Resume when on CSS
        if gm.bool(gm.instance_exists(gm.constants.oSelectMenu)) then
            Tests.resume()
        end
    end)

    -- Start a run
    local s = gm.instance_find(gm.constants.oSelectMenu, 0)
    s.run_start(s, s)

    Tests.pause(function()
        -- Resume when player has loaded
        if gm.bool(gm.instance_exists(gm.constants.oP)) then
            Tests.resume()
        end
    end)
end

--[[
Shortcut function for pausing for `n` frames.
]]
---@param n integer The number of frames to pause for.
function Tests.pause_for(n)
    Tests.pause(function()
        n = n - 1
        if n <= 0 then
            Tests.resume()
        end
    end)
end