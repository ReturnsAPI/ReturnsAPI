Tests.add_test_suite(
    "Extensions",
    path.get_parent(debug.getinfo(1, "S").source:sub(2, -1))
)