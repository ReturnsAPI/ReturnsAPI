-- ENVY

if not __namespace_path then __namespace_path = {} end  -- Preserve on hotload


function public.setup(env, namespace)
    if env == nil then
        env = envy.getfenv(2)
    end

    local namespace = namespace or env["!guid"]
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
                                    return v(arg1, ns or namespace, namespace)
                                end
                            elseif pos == 3 then
                                copy[k] = function(arg1, arg2, ns)
                                    return v(arg1, arg2, ns or namespace, namespace)
                                end
                            elseif pos == 4 then
                                copy[k] = function(arg1, arg2, arg3, ns)
                                    return v(arg1, arg2, arg3, ns or namespace, namespace)
                                end
                            elseif pos == 5 then
                                copy[k] = function(arg1, arg2, arg3, arg4, ns)
                                    return v(arg1, arg2, arg3, arg4, ns or namespace, namespace)
                                end
                            elseif pos == 6 then
                                copy[k] = function(arg1, arg2, arg3, arg4, arg5, ns)
                                    return v(arg1, arg2, arg3, arg4, arg5, ns or namespace, namespace)
                                end
                            end
                        end
                    end

                end
            end
        end

        -- Copy metatable over (if applicable)
        if __class_mt[name] then setmetatable(copy, __class_mt[name]) end

        -- Make new metatable
        if __class_mt_builder[name] then setmetatable(copy, __class_mt_builder[name](namespace)) end

        wrapper[name] = copy
    end

    return wrapper
end


function public.auto(properties)
    local properties = properties or {}

    local env = envy.getfenv(2)
    local wrapper = public.setup(env, properties.namespace)
    envy.import_all(env, wrapper)

    -- Override `print` and `type` with Util's versions
    env.print = Util.print
    env.type = Util.type

    -- Clear callbacks and other stuff associated with namespace
    local namespace = properties.namespace or env["!guid"]
    if Callback         then Callback.remove_all(namespace) end
    if Initialize       then Initialize.internal.remove_all(namespace) end
    if RecalculateStats then RecalculateStats.remove_all(namespace) end
end