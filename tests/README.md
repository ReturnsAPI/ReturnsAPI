Each test suite should be its own folder, containing an `__init.lua` and test case files.

```lua
-- Example `__init.lua`

---@type Tests
local tests = require("./tests/lib.lua")

tests.add_test_suite(
    "My Test Suite",
    path.combine(PATH, "tests/my_test_suite")
)
```