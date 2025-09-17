-- ENVY

run_once(function()
    __namespace_path = {}   -- Paths to mod folders that use RAPI
    __auto_setups = {}      -- Mod ENVs that call `.auto()`; used when hotloading RAPI
end)


function public.setup(env, namespace)
    if env == nil then
        env = envy.getfenv(2)
    end

    -- Replace "-"s in namespace with "." to not
    -- conflict with some vanilla functions
    local namespace = namespace or env["!guid"]:gsub("-", ".")
    
    -- Store mod folder path
    __namespace_path[namespace] = env["!plugins_mod_folder_path"]

    -- Create wrapper by copying all class *function* references
    -- This allows for namespace binding for certain functions and
    -- prevents a mod messing with another mod's import without requiring read-only
    local wrapper = {}
    for name, class_ref in pairs(__class) do

        -- Create copy
        local copy = {}

        -- Copy k, v references from original to copy table
        for k, v in pairs(class_ref) do
            if k ~= "internal" then
                -- Base copy
                copy[k] = v

                -- Namespace binding
                if type(v) == "function" then
                    local edited = false

                    -- Immutable namespace
                    -- (`NAMESPACE` (in caps) argument is first)
                    if debug.getlocal(v, 1) == "NAMESPACE" then
                        copy[k] = function(...)
                            return v(namespace, ...)
                        end
                        edited = true
                    end

                    -- Check for optional namespace
                    -- (`namespace` argument is *not* first)
                    if not edited then
                        local pos = nil
                        local nparams = debug.getinfo(v).nparams
                        for i = 1, nparams do
                            if debug.getlocal(v, i):lower() == "namespace" then
                                pos = i
                                break
                            end
                        end

                        -- Someone please tell me there is a better way to do this
                        if pos then
                            if pos == 1 then
                                copy[k] = function(ns)
                                    if ns then ns = ns:gsub("-", ".") end
                                    return v(parse_optional_namespace(ns, namespace))
                                end
                            elseif pos == 2 then
                                copy[k] = function(arg1, ns)
                                    if ns then ns = ns:gsub("-", ".") end
                                    return v(arg1, parse_optional_namespace(ns, namespace))
                                end
                            elseif pos == 3 then
                                copy[k] = function(arg1, arg2, ns)
                                    if ns then ns = ns:gsub("-", ".") end
                                    return v(arg1, arg2, parse_optional_namespace(ns, namespace))
                                end
                            elseif pos == 4 then
                                copy[k] = function(arg1, arg2, arg3, ns)
                                    if ns then ns = ns:gsub("-", ".") end
                                    return v(arg1, arg2, arg3, parse_optional_namespace(ns, namespace))
                                end
                            elseif pos == 5 then
                                copy[k] = function(arg1, arg2, arg3, arg4, ns)
                                    if ns then ns = ns:gsub("-", ".") end
                                    return v(arg1, arg2, arg3, arg4, parse_optional_namespace(ns, namespace))
                                end
                            elseif pos == 6 then
                                copy[k] = function(arg1, arg2, arg3, arg4, arg5, ns)
                                    if ns then ns = ns:gsub("-", ".") end
                                    return v(arg1, arg2, arg3, arg4, arg5, parse_optional_namespace(ns, namespace))
                                end
                            elseif pos == 7 then
                                copy[k] = function(arg1, arg2, arg3, arg4, arg5, arg6, ns)
                                    if ns then ns = ns:gsub("-", ".") end
                                    return v(arg1, arg2, arg3, arg4, arg5, arg6, parse_optional_namespace(ns, namespace))
                                end
                            end
                        end
                    end

                -- Enums
                elseif type(v) == "table" then
                    -- Copy over enum values to new table
                    local t = {}
                    for k2, v2 in pairs(v) do
                        t[k2] = v2
                    end
                    copy[k] = t

                end
            end
        end

        -- Copy metatable over (if applicable)
        if __class_mt[name] then setmetatable(copy, __class_mt[name]) end

        wrapper[name] = copy
    end

    return wrapper
end


function public.auto(properties)
    local properties = properties or {}

    local env = envy.getfenv(2)
    local wrapper = public.setup(env, properties.namespace)
    envy.import_all(env, wrapper)

    -- Save mod ENV (and preferred namespace) for calling again on RAPI hotload
    __auto_setups[env] = { namespace = properties.namespace }

    -- Override default `print`, `type`, and `tostring` with Util's versions
    if not env.lua_print then
        env.lua_print = env.print
        env.lua_type = env.type
        env.lua_tostring = env.tostring
    end
    env.print = Util.print
    env.type = Util.type
    env.tostring = Util.tostring

    -- Add Math functions to `math`
    for k, v in pairs(Math) do
        if k ~= "internal" then
            env.math[k] = v
        end
    end
    
    local namespace = properties.namespace or env["!guid"]:gsub("-", ".")
    run_clear_namespace_functions(namespace)    -- in Internal.lua

    -- Autoregister to Language
    if Language         then Language.register_autoload(env) end
end


-- Reimport class tables to mods
-- that called .auto() on RAPI hotload
run_on_hotload(function()
    for env, t in pairs(__auto_setups) do
        local wrapper = public.setup(env, t.namespace)
        envy.import_all(env, wrapper)

        -- Override default `print`, `type`, and `tostring` with Util's versions
        env.print = Util.print
        env.type = Util.type
        env.tostring = Util.tostring
    end
end)