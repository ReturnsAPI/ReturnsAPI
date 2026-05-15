-- ReadOnly

---@class ReadOnly
ReadOnly = new_class()
C.ReadOnly = ReadOnly

local proxy = P.proxy
local metatable

local new_proxy = new_proxy


-- ========== Static Methods ==========

--[[
Returns a read-only version of the provided table.
]]
---@param t table The table to make read-only.
ReadOnly.new = function(t)
    return new_proxy(t, metatable)
end


-- ========== Metatables ==========

---@class ReadOnly
---@field RAPI string

local mt_name = "ReadOnly"

W.ReadOnly = {
    __index = function(t, k)
        if k == "RAPI" then return mt_name end
        return proxy[t][k]
    end,
    
    __newindex = function(t, k, v)
        log.error("Table is read-only", 2)
    end,

    __call = function(t, ...)
        return proxy[t](...)
    end,

    __len = function(t)
        return #proxy[t]
    end,

    __eq = function(p1, p2)
        return proxy[p1] == proxy[p2]
    end,

    __pairs = function(t)
        return next, proxy[t], nil
    end,

    __ipairs = function(t)
        local n = #t
        return function(t, k)
            k = k + 1
            if k <= n then return k, proxy[t][k] end
        end, t, 0
    end,

    __metatable = mt_wrapper_name(mt_name),
}
metatable = W.ReadOnly