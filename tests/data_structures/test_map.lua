return function()
    -- ===== Map.new / size =====
    local map = Map.new()
    Tests.assert(map:size() == 0, "`Map.new():size()` is "..tostring(map:size()))

    local map2 = Map.new({ a = 1, b = 2 })
    Tests.assert(map2:size() == 2, "`Map.new({a=1,b=2}):size()` is "..tostring(map2:size()))

    -- ===== set / get =====
    map:set("x", 10)
    map:set("y", 20)

    Tests.assert(map:get("x") == 10, "`get('x')` is "..tostring(map:get("x")))
    Tests.assert(map:get("y") == 20, "`get('y')` is "..tostring(map:get("y")))

    -- ===== Lua syntax =====
    map.z = 30
    Tests.assert(map.z == 30, "`map.z` is "..tostring(map.z))

    -- ===== overwrite =====
    map:set("x", 99)
    Tests.assert(map:get("x") == 99, "`get('x') after overwrite is "..tostring(map:get("x")))

    -- ===== delete =====
    map:delete("x")
    local v = map:get("x")
    Tests.assert(v == nil, "`get('x') after delete is "..tostring(v))

    -- ===== clear =====
    map:clear()
    Tests.assert(map:size() == 0, "`size()` after clear is "..tostring(map:size()))

    -- ===== pairs iteration =====
    local map3 = Map.new({ a = 1, b = 2, c = 3 })

    local count = 0
    local sum = 0

    for k, v in pairs(map3) do
        count = count + 1
        sum = sum + v
    end

    Tests.assert(count == 3, "`pairs count` is "..tostring(count))
    Tests.assert(sum == 6, "`pairs sum` is "..tostring(sum))

    -- ===== size metamethod =====
    Tests.assert(#map3 == 3, "`#map3` is "..tostring(#map3))

    -- ===== exists / destroy =====
    local map4 = Map.new()
    local e = map4:exists()
    Tests.assert(e == true, "`exists()` before destroy is "..tostring(e))

    map4:destroy()
    e = map4:exists()
    Tests.assert(e == false, "`exists()` after destroy is "..tostring(e))
end
