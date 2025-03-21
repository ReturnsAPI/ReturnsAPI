-- Proxy

-- This class is private to prevent outside tampering

if not __proxy_originals then __proxy_originals = setmetatable({}, {__mode = "k"}) end

Proxy = {
    new = function(t, mt)
        local proxy = {}
        __proxy_originals[proxy] = t or {}
        Util.setmetatable_gc(proxy, mt or { __index = function(t, k)
                                                if k == "RAPI" then return getmetatable(t):sub(14, -1) end
                                                return Proxy.get(t)[k]
                                            end,
                                            __newindex = function(t, k, v) Proxy.get(t)[k] = v end,
                                            __metatable = "RAPI.Wrapper.Proxy"  })
        return proxy
    end,

    get = function(proxy)
        return __proxy_originals[proxy]
    end,

    set = function(proxy, value)
        __proxy_originals[proxy] = value
    end
}

__class.Proxy = Proxy