Tests.add_test_suite(
    "GM",
    path.get_parent(debug.getinfo(1, "S").source:sub(2, -1))
)