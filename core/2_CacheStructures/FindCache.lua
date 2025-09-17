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
            -- Can optionally provide a unique numerical ID
            --      * Used by ItemTier and LootPool for example
            set = function(self, value, identifier, namespace, num_id)
                -- Create namespace cache if existn't
                self[namespace] = self[namespace] or {}

                -- Set value
                self[namespace][identifier] = value

                -- Set value keyed to a numerical ID
                if num_id then self[num_id] = value end
            end,


            -- Get value from cache in provided namespace,
            -- or default namespace *and* "ror" if not provided
            -- Alternatively, get value using numerical ID
            get = function(self, identifier, namespace, namespace_is_specified)
                -- Get value from cache using numerical ID
                if type(identifier) == "number" then
                    return self[identifier]
                end

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

                return nil
            end

        }
    }

end)