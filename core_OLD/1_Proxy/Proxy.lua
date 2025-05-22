-- Proxy

-- This class is private to prevent outside tampering

local proxy_default_name = "Proxy"
local proxy_default_mt  = { __index = function(t, k)
                                if k == "RAPI" then return proxy_default_name end
                                return Proxy.get(t)[k]
                            end,
                            __newindex = function(t, k, v) Proxy.get(t)[k] = v end,
                            __metatable = "RAPI.Wrapper."..proxy_default_name  }

run_once(function()
    __proxy_originals = setmetatable({}, {__mode = "k"})

    Proxy = {
        -- Returns a new proxy table, which is used as
        -- a "key" to access the real table/data in storage.
        new = function(t, mt)
            local proxy = {}
            __proxy_originals[proxy] = t or {}
            Util.setmetatable_gc(proxy, mt or proxy_default_mt)
            return proxy
        end,

        -- Get the real table/data using the proxy "key".
        get = function(proxy)
            return __proxy_originals[proxy]
        end,

        -- Set the real table/data using the proxy "key".
        set = function(proxy, value)
            __proxy_originals[proxy] = value
        end
    }
end)