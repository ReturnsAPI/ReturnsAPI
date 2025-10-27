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



-- ========== Metatables ==========

local wrapper_name = "Net"

make_table_once("metatable_net_class", {
    __index = function(t, k)
        if k == "online" then return gm._mod_net_isOnline() end
        if k == "host"   then return gm._mod_net_isHost() end
        if k == "client" then return gm._mod_net_isClient() end
    end,


    __newindex = function(t, k, v)
        log.error("Net has no properties to set", 2)
    end,


    __metatable = "RAPI.Class."..wrapper_name
})
setmetatable(Net, metatable_net_class)



-- Public export
__class.Net = Net
__class_mt.Net = metatable_net_class