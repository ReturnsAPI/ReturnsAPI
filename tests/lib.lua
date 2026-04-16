-- Tests

local assert_filename = ""
local assert_success = ""
local assert_err = {}
local report = {}

---@class Tests
local t = {}

--[[
Initialize a new assert session for a test file. <br>
Add prior assert session first if it exists.
]]
---@param filename string
local function assert_init(filename)
    if not filename then log.error("assert_init: Missing filename", 2) end

    if assert_success ~= "" then
        table.insert(report, {
            assert_filename,
            assert_success,
            assert_err
        })
    end

    assert_filename = filename
    assert_success = ""
    assert_err = {}
end

--[[
Compile the results of a report, <br>
and initialize a new one.
]]
---@param name string The name of the report.
---@return string report
local function compile_report(name)
    if not name then log.error("compile_report: Missing report name", 2) end

    assert_init("")

    local out = "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    out = out..name
    out = out.."\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

    for i, assert in ipairs(report) do
        if i > 1 then out = out.."\n" end

        out = out..assert[1].."\n"
        out = out.."["..assert[2].."]\n"
        for _, err in ipairs(assert[3]) do
            out = out.."    ✗ "..err.."\n"
        end
    end

    out = out.."━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    report = {}
    return out
end

---@param cond? any If this evaluates to `true`, the assert passes.
---@param msg string The error message to display.
---@return boolean success, any ...
function t.assert(cond, msg)
    if cond then
        assert_success = assert_success.."✓"
        return
    end

    assert_success = assert_success.."."
    local src = debug.getinfo(2, "S").short_src:sub(40, -1)
    table.insert(assert_err, "..."..src..": "..msg)
end

---@param name string The name of the test suite.
---@param dir string The path to the test suite directory.
function t.run_test_suite(name, dir)
    if not name then log.error("run_test_suite: Missing name", 2) end
    if not dir then log.error("run_test_suite: Missing dir", 2) end

    local files = path.get_files(dir)
    for _, file in ipairs(files) do
        local filename = path.filename(file)
        if filename ~= "__init.lua" then
            assert_init(filename)
            require(file)
        end
    end

    print(compile_report(name))
end

---@param name string The name of the test suite.
---@param dir string The path to the test suite directory.
function t.add_test_suite(name, dir)
    if not name then log.error("run_test_suite: Missing name", 2) end
    if not dir then log.error("run_test_suite: Missing dir", 2) end

    gui.add_to_menu_bar(function()
        if ImGui.Button(name) then
            t.run_test_suite(
                name,
                dir
            )
        end
    end)
end

return t