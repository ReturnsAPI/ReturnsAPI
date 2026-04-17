-- Proxy

---@class Proxy
Proxy = {}

run_once(function()
    P.proxy = setmetatable({}, {__mode = "k"})
end)


-- ========== Static Methods ==========

--[[
Creates a new proxy table, which is used as <br>
a "key" to access the real table/data in storage.
]]
---@param t table The table to make a proxy for.
---@param mt? table A metatable to assign to the proxy. <br>`proxy_default_mt` by default.
---@return table
Proxy.new = function(t, mt)
    local proxy = {}
    P.proxy[proxy] = t
    setmetatable(proxy, mt or W.Proxy)
    return proxy
end

--[[
Access the original table of a proxy.
]]
---@param proxy table The proxy.
---@return table
Proxy.get = function(proxy)
    return P.proxy[proxy]
end


-- ========== Metatables ==========

local mt_name = "Proxy"

W.Proxy = {
    __index = function(proxy, k)
        if k == "RAPI" then return mt_name end
        return Proxy.get(proxy)[k]
    end,

    __newindex = function(proxy, k, v)
        Proxy.get(proxy)[k] = v
    end,

    __metatable = mt_wrapper_name(mt_name),
}