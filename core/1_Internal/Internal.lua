-- Internal

-- Utility functions for RAPI

function new_class()
    return {
        internal = {}
    }
end


function setmetatable_gc(t, mt)
    -- `setmetatable` but with `__gc` metamethod enabled
    local prox = newproxy(true)
    getmetatable(prox).__gc = function() mt.__gc(t) end
    t[prox] = true
    return setmetatable(t, mt)
end


function print2(text)
    print(text)
end


-- Extend gmf
gmf.rvalue_new_object = function (obj)
	local rvalue = ffi.new("struct RValue")
	rvalue.type = 6
    rvalue.yy_object_base = obj
	return rvalue
end

gmf.rvalue_new_auto = function (val)
    local _type = type(val)
    if _type == "number" then return gmf.rvalue_new(val) end
    if _type == "string" then return gmf.rvalue_new_string(val) end
    return val
end


if __ref_list then
    -- clear it when hot reloading, this will garbage-collect all the old structs
    __ref_list:destroy()
end
__ref_list = nil    -- Created in main.lua after loading core


-- -- The Gamemaker garbage collector frees anything that doesn't appear to be used.
-- -- Lua variables do not count as references, so this DS list is used to prevent unreferenced structs and other objects from disappearing
-- if __ref_list then
--     -- clear it when hot reloading, this will garbage-collect all the old structs
--     gm.ds_list_destroy(__ref_list)
-- end
-- __ref_list = gm.ds_list_create()

-- function add_to_ref_list(thing)
--     gm.ds_list_add(__ref_list, thing)
-- end

-- function remove_from_ref_list(thing)
--     gm.ds_list_delete(__ref_list, gm.ds_list_find_index(__ref_list, thing))
-- end

-- local id_count = 0
-- local id_to_func = {}

-- local STRUCT_VARIABLE_NAME = "__id"
-- local STRUCT_VARIABLE_HASH = gm.variable_get_hash(STRUCT_VARIABLE_NAME)

-- --- this function takes a lua function and uses black magic to wrap it in a CScriptRef which you can give to things that accept a gamemaker function
-- function bind_lua_to_cscriptref(func)
--     local struct = gm.struct_create()
--     gm.variable_struct_set(struct, STRUCT_VARIABLE_NAME, id_count)

--     id_to_func[id_count] = func
--     id_count = id_count + 1
--     -- bind a struct to a dummy function, so the struct is the self when this CScriptRef is executed
--     local method = gm.method(struct, gm.constants.function_dummy)

--     add_to_ref_list(method)

--     return method
-- end

-- -- LIMITATIONS:
-- -- * If `method` is called by game code against your bound CScriptRef, then the `self` argument will no longer be the custom struct, therefore stopping it from being recognized by the hook
-- -- * If the given function call relies on accessing `self` to be useful, then it likely won't be useful from this context

-- memory.dynamic_hook("RAPI.function_dummy", "void*", {"YYObjectBase*", "void*", "RValue*", "int", "void*"}, gm.get_script_function_address(gm.constants.function_dummy),
--     -- pre hook
--     function(return_val, self, other, result, arg_count, args)
--         if gm.is_struct(self) then
--             local arg_count = arg_count:get()
--             local args_typed = ffi.cast("struct RValue**", args:get_address())

--             --local fn = id_to_func[gm.variable_struct_get(self, STRUCT_VARIABLE_NAME)]
--             local fn = id_to_func[gm.struct_get_from_hash(self, STRUCT_VARIABLE_HASH)]
--             if fn then
--                 local arg_table = {}
--                 for i=0, arg_count-1 do
--                     local arg, is_instance_id = rvalue_to_lua(args_typed[i])
--                     if is_instance_id then
--                         arg = Instance.wrap(arg)
--                     else
--                         arg = Wrap.wrap(arg)
--                     end
--                     table.insert(arg_table, arg)
--                 end
--                 local ret = fn(table.unpack(arg_table))
--                 if ret then result.value = ret end
--             end
--         end
--     end,
--     -- post hook
--     nil
-- )
