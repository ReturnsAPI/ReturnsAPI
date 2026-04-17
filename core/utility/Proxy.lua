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
---@param t any The table/data to make a proxy for.
---@param mt? table A metatable to assign to the proxy. <br>`proxy_default_mt` by default.
---@return table
Proxy.new = function(t, mt)
    local proxy = {}
    P.proxy[proxy] = t
    setmetatable(proxy, mt or W.Proxy)
    return proxy
end

--[[
Access the original table/data of a proxy.
]]
---@param proxy table The proxy.
---@return any
Proxy.get = function(proxy)
    return P.proxy[proxy]
end

--[[
Overwrite the original table/data of a proxy.
]]
---@param proxy table The proxy.
---@param any value The new value to set.
Proxy.set = function(proxy, value)
    P.proxy[proxy] = value
end


-- ========== Metatables ==========

---@class Proxy
---@field RAPI string

local mt_name = "Proxy"

W.Proxy = {
    __index = function(proxy, k)
        if k == "RAPI" then return mt_name end
        return Proxy.get(proxy)[k]
    end,

    __newindex = function(proxy, k, v)
        -- Throw read-only error
        if k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        Proxy.get(proxy)[k] = v
    end,

    __metatable = mt_wrapper_name(mt_name),
}