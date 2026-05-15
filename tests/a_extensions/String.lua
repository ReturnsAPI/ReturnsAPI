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

    -- string extension
    Tests.assert(string.pad_left("x", 3), "  x")
    Tests.assert(string.pad_right("x", 3), "x  ")
    Tests.assert(type(string.pad_left_to_width), "function")
    Tests.assert(type(string.pad_right_to_width), "function")
end