Tests.add_test_suite(
    "Utility",
    path.get_parent(debug.getinfo(1, "S").source:sub(2, -1))
)