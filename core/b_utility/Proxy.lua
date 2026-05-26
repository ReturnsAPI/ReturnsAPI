-- Proxy

run_on_initial_load(function()
    P.proxy = setmetatable({}, {__mode = "k"})  ---@type table<table, any> Maps proxy table "keys" to stored values.
end)

local proxy = P.proxy
local metatable


-- ========== Static Methods ==========

--[[
Creates a new proxy table, which is used as <br>
a "key" to access the real table/data in storage.
]]
---@param t any The table/data to make a proxy for.
---@param mt? table A metatable to assign to the proxy. <br>`proxy_default_mt` by default.
---@return table proxy
function new_proxy(t, mt)
    local p = {}
    proxy[p] = t
    setmetatable(p, mt or metatable)
    return p
end


-- ========== Metatables ==========

---@class Proxy
---@field RAPI string The name of this wrapper.

local mt_name = "Proxy"

W.Proxy = {
    __index = function(t, k)
        if k == "RAPI" then return mt_name end
        return proxy[t][k]
    end,

    __newindex = function(t, k, v)
        -- Throw read-only error
        if k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        proxy[t][k] = v
    end,

    __eq = function(p1, p2)
        return proxy[p1] == proxy[p2]
    end,

    __metatable = mt_wrapper_name(mt_name),
}
metatable = W.Proxy