-- Proxy

-- This does not create read-only tables, only proxies
-- This class is also private

local originals = setmetatable({}, {__mode = "k"})

Proxy = {
    new = function(t, mt)
        local proxy = {}
        originals[proxy] = t or {}
        setmetatable(proxy, mt)
        return proxy
    end,

    new_gc = function(t, mt)
        local proxy = {}
        originals[proxy] = t or {}
        setmetatable_gc(proxy, mt)
        return proxy
    end,

    get = function(proxy)
        return originals[proxy]
    end
}