-- ReadOnly

-- This version has no support for read-only *keys*
-- since that has significantly increased performance cost

-- Additionally, ReadOnly.new should be called to *finalize* the lock

local originals = setmetatable({}, {__mode = "k"})

local metatable_readonly = {
    __index = function(t, k)
        return originals[t][k]
    end,
    
    __newindex = function(t, k, v)
        log.error("Table is read-only", 2)
    end,

    __call = function(t, ...)
        return originals[t](...)
    end,

    -- __len = function(t)
    --     return #originals[t]
    -- end,

    -- __pairs = function(t)
    --     return next, originals[t], nil
    -- end,

    __metatable = "ReadOnly"
}

ReadOnly = {
    new = function(t)
        local readonly = {}
        originals[readonly] = t or {}
        setmetatable(readonly, metatable_readonly)
        return readonly
    end
}