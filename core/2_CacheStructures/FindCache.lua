-- FindCache

-- Cache base for resource lookups

-- Used by
-- * Object

run_once(function()

    FindCache = {
        new = function()
            return setmetatable({
                ror         = {}    -- Vanilla namespace cache
            }, find_cache_mt)
        end
    }


    find_cache_mt = {
        __index = {

            -- Set value in cache
            set = function(self, value, identifier, namespace)
                -- Create namespace cache if existn't
                self[namespace] = self[namespace] or {}

                -- Set value
                self[namespace][identifier] = value
            end,


            -- Get value from cache in provided namespace,
            -- or default namespace *and* "ror" if not provided
            get = function(self, identifier, namespace, namespace_is_specified)
                -- Create namespace cache if existn't
                self[namespace] = self[namespace] or {}

                -- Check in namespace cache
                local cached = self[namespace][identifier]
                if cached then return cached end
                
                -- Check if "ror" cache
                if not namespace_is_specified then
                    local cached = self["ror"][identifier]
                    if cached then return cached end
                end
            end

        }
    }

end)