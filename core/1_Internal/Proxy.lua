-- Proxy

-- This class is private to prevent outside tampering

local originals = setmetatable({}, {__mode = "k"})

Proxy = {
    new = function(t, mt)
        local proxy = {}
        originals[proxy] = t or {}
        Util.setmetatable_gc(proxy, mt or { __index = function(t, k)
                                                if k == "RAPI" then return getmetatable(t):sub(14, -1) end
                                                return Proxy.get(t)[k]
                                            end,
                                            __newindex = function(t, k, v) Proxy.get(t)[k] = v end,
                                            __metatable = "RAPI.Wrapper.Proxy"  })
        return proxy
    end,

    get = function(proxy)
        return originals[proxy]
    end,

    set = function(proxy, value)
        originals[proxy] = value
    end
}

__class.Proxy = Proxy