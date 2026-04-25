Each test suite should be its own folder, containing an `__init.lua` and test case files.

```lua
-- Example `__init.lua`

Tests.add_test_suite(
    "My Test Suite",
    "tests/my_test_suite"
)
```