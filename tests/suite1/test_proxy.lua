---@type Tests
local tests = require("./tests/lib.lua")

local t = {
    abc = 123,
}
local p = proxy_new(t)

local mtname = getmetatable(p)
tests.assert(mtname == mt_wrapper_name("Proxy"), "`__metatable` is "..tostring(mtname))

tests.assert(p.abc == 123, "`p.abc` is "..tostring(p.abc))
tests.assert(p.def == nil, "`p.def` is "..tostring(p.def))

p.def = 456
tests.assert(p.def == 456, "`p.def` is "..tostring(p.def))

t.def = 789
tests.assert(p.def == 789, "`p.def` is "..tostring(p.def))