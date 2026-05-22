return function()
    -- TODO need some test cases for custom objs

    -- .create, .exists, .destroy
    local obj = new_proxy(gm.constants.oB)  -- Mock object
    local inst = Instance.create(0, 0, obj)
    Tests.assert(type(inst), "userdata")
    Tests.assert(Instance.exists(inst), true)
    Instance.destroy(inst)
    Tests.assert(Instance.exists(inst), false)

    -- .find
    gm.instance_destroy(gm.constants.oLizard)
    Tests.pause_for(1)
    Instance.create(0, 0, gm.constants.oLizard)
    Tests.assert(type(Instance.find(gm.constants.oLizard)), "userdata")
    Tests.assert(type(Instance.find(gm.constants.oLizard, 1)), "userdata")
    Tests.assert(Instance.find(gm.constants.oLizard, 2), nil)

    -- .find_all
    gm.instance_destroy(gm.constants.oLizard)
    Tests.pause_for(1)
    for i = 1, 10 do gm.instance_create(0, 0, gm.constants.oLizard) end
    Tests.assert(#Instance.find_all(gm.constants.oLizard), 10)

    -- .nearest
    gm.instance_destroy(gm.constants.oLizard)
    Tests.pause_for(1)
    local inst = gm.instance_create(10, 0, gm.constants.oLizard)
    for x = 9, 1, -1 do gm.instance_create(x, 0, gm.constants.oLizard) end
    local near = Instance.nearest(20, 0, gm.constants.oLizard)
    Tests.assert(near.id, inst.id)

    -- .count
    Tests.assert(Instance.count(gm.constants.oLizard), 10)

    -- .get_data
    local data1 = Instance.get_data(inst)
    local data2 = Instance.get_data(near)
    local data3 = Instance.get_data(inst, nil, "foo", true)
    local data4 = Instance.get_data(inst, "subtable")
    Tests.assert(type(data1), "table")
    Tests.assert(data1, data2)
    Tests.assert(data1 ~= data3, true)
    Tests.assert(data1 ~= data4, true)

    -- :destroy
    gm.instance_destroy(gm.constants.oLizard)
    Tests.pause_for(1)
    local inst = Instance.create(0, 0, gm.constants.oLizard)
    Tests.assert(Instance.exists(inst), true)
    inst:destroy()
    Tests.assert(Instance.exists(inst), false)

    -- :get_object_index, :get_object
    local inst = Instance.create(0, 0, gm.constants.oLizard)
    local obj_index  = inst.object_index
    local obj_index2 = inst:get_object_index()
    local obj        = inst:get_object()
    Tests.assert(obj_index, obj_index2)
    Tests.assert(obj.value, obj_index2)

    -- :is_colliding, :get_collisions
    local inst2 = Instance.create(0, 0, gm.constants.oLizard)
    Tests.assert(inst:is_colliding(gm.constants.oLizard), true)
    Tests.assert(inst:is_colliding(inst2), true)
    Tests.assert(#inst:get_collisions(gm.constants.oLizard), 1)
    inst2.x = 100
    Tests.pause_for(1)
    Tests.assert(inst:is_colliding(gm.constants.oLizard), false)
    Tests.assert(inst:is_colliding(inst2), false)
    Tests.assert(#inst:get_collisions(gm.constants.oLizard), 0)

    -- :get_collisions_rectangle, :get_collisions_circle
    gm.instance_destroy(gm.constants.oLizard)
    Tests.pause_for(1)
    local inst = Instance.create(0, 0, gm.constants.oLizard)
    for i = 1, 10 do gm.instance_create(i * 32, 0, gm.constants.oLizard) end
    local count = 5
    local t = inst:get_collisions_rectangle(gm.constants.oLizard, 0, -10, count * 32, 10)
    Tests.assert(#t, count)
    local t = inst:get_collisions_circle(gm.constants.oLizard, count * 32)
    Tests.assert(#t, count)

    -- :has_tag
    if Object and P.object_tags then
        Tests.assert(inst:has_tag("foo"), false)
        local obj = inst:get_object()
        obj:add_tag("foo")
        Tests.assert(inst:has_tag("foo"), true)
        obj:remove_tag("foo")
        Tests.assert(inst:has_tag("foo"), false)
    end

    -- Metatable
    Tests.assert(inst.RAPI, "Actor")
    Tests.assert(type(inst.hp), "number")
    Tests.assert(inst.hp, inst.maxhp)
    inst.hp = 50
    Tests.assert(inst.hp, 50)
    local inst2 = Instance.find(gm.constants.oLizard)
    Tests.assert(inst, inst2)

    if AttackInfo then
        -- TODO
    end
end