-- ENVY

run_once(function()
    __namespace_path = {}
    __auto_setups = {}
end)


function public.setup(env, namespace)
    if env == nil then
        env = envy.getfenv(2)
    end

    local namespace = namespace or env["!guid"]:gsub("-", ".")
    __namespace_path[namespace] = env["!plugins_mod_folder_path"]

    local wrapper = {}
    for name, class_ref in pairs(__class) do
        -- Create copy
        local copy = {}

        -- Copy k, v references from original to copy table
        for k, v in pairs(class_ref) do
            if k ~= "internal" then
                copy[k] = v

                -- Namespace binding
                if type(v) == "function" then
                    local edited = false

                    -- Immutable namespace
                    if debug.getlocal(v, 1) == "namespace" then
                        copy[k] = function(...)
                            return v(namespace, ...)
                        end
                        edited = true
                    end

                    -- Optional namespace
                    if not edited then
                        local pos = nil
                        local nparams = debug.getinfo(v).nparams
                        for i = 2, nparams do
                            if debug.getlocal(v, i) == "namespace" then
                                pos = i
                                break
                            end
                        end

                        -- Someone please tell me there is a better way to do this
                        if pos then
                            if pos == 2 then
                                copy[k] = function(arg1, ns)
                                    if ns then ns = ns:gsub("-", ".") end
                                    return v(arg1, ns, namespace)
                                end
                            elseif pos == 3 then
                                copy[k] = function(arg1, arg2, ns)
                                    if ns then ns = ns:gsub("-", ".") end
                                    return v(arg1, arg2, ns, namespace)
                                end
                            elseif pos == 4 then
                                copy[k] = function(arg1, arg2, arg3, ns)
                                    if ns then ns = ns:gsub("-", ".") end
                                    return v(arg1, arg2, arg3, ns, namespace)
                                end
                            elseif pos == 5 then
                                copy[k] = function(arg1, arg2, arg3, arg4, ns)
                                    if ns then ns = ns:gsub("-", ".") end
                                    return v(arg1, arg2, arg3, arg4, ns, namespace)
                                end
                            elseif pos == 6 then
                                copy[k] = function(arg1, arg2, arg3, arg4, arg5, ns)
                                    if ns then ns = ns:gsub("-", ".") end
                                    return v(arg1, arg2, arg3, arg4, arg5, ns, namespace)
                                end
                            elseif pos == 7 then
                                copy[k] = function(arg1, arg2, arg3, arg4, arg5, arg6, ns)
                                    if ns then ns = ns:gsub("-", ".") end
                                    return v(arg1, arg2, arg3, arg4, arg5, arg6, ns, namespace)
                                end
                            end
                        end
                    end

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
    __auto_setups[env] = { namespace = properties.namespace }   -- Save for calling again on RAPI hotload

    -- Override default `print`, `type`, and `tostring` with Util's versions
    env.lua_print = env.print
    env.lua_type = env.type
    env.lua_tostring = env.tostring
    env.print = Util.print
    env.type = Util.type
    env.tostring = Util.tostring

    -- Clear callbacks and other stuff associated with namespace
    local namespace = properties.namespace or env["!guid"]:gsub("-", ".")
    if Callback         then Callback.remove_all(namespace) end
    if Hook             then Hook.remove_all(namespace) end
    if Initialize       then Initialize.internal.remove_all(namespace) end
    if RecalculateStats then RecalculateStats.remove_all(namespace) end
    if DamageCalculate  then DamageCalculate.remove_all(namespace) end

    -- Autoregister to Language
    if Language         then Language.register_autoload(env) end
end


run_on_hotload(function()
    -- Reimport class tables to mods
    -- that called .auto() on RAPI hotload
    for env, t in pairs(__auto_setups) do
        local wrapper = public.setup(env, t.namespace)
        envy.import_all(env, wrapper)

        -- Override default `print`, `type`, and `tostring` with Util's versions
        env.print = Util.print
        env.type = Util.type
        env.tostring = Util.tostring
    end
end)