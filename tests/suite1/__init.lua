---@type Tests
local tests = require("./tests/lib.lua")

tests.add_test_suite(
    "Test Suite 1",
    path.combine(PATH, "tests/suite1")
)