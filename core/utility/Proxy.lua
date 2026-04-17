-- Proxy

run_once(function()
    P.proxy = setmetatable({}, {__mode = "k"})

    P.proxy_default_mt = {
        __index = function(t, k)
            return proxy_get(t)[k]
        end,

        __newindex = function(t, k, v)
            proxy_get(t)[k] = v
        end,

        __metatable = mt_wrapper_name("Proxy"),
    }
end)

--[[
Creates a new proxy table, which is used as <br>
a "key" to access the real table/data in storage.
]]
---@param t table The table to make a proxy for.
---@param mt? table A metatable to assign to the proxy. <br>`proxy_default_mt` by default.
---@return table
function proxy_new(t, mt)
    local proxy = {}
    P.proxy[proxy] = t
    setmetatable(proxy, mt or P.proxy_default_mt)
    return proxy
end

--[[
Access the original table of a proxy.
]]
---@param proxy table The proxy.
---@return table
function proxy_get(proxy)
    return P.proxy[proxy]
end