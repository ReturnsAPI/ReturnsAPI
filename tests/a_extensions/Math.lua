return function()
    -- Constants
    Tests.assert(Math.DEG2RAD, math.pi / 180)
    Tests.assert(Math.RAD2DEG, 180 / math.pi)

    -- randomf
    local err = false
    for i = 1, 1000 do
        local v = Math.randomf(1, 2)
        if v < 1 or v >= 2 then
            err = true
            break
        end
    end
    Tests.assert(err, false)

    -- round
    Tests.assert(Math.round(1.4), 1)
    Tests.assert(Math.round(1.5), 2)
    Tests.assert(Math.round(1.6), 2)

    -- sign
    Tests.assert(Math.sign(0), 0)
    Tests.assert(Math.sign(0.5), 1)
    Tests.assert(Math.sign(-0.5), -1)
    Tests.assert(Math.sign(2), 1)
    Tests.assert(Math.sign(-2), -1)

    -- dcos
    Tests.assert(Math.dcos(0), 1)
    Tests.assert(math.abs(Math.dcos(90)) <= 0.00001, true)
    Tests.assert(Math.dcos(180), -1)

    -- dsin
    Tests.assert(Math.dsin(0), 0)
    Tests.assert(math.abs(Math.dsin(90)), 1)
    Tests.assert(math.abs(Math.dsin(180)) <= 0.00001, true)

    -- distance
    Tests.assert(Math.distance(0, 0, 3, 4), 5)
    Tests.assert(Math.distance(0, 0, 1, 1), math.sqrt(2))

    -- direction
    Tests.assert(Math.direction(0, 0, 1, -1), 45)
    Tests.assert(Math.direction(1, 1, 0, 0), 135)

    -- clamp
    Tests.assert(Math.clamp(1, 5, 7), 5)
    Tests.assert(Math.clamp(8, 5, 7), 7)
    Tests.assert(Math.clamp(5, 5, 7), 5)
    Tests.assert(Math.clamp(6, 5, 7), 6)

    -- easein
    Tests.assert(Math.easein(0.5), 0.25)
    Tests.assert(Math.easein(0.5, 1), 0.5)

    -- easeout
    Tests.assert(Math.easeout(0.5), 0.75)
    Tests.assert(Math.easeout(0.5, 1), 0.5)

    -- lerp
    Tests.assert(Math.lerp(0, 10, 0.5), 5)
    Tests.assert(Math.lerp(0, 100, 0.25), 25)
end