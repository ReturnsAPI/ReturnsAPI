-- Net

Net = new_class()



-- ========== Static Methods ==========

Net.online = function()
    local out = RValue.new(0)
    gmf._mod_net_isOnline(nil, nil, out, 0, nil)
    return RValue.to_wrapper(out)
end


Net.host = function()
    local out = RValue.new(0)
    gmf._mod_net_isHost(nil, nil, out, 0, nil)
    return RValue.to_wrapper(out)
end


Net.client = function()
    local out = RValue.new(0)
    gmf._mod_net_isClient(nil, nil, out, 0, nil)
    return RValue.to_wrapper(out)
end



__class.Net = Net