return function()
    -- .find
    local obj = Object.find("Lizard", nil, false)
    Tests.assert(type(obj), "table")
    Tests.assert(obj.RAPI, "Object")
    Tests.assert(obj.value, gm.constants.oLizard)
    local obj2 = Object.find("Lizard", "ror", true)
    Tests.assert(obj, obj2)
    local obj3 = Object.find("Lizard", "foo", true)
    Tests.assert(obj3, nil)

    -- .find_all
    local err = false
    local objs = Object.find_all("ror", true)
    for _, obj in ipairs(objs) do
        if obj.namespace ~= "ror" then
            err = true
            break
        end
    end
    Tests.assert(err, false)
    Tests.assert(#Object.find_all("foo", true), 0)

    -- .find_all_by_tag, :add_tag, :remove_tag, :has_tag, :get_tags
    local err = false
    local objs, n = Object.find_all_by_tag("enemy_projectile")
    Tests.assert(n > 0, true)
    for _, obj in pairs(objs) do
        if not obj:has_tag("enemy_projectile") then
            err = true
            break
        end
    end
    Tests.assert(err, false)
    local obj = Object.wrap(gm.constants.oLizard)
    obj:add_tag("foo")
    Tests.assert(obj:has_tag("foo"), true)
    Tests.assert(#obj:get_tags(), 1)
    local objs, n = Object.find_all_by_tag("foo")
    Tests.assert(n, 1)
    obj:remove_tag("foo")
    Tests.assert(obj:has_tag("foo"), false)
    Tests.assert(#obj:get_tags(), 0)

    -- :create
    local count = gm.instance_number(gm.constants.oLizard)
    obj:create()
    Tests.assert(gm.instance_number(gm.constants.oLizard), count + 1)
    local inst = obj:create(100, 200)
    Tests.assert(inst.x, 100)
    Tests.assert(inst.y, 200)
    gm.instance_destroy(gm.constants.oLizard)
    Tests.pause_for(1)

    -- :new
    Tests.goto_title()
    local obj = Object.new(RAPI_NAMESPACE, "myObject")
    Tests.assert(obj.value > Object.CUSTOM_START, true)
    local obj2 = Object.new(RAPI_NAMESPACE, "myObject2")
    Tests.assert(obj2.value > Object.CUSTOM_START, true)
    Tests.assert(obj ~= obj2, true)

    -- :set_sprite
    local spr = gm.constants.sWispIdle
    obj:set_sprite(spr)
    Tests.assert(gm.object_get_sprite_w(obj.value), spr)
    Tests.assert(obj.obj_sprite, spr)
end