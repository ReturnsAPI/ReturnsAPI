-- Internal

-- Utility functions for RAPI

function userdata_type(userdata)
    return getmetatable(player).__name
end