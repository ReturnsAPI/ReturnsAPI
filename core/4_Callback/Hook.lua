-- Hook

--[[
Allows for calling a function before/after a game function.

**Callback arguments**
| - | - | -
`self`          | Instance, Struct, or nil  | The calling instance.
`other`         | Instance, Struct, or nil  | The "other" instance.
`result`        |                           | The post-hook return value (`nil` for pre-hooks). <br>Get/set using `result.value`. <br>Can only be set in post-hooks.
`args`          | table                     | The called game function's arguments. <br>Get/set using `args[i]`. <br>Can only be set in pre-hooks.

In a pre-hook, returning `false` will prevent normal execution of the game function (post-hooks will still run).
]]

Hook = new_class()

run_once(function()
    __pre_hooks         = {}
    __post_hooks        = {}
    __pre_hook_cache    = CallbackCache.new()
    __post_hook_cache   = CallbackCache.new()
    __hook_current_id   = -1    -- Shared by both __pre and __post
end)



-- ========== Internal ==========

Hook.internal.add_pre_hook = function(script)
    __pre_hooks[script] = true

    gm.pre_script_hook(script, function(self, other, result, args)
        -- Wrap args
        local _self     = Wrap.wrap(self)
        local _other    = Wrap.wrap(other)
        local _result   = { value = nil }
        local _args     = {}
        local _args_og  = {}
        for i, arg in ipairs(args) do
            local wrap = Wrap.wrap(arg.value)
            _args[i]    = wrap
            _args_og[i] = wrap
        end

        local pre_hook_return = true

        -- Call registered functions with wrapped args
        __pre_hook_cache:loop_and_call_functions(function(fn_table)
            local status, err = pcall(fn_table.fn, _self, _other, _result, _args)
            if not status then
                if (err == nil)
                or (err == "C++ exception") then err = "GameMaker error (see above)" end
                log.warning("\n"..fn_table.namespace..": Pre-hook (ID '"..fn_table.id.."') of function '"..(gm.constants_type_sorted["script"][script] or gm.constants_type_sorted["gml_script"][script] or script).."' failed to execute fully.\n"..err)
            else
                -- Allow `return false` to prevent normal function execution
                if err == false then pre_hook_return = false end
            end
        end, script)

        -- Args modification
        for i, arg in ipairs(_args) do
            if arg ~= _args_og[i] then
                args[i].value = Wrap.unwrap(arg)
            end
        end

        return pre_hook_return
    end)
end


Hook.internal.add_post_hook = function(script)
    __post_hooks[script] = true

    gm.post_script_hook(script, function(self, other, result, args)
        -- Wrap args
        local _self     = Wrap.wrap(self)
        local _other    = Wrap.wrap(other)
        local _result   = { value = Wrap.wrap(result.value) }   -- Allow detecting modification
        local _result_og = _result.value
        local _args     = {}
        for i, arg in ipairs(args) do
            _args[i] = Wrap.wrap(arg.value)
        end

        -- Call registered functions with wrapped args
        __post_hook_cache:loop_and_call_functions(function(fn_table)
            local status, err = pcall(fn_table.fn, _self, _other, _result, _args)
            if not status then
                if (err == nil)
                or (err == "C++ exception") then err = "GameMaker error (see above)" end
                log.warning("\n"..fn_table.namespace..": post-hook (ID '"..fn_table.id.."') of function '"..(gm.constants_type_sorted["script"][script] or gm.constants_type_sorted["gml_script"][script] or script).."' failed to execute fully.\n"..err)
            end
        end, script)

        -- Result modification
        if _result.value ~= _result_og then
            result.value = Wrap.unwrap(_result.value)
        end
    end)
end


Hook.internal.readd_hooks = function()
    for script, _ in pairs(__pre_hooks) do
        Hook.internal.add_pre_hook(script)
    end
    for script, _ in pairs(__post_hooks) do
        Hook.internal.add_post_hook(script)
    end
end
table.insert(_rapi_initialize, Hook.internal.readd_hooks)



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       number
--@param        script      | number    | The game function to hook. <br>(E.g., `gm.constants.instance_number`)
--@param        fn          | function  | The function to register. <br>The parameters for it are `self, other, result, args`.
--@overload
--@return       number
--@param        script      | number    | The game function to hook. <br>(E.g., `gm.constants.instance_number`)
--@param        priority    | number    | The priority of the function. <br>Higher values run before lower ones; can be negative. <br>`Callback.Priority.NORMAL` (`0`) by default.
--@param        fn          | function  | The function to register. <br>The parameters for it are `self, other, result, args`.
--[[
Registers a function under a game function pre-hook
Returns the unique ID of the registered function.

*Technical:* Uses `gm.pre_script_hook` internally, passing auto-wrapped values.
]]
Hook.add_pre = function(NAMESPACE, script, arg2, arg3)
    -- Throw error if not numerical ID
    if type(script) ~= "number" then
        log.error("Hook.pre: Invalid function", 2)
    end

    -- Throw error if not function
    if  (type(arg2) ~= "function")
    and (type(arg3) ~= "function") then
        log.error("Hook.pre: No function provided", 2)
    end

    -- Create actual hook
    if not __pre_hooks[script] then
        Hook.internal.add_pre_hook(script)
    end

    __hook_current_id = __hook_current_id + 1
    if type(arg2) == "function" then
        return __pre_hook_cache:add(arg2, NAMESPACE, 0, script, __hook_current_id)
    end
    return __pre_hook_cache:add(arg3, NAMESPACE, arg2, script, __hook_current_id)
end


--@static
--@return       number
--@param        script      | number    | The game function to hook. <br>(E.g., `gm.constants.instance_number`)
--@param        fn          | function  | The function to register. <br>The parameters for it are `self, other, result, args`.
--@overload
--@return       number
--@param        script      | number    | The game function to hook. <br>(E.g., `gm.constants.instance_number`)
--@param        priority    | number    | The priority of the function. <br>Higher values run before lower ones; can be negative. <br>`Callback.Priority.NORMAL` (`0`) by default.
--@param        fn          | function  | The function to register. <br>The parameters for it are `self, other, result, args`.
--[[
Registers a function under a game function post-hook
Returns the unique ID of the registered function.

*Technical:* Uses `gm.post_script_hook` internally, passing auto-wrapped values.
]]
Hook.add_post = function(NAMESPACE, script, arg2, arg3)
    -- Throw error if not numerical ID
    if type(script) ~= "number" then
        log.error("Hook.post: Invalid function", 2)
    end

    -- Throw error if not function
    if  (type(arg2) ~= "function")
    and (type(arg3) ~= "function") then
        log.error("Hook.post: No function provided", 2)
    end

    -- Create actual hook
    if not __post_hooks[script] then
        Hook.internal.add_post_hook(script)
    end

    __hook_current_id = __hook_current_id + 1
    if type(arg2) == "function" then
        return __post_hook_cache:add(arg2, NAMESPACE, 0, script, __hook_current_id)
    end
    return __post_hook_cache:add(arg3, NAMESPACE, arg2, script, __hook_current_id)
end


--@static
--@return       function
--@param        id          | number    | The unique ID of the registered function to remove.
--[[
Removes and returns a registered hook function.
The ID is the one from @link {`Hook.add_pre` | Hook#add_pre} / @link {`Hook.add_post` | Hook#add_post}.
]]
Hook.remove = function(id)
    return __pre_hook_cache:remove(id)
        or __post_hook_cache:remove(id)
end


--@static
--[[
Removes all registered hook functions from your namespace.

Automatically called when you hotload your mod.
]]
Hook.remove_all = function(NAMESPACE)
    __pre_hook_cache:remove_all(NAMESPACE)
    __post_hook_cache:remove_all(NAMESPACE)
end
table.insert(_clear_namespace_functions, Hook.remove_all)



__class.Hook = Hook