-- ENVY

function public.setup(env)
    if env == nil then
        env = envy.getfenv(2)
    end

    local namespace = env["!guid"]

    local wrapper = {}
    for name, class_ref in pairs(class_refs) do
        local copy = {}
        for k, v in pairs(class_ref) do
            copy[k] = v

            -- Namespace binding
            if type(v) == "function" then
                -- local nparams = debug.getinfo(v).nparams
                if debug.getlocal(v, 1) == "namespace" then
                    copy[k] = function(namespace, ...)
                        v(namespace, ...)
                    end
                end
            end

        end
        wrapper[name] = copy
    end

    return wrapper
end


function public.auto()
    local env = envy.getfenv(2)
    local wrapper = public.setup(env)
    envy.import_all(env, wrapper)
end