return function()
    -- pad_left
    Tests.assert(String.pad_left("abc", 5), "  abc")
    Tests.assert(String.pad_left("abc", 5, "0"), "00abc")
    Tests.assert(String.pad_left("abc", 3), "abc")
    Tests.assert(String.pad_left("abcdef", 3), "abcdef")
    Tests.assert(String.pad_left(123, 5), "  123")

    -- pad_right
    Tests.assert(String.pad_right("abc", 5), "abc  ")
    Tests.assert(String.pad_right("abc", 5, "0"), "abc00")
    Tests.assert(String.pad_right("abc", 3), "abc")
    Tests.assert(String.pad_right("abcdef", 3), "abcdef")
    Tests.assert(String.pad_right(123, 5), "123  ")

    -- pad_left_to_width
    local s = "abc"
    local space_w = gm.scribble_get_width(" ")
    local base_w  = gm.scribble_get_width(s)

    local w1 = base_w + space_w
    local r1 = String.pad_left_to_width(s, w1, " ")
    Tests.assert(#r1 >= #s, true)

    local r2 = String.pad_left_to_width(s, base_w, " ")
    Tests.assert(r2, s)

    local char = "0"
    local char_w = gm.scribble_get_width(char)
    local w2 = base_w + char_w * 2
    local r3 = String.pad_left_to_width(s, w2, char)
    Tests.assert(#r3 >= #s, true)

    -- pad_right_to_width
    local r4 = String.pad_right_to_width(s, w1, " ")
    Tests.assert(#r4 >= #s, true)

    local r5 = String.pad_right_to_width(s, base_w, " ")
    Tests.assert(r5, s)

    local r6 = String.pad_right_to_width(s, w2, char)
    Tests.assert(#r6 >= #s, true)

    -- split
    local t1 = String.split("a,b,c,d", ",")
    Tests.assert(#t1, 4)
    Tests.assert(t1[1], "a")

    local t2 = String.split("abcd", ",")
    Tests.assert(#t2, 1)
    Tests.assert(t2[1], "abcd")

    local t3 = String.split("", ",")
    Tests.assert(#t3, 0)

    local t4 = String.split("a,b,,c,d", ",", true)
    Tests.assert(#t4, 4)

    local t5 = String.split("a,b,c,d", ",", false, 2)
    Tests.assert(#t5, 3)
    Tests.assert(t5[3], "c,d")

    local t6 = String.split("aWORDbWORDcWORd", "WORD")
    Tests.assert(#t6, 3)
    Tests.assert(t6[3], "cWORd")

    local t7 = String.split("a, b, c, d", ",")
    Tests.assert(#t7, 4)
    Tests.assert(t7[2], " b")  -- leading space
end