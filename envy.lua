-- ENVY

run_once(function()
    __auto_setups = {}      -- Store mod ENVs that call `.auto()`; used when hotloading RAPI

    -- Create storage for some ENV things
    -- and populate with RAPI's things
    local guid = _ENV["!guid"]
    local t = {
        namespace = RAPI_NAMESPACE,
        guid      = guid,
        path      = _ENV["!plugins_mod_folder_path"]
    }
    __namespace = {
        [RAPI_NAMESPACE] = t,
        [guid]  = t
    }
end)


function public.setup(env, namespace)
    if env == nil then
        env = envy.getfenv(2)
    end

    local guid = env["!guid"]
    local namespace = namespace or guid

    -- Prevent taking a namespace already used internally
    if namespace == RAPI_NAMESPACE
    or namespace == "__permanent" then
        log.warning("Cannot use namespace '"..namespace.."'; using '"..guid.."' instead")
        namespace = guid
    end

    -- Prevent taking a namespace already used by another mod
    if __namespace[namespace] then
        if guid ~= __namespace[namespace].guid then
            log.warning("Namespace '"..namespace.."' is already in use; using '"..guid.."' instead")
            namespace = guid
        end
    end
    
    -- Store some ENV things
    local t = {
        namespace = namespace,
        guid      = guid,
        path      = env["!plugins_mod_folder_path"]
    }
    __namespace[namespace] = t
    __namespace[guid]      = t

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
                    -- (`namespace` (not caps) argument)
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
                                    return v(parse_optional_namespace(ns, namespace))
                                end
                            elseif pos == 2 then
                                copy[k] = function(arg1, ns)
                                    return v(arg1, parse_optional_namespace(ns, namespace))
                                end
                            elseif pos == 3 then
                                copy[k] = function(arg1, arg2, ns)
                                    return v(arg1, arg2, parse_optional_namespace(ns, namespace))
                                end
                            elseif pos == 4 then
                                copy[k] = function(arg1, arg2, arg3, ns)
                                    return v(arg1, arg2, arg3, parse_optional_namespace(ns, namespace))
                                end
                            elseif pos == 5 then
                                copy[k] = function(arg1, arg2, arg3, arg4, ns)
                                    return v(arg1, arg2, arg3, arg4, parse_optional_namespace(ns, namespace))
                                end
                            elseif pos == 6 then
                                copy[k] = function(arg1, arg2, arg3, arg4, arg5, ns)
                                    return v(arg1, arg2, arg3, arg4, arg5, parse_optional_namespace(ns, namespace))
                                end
                            elseif pos == 7 then
                                copy[k] = function(arg1, arg2, arg3, arg4, arg5, arg6, ns)
                                    return v(arg1, arg2, arg3, arg4, arg5, arg6, parse_optional_namespace(ns, namespace))
                                end
                            end
                        end
                    end

                -- Enums
                elseif type(v) == "table" and (not v.RAPI) then
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

    -- Create unique version of `Util.print` with mod name binded
    wrapper.Util.print = Util.internal.make_print(env["!guid"])

    return wrapper
end


function public.auto(properties)
    properties = properties or {}

    local env = envy.getfenv(2)
    local wrapper = public.setup(env, properties.namespace)
    envy.import_all(env, wrapper)

    -- Save mod ENV and properties for calling again on RAPI hotload
    __auto_setups[env] = properties

    -- Override default `print`, `type`, and `tostring` with Util's versions
    if not env.lua_print then
        env.lua_print       = env.print
        env.lua_type        = env.type
        env.lua_tostring    = env.tostring
    end
    env.print       = wrapper.Util.print
    env.type        = wrapper.Util.type
    env.tostring    = wrapper.Util.tostring

    -- Add Math functions to `math`
    for k, v in pairs(Math) do
        if k ~= "internal" then
            env.math[k] = v
        end
    end
    
    local namespace = properties.namespace or env["!guid"]
    run_clear_namespace_functions(namespace)    -- in Internal.lua

    -- Autoregister to Language
    if Language then Language.register_autoload(env) end
end


-- Reimport class tables to mods
-- that called .auto() on RAPI hotload
run_on_hotload(function()
    for env, t in pairs(__auto_setups) do
        local wrapper = public.setup(env, t.namespace)
        envy.import_all(env, wrapper)

        -- Override default `print`, `type`, and `tostring` with Util's versions
        env.print       = wrapper.Util.print
        env.type        = wrapper.Util.type
        env.tostring    = wrapper.Util.tostring
    end
end)