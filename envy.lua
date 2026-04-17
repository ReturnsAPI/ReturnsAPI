-- ENVY exports

--[[
Returns a table containing the API.
]]
---@param env? The ENV table of your mod. <br>If not provided, automatically fetches your ENV.
---@return table API
public.setup = function(env)
    env = env or envy.getfenv(2)

    local wrapper = {}

    -- For each public class, create a new table
    -- and copy all key-value pairs to it
    for name, class in pairs(C) do
        local copy = {}

        for k, v in pairs(class) do
            -- Base copy
            copy[k] = v

            -- Namespace binding
            if type(v) == "function" then
                -- Immutable/implicit namespace
                -- (`NAMESPACE` (in caps) argument is first)
                if debug.getlocal(v, 1) == "NAMESPACE" then
                    copy[k] = function(...)
                        return v(namespace, ...)
                    end

                -- Optional namespace
                -- (`namespace` (not caps) argument)
                else
                    copy[k] = function(...)
                        local args = {...}
                        -- args[k] = handle parsing here
                        return v(table.unpack(args, 1, select("#", ...)))
                    end
                end

            -- Enums
            elseif type(v) == "table" and not v.RAPI then
                -- Copy enum values to new table
                local t = {}
                for k2, v2 in pairs(v) do
                    t[k2] = v2
                end
                copy[k] = t

            end
        end

        -- Copy over class metatable (if applicable)
        if M[name] then setmetatable(copy, M[name]) end

        wrapper[name] = copy
    end

    return wrapper
end

--[[
Imports the API directly into your environment.
]]
public.auto = function()
    local env = envy.getfenv(2)
    local wrapper = public.setup(env)
    envy.import_all(env, wrapper)
end