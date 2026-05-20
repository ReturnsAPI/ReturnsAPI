return function()
    -- get_mod_info
    local p  = Util.get_mod_info(_ENV["!guid"])
    local p2 = Util.get_mod_info(RAPI_NAMESPACE)
    Tests.assert(p.guid, p2.guid)
    Tests.assert(p.namespace, RAPI_NAMESPACE)

    -- type
    local p = new_proxy()
    Tests.assert(Util.type({}), "table")
    Tests.assert(Util.type(p), "Proxy")

    -- bool
    Tests.assert(Util.bool(false), false)
    Tests.assert(Util.bool(nil), false)
    Tests.assert(Util.bool(-1), false)
    Tests.assert(Util.bool(0), false)
    Tests.assert(Util.bool(0.4), false)
    Tests.assert(Util.bool(0.6), true)
    Tests.assert(Util.bool(1), true)
    Tests.assert(Util.bool(100), true)
    Tests.assert(Util.bool("abc"), true)
    Tests.assert(Util.bool({}), true)
    Tests.assert(Util.bool(true), true)
end