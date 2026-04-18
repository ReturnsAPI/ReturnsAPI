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
            if k == "internal" then goto continue end

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
                    local pos = nil
                    local nparams = debug.getinfo(v).nparams
                    for i = 1, nparams do
                        if debug.getlocal(v, i):lower() == "namespace" then
                            pos = i
                            break
                        end
                    end
                    if not pos then goto continue end

                    -- Handled like this to minimize function calls
                    -- More dev-friendly way would be to use table.pack and unpack
                    -- if pos == 1 then
                    --     copy[k] = function(ns)
                    --         return v(parse_optional_namespace(ns, namespace))
                    --     end
                    -- elseif pos == 2 then
                    --     copy[k] = function(arg1, ns)
                    --         return v(arg1, parse_optional_namespace(ns, namespace))
                    --     end
                    -- elseif pos == 3 then
                    --     copy[k] = function(arg1, arg2, ns)
                    --         return v(arg1, arg2, parse_optional_namespace(ns, namespace))
                    --     end
                    -- elseif pos == 4 then
                    --     copy[k] = function(arg1, arg2, arg3, ns)
                    --         return v(arg1, arg2, arg3, parse_optional_namespace(ns, namespace))
                    --     end
                    -- elseif pos == 5 then
                    --     copy[k] = function(arg1, arg2, arg3, arg4, ns)
                    --         return v(arg1, arg2, arg3, arg4, parse_optional_namespace(ns, namespace))
                    --     end
                    -- elseif pos == 6 then
                    --     copy[k] = function(arg1, arg2, arg3, arg4, arg5, ns)
                    --         return v(arg1, arg2, arg3, arg4, arg5, parse_optional_namespace(ns, namespace))
                    --     end
                    -- elseif pos == 7 then
                    --     copy[k] = function(arg1, arg2, arg3, arg4, arg5, arg6, ns)
                    --         return v(arg1, arg2, arg3, arg4, arg5, arg6, parse_optional_namespace(ns, namespace))
                    --     end
                    -- end
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

            ::continue::
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