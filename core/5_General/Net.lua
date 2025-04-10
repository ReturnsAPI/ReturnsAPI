-- Net

Net = new_class()



-- ========== Static Methods ==========

--$static
--$return   bool
--[[
Returns `true` if the game client is currently connected online.
]]
Net.is_online = function()
    local out = RValue.new(0)
    gmf._mod_net_isOnline(nil, nil, out, 0, nil)
    return RValue.to_wrapper(out)
end


--$static
--$return   bool
--[[
Returns `true` if the game client is currently the lobby host.
]]
Net.is_host = function()
    local out = RValue.new(0)
    gmf._mod_net_isHost(nil, nil, out, 0, nil)
    return RValue.to_wrapper(out)
end


--$static
--$return   bool
--[[
Returns `true` if the game client is currently a lobby client.
]]
Net.is_client = function()
    local out = RValue.new(0)
    gmf._mod_net_isClient(nil, nil, out, 0, nil)
    return RValue.to_wrapper(out)
end



__class.Net = Net