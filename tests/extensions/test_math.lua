return function()
    Tests.assert(Math.DEG2RAD == (math.pi / 180), "`DEG2RAD` is wrong")
    Tests.assert(Math.RAD2DEG == (180 / math.pi), "`RAD2DEG` is wrong")

    local err = ""
    for i = 1, 1000 do
        local v = Math.randomf(1, 2)
        if v < 1 or v >= 2 then
            err = "`v` is "..tostring(v)
            break
        end
    end
    Tests.assert(err == "", err)

    Tests.assert(Math.round(1.4) == 1, "`round(1.4)` is "..tostring(Math.round(1.4)))
    Tests.assert(Math.round(1.5) == 2, "`round(1.5)` is "..tostring(Math.round(1.5)))
    Tests.assert(Math.round(1.6) == 2, "`round(1.6)` is "..tostring(Math.round(1.6)))

    Tests.assert(Math.sign(0) == 0, "`sign(0)` is "..tostring(Math.sign(0)))
    Tests.assert(Math.sign(0.5) == 1, "`sign(0.5)` is "..tostring(Math.sign(0.5)))
    Tests.assert(Math.sign(-0.5) == -1, "`sign(-0.5)` is "..tostring(Math.sign(-0.5)))
    Tests.assert(Math.sign(2) == 1, "`sign(2)` is "..tostring(Math.sign(2)))
    Tests.assert(Math.sign(-2) == -1, "`sign(-2)` is "..tostring(Math.sign(-2)))

    Tests.assert(Math.dcos(0) == 1, "`dcos(0) is "..tostring(Math.dcos(0)))
    Tests.assert(math.abs(Math.dcos(90)) <= 0.00001, "`dcos(90) is "..tostring(Math.dcos(90)))
    Tests.assert(Math.dcos(180) == -1, "`dcos(180) is "..tostring(Math.dcos(180)))

    Tests.assert(Math.dsin(0) == 0, "`dsin(0) is "..tostring(Math.dsin(0)))
    Tests.assert(math.abs(Math.dsin(90)) == 1, "`dsin(90) is "..tostring(Math.dsin(90)))
    Tests.assert(math.abs(Math.dsin(180)) <= 0.00001, "`dsin(180) is "..tostring(Math.dsin(180)))

    Tests.assert(Math.distance(0, 0, 3, 4) == 5, "`distance(0, 0, 3, 4)` is "..tostring(Math.distance(0, 0, 3, 4)))

    Tests.assert(Math.direction(0, 0, 1, -1) == 45, "`direction(0, 0, 1, -1)` is "..tostring(Math.direction(0, 0, 1, -1)))

    Tests.assert(Math.clamp(1, 5, 7) == 5, "`clamp(1, 5, 7)` is "..tostring(Math.clamp(1, 5, 7)))
    Tests.assert(Math.clamp(8, 5, 7) == 7, "`clamp(8, 5, 7)` is "..tostring(Math.clamp(8, 5, 7)))
    Tests.assert(Math.clamp(5, 5, 7) == 5, "`clamp(5, 5, 7)` is "..tostring(Math.clamp(5, 5, 7)))
    Tests.assert(Math.clamp(6, 5, 7) == 6, "`clamp(6, 5, 7)` is "..tostring(Math.clamp(6, 5, 7)))

    Tests.assert(Math.easein(0.5) == 0.25, "`easein(0.5)` is "..tostring(Math.easein(0.5)))
    Tests.assert(Math.easein(0.5, 1) == 0.5, "`easein(0.5, 1)` is "..tostring(Math.easein(0.5)))

    Tests.assert(Math.easeout(0.5) == 0.75, "`easeout(0.5)` is "..tostring(Math.easeout(0.5)))
    Tests.assert(Math.easeout(0.5, 1) == 0.5, "`easeout(0.5, 1)` is "..tostring(Math.easeout(0.5)))

    Tests.assert(Math.lerp(0, 10, 0.5) == 5, "`lerp(0, 10, 0.5)` is "..tostring(Math.lerp(0, 10, 0.5)))
    Tests.assert(Math.lerp(0, 100, 0.25) == 25, "`lerp(0, 100, 0.25)` is "..tostring(Math.lerp(0, 100, 0.25)))
end