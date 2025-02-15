-- ReadOnly

-- This version has no support for read-only *keys*
-- since that has significantly increased performance cost

-- Additionally, ReadOnly.new should be called to *finalize* the lock

local metatable_readonly = {
    __index = function(t, k)
        return Proxy.get(t)[k]
    end,
    
    __newindex = function(t, k, v)
        log.error("Table is read-only", 2)
    end,

    __call = function(t, ...)
        return Proxy.get(t)(...)
    end,

    __metatable = "RAPI.ReadOnly"
}

ReadOnly = {
    new = function(t)
        return Proxy.new(t, metatable_readonly)
    end
}

_CLASS["ReadOnly"] = ReadOnly