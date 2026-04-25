return function()
    -- ========== pad_left ==========

    local r1 = String.pad_left("abc", 5)
    Tests.assert(r1 == "  abc",
        "`pad_left('abc', 5)` is '"..tostring(r1).."'")

    local r2 = String.pad_left("abc", 5, "0")
    Tests.assert(r2 == "00abc",
        "`pad_left('abc', 5, '0')` is '"..tostring(r2).."'")

    local r3 = String.pad_left("abc", 3)
    Tests.assert(r3 == "abc",
        "`pad_left('abc', 3)` is '"..tostring(r3).."'")

    local r4 = String.pad_left(123, 5)
    Tests.assert(r4 == "  123",
        "`pad_left(123, 5)` is '"..tostring(r4).."'")

    local r5 = String.pad_left("abcdef", 3)
    Tests.assert(r5 == "abcdef",
        "`pad_left('abcdef', 3)` is '"..tostring(r5).."'")


    -- ========== pad_right ==========

    local r6 = String.pad_right("abc", 5)
    Tests.assert(r6 == "abc  ",
        "`pad_right('abc', 5)` is '"..tostring(r6).."'")

    local r7 = String.pad_right("abc", 5, "0")
    Tests.assert(r7 == "abc00",
        "`pad_right('abc', 5, '0')` is '"..tostring(r7).."'")

    local r8 = String.pad_right("abc", 3)
    Tests.assert(r8 == "abc",
        "`pad_right('abc', 3)` is '"..tostring(r8).."'")

    local r9 = String.pad_right(123, 5)
    Tests.assert(r9 == "123  ",
        "`pad_right(123, 5)` is '"..tostring(r9).."'")

    local r10 = String.pad_right("abcdef", 3)
    Tests.assert(r10 == "abcdef",
        "`pad_right('abcdef', 3)` is '"..tostring(r10).."'")


    -- ========== pad_left_to_width ==========

    -- Mock expected behavior: width >= string width → result length increases
    local s1 = "abc"
    local width1 = gm.scribble_get_width(s1) + gm.scribble_get_width(" ")

    local r11 = String.pad_left_to_width(s1, width1, " ")
    Tests.assert(#r11 >= #s1,
        "`pad_left_to_width` length is "..tostring(#r11))


    -- ========== pad_right_to_width ==========

    local r12 = String.pad_right_to_width(s1, width1, " ")
    Tests.assert(#r12 >= #s1,
        "`pad_right_to_width` length is "..tostring(#r12))


    -- ========== Custom Char Width Padding ==========

    local char = "0"
    local width2 = gm.scribble_get_width(s1) + gm.scribble_get_width(char) * 2

    local r13 = String.pad_left_to_width(s1, width2, char)
    Tests.assert(#r13 >= #s1,
        "`pad_left_to_width custom char` is '"..tostring(r13).."'")

    local r14 = String.pad_right_to_width(s1, width2, char)
    Tests.assert(#r14 >= #s1,
        "`pad_right_to_width custom char` is '"..tostring(r14).."'")


    -- ========== string extension injection ==========

    local r15 = string.pad_left("x", 3)
    Tests.assert(r15 == "  x",
        "`string.pad_left('x', 3)` is '"..tostring(r15).."'")

    local r16 = string.pad_right("x", 3)
    Tests.assert(r16 == "x  ",
        "`string.pad_right('x', 3)` is '"..tostring(r16).."'")

    Tests.assert(type(string.pad_left_to_width) == "function",
        "`string.pad_left_to_width` is "..tostring(type(string.pad_left_to_width)))

    Tests.assert(type(string.pad_right_to_width) == "function",
        "`string.pad_right_to_width` is "..tostring(type(string.pad_right_to_width)))
end