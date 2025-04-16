-- Memory

Memory = {}



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
Memory.dynamic_hook = function(name, ret_signature, signature, address, functions)
    if type(functions[1]) == "function" then jit.off(functions[1]) end
    if type(functions[2]) == "function" then jit.off(functions[2]) end
    memory.dynamic_hook(name, ret_signature, signature, address, functions)
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
Memory.dynamic_hook_mid = function(name, registers, signature, arg4, address, fn)
    if type(fn) == "function" then jit.off(fn) end
    memory.dynamic_hook_mid(name, registers, signature, arg4, address, fn)
end



-- Public export
__class.Memory = Memory