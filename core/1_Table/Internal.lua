-- Internal

-- Utility functions for RAPI

function userdata_type(userdata)
    if type(userdata) ~= "userdata" then return end
    return getmetatable(userdata).__name
end