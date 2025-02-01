-- Proxy

-- This version has no support for read-only *keys*
-- since that has significantly increased performance cost

-- Additionally, Proxy.new should be called to *finalize* the lock

local originals = setmetatable({}, {__mode = "k"})

local metatable_proxy = {
    __index = function(t, k)
        return originals[t][k]
    end,
    
    __newindex = function(t, k, v)
        log.error("Table is read-only", 2)
    end,

    __len = function(t)
        return #originals[t]
    end,

    __call = function(t, ...)
        return originals[t](...)
    end,

    __pairs = function(t)
        return next, originals[t], nil
    end,

    __metatable = "Proxy"
}

local new = function(t)
    local proxy = {}
    originals[proxy] = t or {}
    setmetatable(proxy, metatable_proxy)
    return proxy
end

Proxy = new({new = new})