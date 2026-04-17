-- ReadOnly

---@class ReadOnly
ReadOnly = {}
C.ReadOnly = ReadOnly


-- ========== Static Methods ==========

--[[
Returns a read-only version of the provided table.
]]
---@param t table The table to make read-only.
ReadOnly.new = function(t)
    return proxy_new(t, W.ReadOnly)
end


-- ========== Metatables ==========

W.ReadOnly = {
    __index = function(proxy, k)
        return proxy_get(proxy)[k]
    end,
    
    __newindex = function(proxy, k, v)
        log.error("Table is read-only", 2)
    end,

    __call = function(proxy, ...)
        return proxy_get(proxy)(...)
    end,

    __len = function(proxy)
        return #proxy_get(proxy)
    end,

    __eq = function(p1, p2)
        return proxy_get(p1) == proxy_get(p2)
    end,

    __pairs = function(proxy)
        return next, proxy_get(proxy), nil
    end,

    __ipairs = function(proxy)
        local n = #proxy
        return function(proxy, k)
            k = k + 1
            if k <= n then return k, proxy_get(proxy)[k] end
        end, proxy, 0
    end,

    __metatable = mt_wrapper_name("ReadOnly"),
}