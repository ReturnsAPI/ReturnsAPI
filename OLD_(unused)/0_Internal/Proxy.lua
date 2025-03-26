-- Proxy

-- This does not create read-only tables, only proxies
-- This class is also private

local originals = setmetatable({}, {__mode = "k"})

Proxy = {
    new = function(t, mt)
        local proxy = newproxy(true)
        originals[proxy] = t or {}
        local mt = getmetatable(proxy)
        mt.__index = function(u, k) return Proxy.get(u)[k] end
        mt.__newindex = function(u, k, v) Proxy.get(u)[k] = v end
        mt.__metatable = "RAPI.Wrapper.GenericProxy"
        mt.__gc = function(u) print("Collected!") end
        return proxy
    end,

    -- new_gc = function(t, mt)
    --     local proxy = {}
    --     originals[proxy] = t or {}
    --     setmetatable_gc(proxy, mt)
    --     return proxy
    -- end,

    get = function(proxy)
        return originals[proxy]
    end,

    set = function(proxy, value)
        originals[proxy] = value
    end
}

_CLASS["Proxy"] = Proxy