-- Memory

-- Calls hook but `jit.off`s the functions

Memory = {}

Memory.dynamic_hook = function(name, ret_signature, signature, address, functions)
    if type(functions[1]) == "function" then jit.off(functions[1]) end
    if type(functions[2]) == "function" then jit.off(functions[2]) end
    memory.dynamic_hook(name, ret_signature, signature, address, functions)
end

Memory.dynamic_hook_mid = function(name, register, signature, arg4, address, fn)
    if type(fn) == "function" then jit.off(fn) end
    memory.dynamic_hook_mid(name, register, signature, arg4, address, fn)
end