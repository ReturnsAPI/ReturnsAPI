-- FindCache

-- Cache base for resource lookups

-- Used by
-- * Object

run_once(function()

    FindCache = {
        new = function()
            return setmetatable({
                current_id  = 0,    -- Unique ID for each callback fn
                id_lookup   = {},   -- Lookup callback function data tables by ID
                sections    = {}    -- Separate into sections, each having their own priorities
            }, find_cache_mt)
        end
    }


    find_cache_mt = {
        __index = {

            

        }
    }

end)