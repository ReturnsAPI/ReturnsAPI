-- Memory

-- Calls hook but `jit.off`s the functions

Memory = {}

Memory.dynamic_hook = function(name, ret_signature, signature, address, functions)
    if type(functions[1]) == "function" then jit.off(functions[1]) end
    if type(functions[2]) == "function" then jit.off(functions[2]) end
    memory.dynamic_hook(name, ret_signature, signature, address, functions)
end