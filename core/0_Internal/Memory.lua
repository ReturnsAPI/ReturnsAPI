-- Memory

Memory = new_class()

run_once(function()
    __memory_hook_bank = {}
    __memory_hook_mid_bank = {}
end)



-- ========== Internal ==========

Memory.internal.remove_all = function(namespace)
    local namespace_bank = __memory_hook_bank[namespace]
    if namespace_bank then
        for name, hook_table in pairs(namespace_bank) do
            memory.dynamic_hook_disable(hook_table[1])
        end
        __memory_hook_bank[namespace] = nil
    end

    local namespace_bank = __memory_hook_mid_bank[namespace]
    if namespace_bank then
        for name, hook_table in pairs(namespace_bank) do
            memory.dynamic_hook_disable(hook_table[1])
        end
        __memory_hook_mid_bank[namespace] = nil
    end
end


-- Re-add all hooks on hotload
run_on_hotload(function()
    for namespace, namespace_bank in ipairs(__memory_hook_bank) do
        for name, hook_table in pairs(namespace_bank) do
            if type(hook_table[6][1]) == "function" then jit.off(hook_table[6][1]) end
            if type(hook_table[6][2]) == "function" then jit.off(hook_table[6][2]) end
            memory.dynamic_hook(namespace.."."..hook_table[2], hook_table[3], hook_table[4], hook_table[5], hook_table[6])
        end
    end

    for namespace, namespace_bank in ipairs(__memory_hook_mid_bank) do
        for name, hook_table in pairs(namespace_bank) do
            if type(hook_table[7]) == "function" then jit.off(hook_table[7]) end
            memory.dynamic_hook_mid(namespace.."."..hook_table[2], hook_table[3], hook_table[4], hook_table[5], hook_table[6], hook_table[7])
        end
    end
end)



-- ========== Static Methods ==========

--$static
--$param        name            | string    | The identifier to use.
--$param        ret_signature   | table     | The return signature.
--$param        signature       | table     | The function signature.
--$param        address         |           | The address of the function to hook.
--$param        function        | table     | A pair of Lua functions for pre and post hooking. <br>One or more can be `nil`.
--[[
Version of `memory.dynamic_hook` with the Lua functions `jit.off`ed.
]]
Memory.dynamic_hook = function(namespace, name, ret_signature, signature, address, functions)
    if not __memory_hook_bank[namespace] then __memory_hook_bank[namespace] = {} end

    -- "Override" old hook with same name
    local old_hook = __memory_hook_bank[namespace][name]
    if old_hook then
        memory.dynamic_hook_disable(old_hook[1])
    end

    if type(functions[1]) == "function" then jit.off(functions[1]) end
    if type(functions[2]) == "function" then jit.off(functions[2]) end
    local hook = memory.dynamic_hook(namespace.."."..name, ret_signature, signature, address, functions)
    memory.dynamic_hook_enable(hook)

    __memory_hook_bank[namespace][name] = {
        hook,
        name,
        ret_signature,
        signature,
        address,
        functions
    }

    -- Don't save RAPI internal hooks
    __memory_hook_bank[_ENV["!guid"]] = nil
end


--$static
--$param        name            | string    | The identifier to use.
--$param        registers       | table     | 
--$param        signature       | table     | 
--$param        arg4            |           | Should be `0`?
--$param        address         |           | The address of the function to hook.
--$param        function        | table     | The Lua function to hook with.
--[[
Version of `memory.dynamic_hook_mid` with the Lua function `jit.off`ed.
]]
Memory.dynamic_hook_mid = function(namespace, name, registers, signature, arg4, address, fn)
    if not __memory_hook_mid_bank[namespace] then __memory_hook_mid_bank[namespace] = {} end

    -- "Override" old hook with same name
    local old_hook = __memory_hook_mid_bank[namespace][name]
    if old_hook then
        memory.dynamic_hook_disable(old_hook[1])
    end

    if type(fn) == "function" then jit.off(fn) end
    local hook = memory.dynamic_hook_mid(namespace.."."..name, registers, signature, arg4, address, fn)
    memory.dynamic_hook_enable(hook)

    __memory_hook_mid_bank[namespace][name] = {
        hook,
        name,
        registers,
        signature,
        arg4,
        address,
        fn
    }

    -- Don't save RAPI internal hooks
    __memory_hook_mid_bank[_ENV["!guid"]] = nil
end



-- Public export
__class.Memory = Memory