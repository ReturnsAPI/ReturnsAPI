-- Net

--[[
```lua
-- (bools)
Net.online   --> `true` if the game client is currently connected online.
Net.host     --> `true` if the game client is currently the lobby host, or is offline.
Net.client   --> `true` if the game client is currently a lobby client.
```
]]

Net = new_class()

__net_cache = __net_cache or {}



-- ========== Metatables ==========

local wrapper_name = "Net"

make_table_once("metatable_net_class", {
    __index = function(t, k)
        if k == "online" then return __net_cache.online or gm._mod_net_isOnline()   end
        if k == "host"   then return __net_cache.host   or gm._mod_net_isHost()     end
        if k == "client" then return __net_cache.client or gm._mod_net_isClient()   end
    end,


    __newindex = function(t, k, v)
        log.error("Net has no properties to set", 2)
    end,


    __metatable = "RAPI.Class."..wrapper_name
})
setmetatable(Net, metatable_net_class)



-- ========== Hooks ==========

Hook.add_pre(RAPI_NAMESPACE, gm.constants.run_create, Callback.internal.FIRST, function(self, other, result, args)
    __net_cache = {
        online  = gm._mod_net_isOnline(),
        host    = gm._mod_net_isHost(),
        client  = gm._mod_net_isClient()
    }
end)


Hook.add_post(RAPI_NAMESPACE, gm.constants.run_destroy, Callback.internal.FIRST, function(self, other, result, args)
    __net_cache = {}
end)



-- Public export
__class.Net = Net
__class_mt.Net = metatable_net_class