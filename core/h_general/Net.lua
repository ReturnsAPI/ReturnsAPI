-- Net

---@class Net
Net = new_class()
C.Net = Net

run_on_initial_load(function()
    P.net_cache = {}
end)

local net_cache = P.net_cache

local gm_online = gm._mod_net_isOnline  ---@type function
local gm_host   = gm._mod_net_isHost    ---@type function
local gm_client = gm._mod_net_isClient  ---@type function


-- ========== Metatables ==========

---@class Net
---@field online boolean `true` if the game client is connected online.
---@field host   boolean `true` if the game client is a lobby host, or is offline.
---@field client boolean `true` if the game client is a lobby client.

M.Net = {
    __index = function(t, k)
        if k == "online" then return net_cache.online or gm_online() end
        if k == "host"   then return net_cache.host   or gm_host()   end
        if k == "client" then return net_cache.client or gm_client() end
    end,

    __newindex = function(t, k, v)
        log.error("Net has no properties to set", 2)
    end,

    __metatable = mt_class_name("Net"),
}
setmetatable(Net, M.Net)


-- ========== Hooks ==========

gm.pre_script_hook(gm.constants.run_create, function(self, other, result, args)
    P.net_cache = {
        online = gm_online(),
        host   = gm_host(),
        client = gm_client(),
    }
    net_cache = P.net_cache
end)

gm.post_script_hook(gm.constants.run_destroy, function(self, other, result, args)
    P.net_cache = {}
    net_cache = P.net_cache
end)