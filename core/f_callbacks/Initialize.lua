-- Initialize

---@class Initialize
Initialize = new_class()
C.Initialize = Initialize

run_on_initial_load(function()
    P.initialize_functions = CallbackTable.new()
    P.initialize_started   = false  -- `true` after initialization starts
    P.initialize_done      = false  -- `true` after initialization finishes
end)


-- ========== Private Methods ==========

---@param name string The name of the method. <br>Necessary for namespace-binded methods.
Initialize.internal.check_if_started = function(name)
    if P.initialize_started then return end
    throw("Cannot call method before vanilla content initialization has finished; try placing the call within 'Initialize.add()'", name, 4)
end

--[[
Removes all registered functions in the namespace.
]]
Initialize.internal.remove_all = function(NAMESPACE)
    P.initialize_functions:remove_all(NAMESPACE)

    -- Call hotloadable Initialize functions again (if initialization loop already ran)
    -- Do this after 1 frame though to allow `Initialize.add_hotloadable`s to run again first
    if not P.initialize_done then return end
    Alarm.add(RAPI_NAMESPACE, 1, function()
        local fn_table = P.initialize_functions
        for i = 1, #fn_table do
            local data = fn_table[i]
            local status, out = pcall(data.fn)
            if not status then
                if out == nil
                or out == "C++ exception" then
                    out = "GameMaker error (see above)"
                end
                log.warning("\n| "..data.namespace..": Error in initialize function (ID "..math.floor(data.id)..")\n| "..out)
            end
        end
        P.initialize_functions = CallbackTable.new()
    end)
end
run_on_import(Initialize.internal.remove_all)


-- ========== Static Methods ==========

--[[
Registers a function to run exactly once during ReturnsAPI's initialization loop. <br>
This happens after all vanilla content has loaded.
]]
---@param fn function The function to register.
Initialize.add = function(NAMESPACE, fn) end

--[[
Registers a function to run exactly once during ReturnsAPI's initialization loop. <br>
This happens after all vanilla content has loaded.

**Priority Convention** <br>
To allow for a decent amount of space between priorities, <br>
use the enum values in @link {`Callback.Priority` | Callback#Priority}. <br>
If you need to be more specific than that, try to keep a distance of at least `100`.
]]
---@param priority integer The priority of the function. <br>Higher values run before lower ones. <br>`0` by default.
---@param fn function The function to register.
Initialize.add = function(NAMESPACE, priority, fn)
    if P.initialize_done then return end

    local _type = type(priority)
    if _type == "function" then
        P.initialize_functions:add(priority, NAMESPACE)
    else
        if _type    ~= "number"   then throw("Priority should be a number", "add") end
        if type(fn) ~= "function" then throw("No function provided", "add") end
        P.initialize_functions:add(fn, NAMESPACE, priority)
    end
end

--[[
Variant of @link {`Initialize.add` | Initialize#add} that calls the function <br>
again when your mod is hotloaded after ReturnsAPI's initialization loop.
]]
---@param fn function The function to register.
Initialize.add_hotloadable = function(NAMESPACE, fn) end

--[[
Variant of @link {`Initialize.add` | Initialize#add} that calls the function <br>
again when your mod is hotloaded after ReturnsAPI's initialization loop.

**Priority Convention** <br>
To allow for a decent amount of space between priorities, <br>
use the enum values in @link {`Callback.Priority` | Callback#Priority}. <br>
If you need to be more specific than that, try to keep a distance of at least `100`.
]]
---@param priority integer The priority of the function. <br>Higher values run before lower ones. <br>`0` by default.
---@param fn function The function to register.
Initialize.add_hotloadable = function(NAMESPACE, priority, fn)
    local _type = type(priority)
    if _type == "function" then
        P.initialize_functions:add(priority, NAMESPACE)
    else
        if _type    ~= "number"   then throw("Priority should be a number", "add_hotloadable") end
        if type(fn) ~= "function" then throw("No function provided", "add_hotloadable") end
        P.initialize_functions:add(fn, NAMESPACE, priority)
    end
end

--[[
Returns `true` if ReturnsAPI's initialization loop has started. <br>
This happens after all vanilla content has loaded.
]]
---@return boolean
Initialize.has_started = function()
    return P.initialize_started
end

--@static
--@return   bool
--[[
Returns `true` if ReturnsAPI's initialization loop has finished.
]]
---@return boolean
Initialize.is_done = function()
    return P.initialize_done
end


-- ========== Hooks ==========

local hook
hook = gm.post_script_hook(gm.constants.__input_system_tick, function(self, other, result, args)
    P.initialize_started = true

    -- Run RAPI initialization functions
    if G.run_on_initialize then
        for _, fn in ipairs(G.run_on_initialize) do
            fn()
        end
    end

    -- Call registered functions
    -- Do not call them again on RAPI hotload
    if not P.initialize_done then
        local fn_table = P.initialize_functions
        for i = 1, #fn_table do
            local data = fn_table[i]
            local status, out = pcall(data.fn)
            if not status then
                if out == nil
                or out == "C++ exception" then
                    out = "GameMaker error (see above)"
                end
                log.warning("\n| "..data.namespace..": Error in initialize function (ID "..math.floor(data.id)..")\n| "..out)
            end
        end
        P.initialize_functions = CallbackTable.new()
    end

    P.initialize_done = true
    gm.hook_disable(hook)
end)