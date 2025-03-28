-- Internal

__class = {}
__class_mt = {}
__class_mt_builder = {}

-- __ref_map created in Map.lua



-- Functions

function new_class()
    return {
        internal = {}
    }
end


function parse_optional_namespace(namespace, default_namespace)
    local is_specified = false
    if namespace then
        if namespace == "~" then namespace = default_namespace end
        is_specified = true
    else namespace = default_namespace
    end
    return namespace, is_specified
end


-- TODO convert to gmf usage (maybe)

if not __bind_id_count then __bind_id_count = 0 end     -- Preserve on hotload
if not __bind_id_to_func then __bind_id_to_func = {} end

local STRUCT_VARIABLE_NAME = "__id"
local STRUCT_VARIABLE_HASH = gm.variable_get_hash(STRUCT_VARIABLE_NAME)

--- this function takes a lua function and uses black magic to wrap it in a CScriptRef which you can give to things that accept a gamemaker function
function bind_lua_to_cscriptref(func)
    local struct = gm.struct_create()
    gm.variable_struct_set(struct, STRUCT_VARIABLE_NAME, __bind_id_count)

    __bind_id_to_func[__bind_id_count] = func
    __bind_id_count = __bind_id_count + 1
    -- bind a struct to a dummy function, so the struct is the self when this CScriptRef is executed
    local method = gm.method(struct, gm.constants.function_dummy)

    -- add_to_ref_list(method)
    __ref_map:set(method, true)

    return method
end

-- LIMITATIONS:
-- * If `method` is called by game code against your bound CScriptRef, then the `self` argument will no longer be the custom struct, therefore stopping it from being recognized by the hook
-- * If the given function call relies on accessing `self` to be useful, then it likely won't be useful from this context

memory.dynamic_hook("RAPI.function_dummy", "void*", {"YYObjectBase*", "void*", "RValue*", "int", "void*"}, gm.get_script_function_address(gm.constants.function_dummy),
    -- pre hook
    function(return_val, self, other, result, arg_count, args)
        if gm.is_struct(self) then
            local arg_count = arg_count:get()
            local args_typed = ffi.cast("struct RValue**", args:get_address())

            --local fn = __bind_id_to_func[gm.variable_struct_get(self, STRUCT_VARIABLE_NAME)]
            local fn = __bind_id_to_func[gm.struct_get_from_hash(self, STRUCT_VARIABLE_HASH)]
            if fn then
                local arg_table = {}
                for i=0, arg_count-1 do
                    -- local arg, is_instance_id = rvalue_to_lua(args_typed[i])
                    -- if is_instance_id then
                    --     arg = Instance.wrap(arg)
                    -- else
                    --     arg = Wrap.wrap(arg)
                    -- end
                    -- table.insert(arg_table, arg)

                    table.insert(arg_table, RValue.to_wrapper(args_typed[i]))
                end
                local ret = fn(table.unpack(arg_table))
                if ret then result.value = ret end  -- What's the point of this exactly?
            end
        end
    end,
    -- post hook
    nil
)