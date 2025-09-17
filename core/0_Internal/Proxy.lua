-- Proxy

run_once(function()
    __proxy = setmetatable({}, {__mode = "k"})

    local proxy_default_name = "Proxy"
    local proxy_default_mt  = { __index = function(t, k)
                                    if k == "RAPI" then return proxy_default_name end
                                    return __proxy[t][k]
                                end,
                                __newindex = function(t, k, v) __proxy[t][k] = v end,
                                __metatable = "RAPI.Wrapper."..proxy_default_name }

    function make_proxy(t, mt)
        -- Returns a new proxy table, which is used as
        -- a "key" to access the real table/data in storage.
        -- Access using `__proxy[proxy]` for get/set
        local proxy = {}
        __proxy[proxy] = t or {}
        setmetatable(proxy, mt or proxy_default_mt)
        return proxy
    end
end)