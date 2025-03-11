-- Internal

-- Utility functions for RAPI

function userdata_type(userdata)
    if type(userdata) ~= "userdata" then return end
    return getmetatable(userdata).__name
end


function new_class()
    return {
        internal = {}
    }
end


-- Taken from ReturnOfModding-DebugToolkit
-- Returns `true` as a second return value if the RValue is an Instance ID
-- function rvalue_to_lua(rvalue)
--     local rvalue_type = rvalue.type
--     if      rvalue_type == 0 then -- real
--         return rvalue.value, 0
--     elseif  rvalue_type == 1 then -- string
--         return ffi.string(rvalue.ref_string.m_str), 1
--     elseif  rvalue_type == 2 then -- array
--         return rvalue.i64, 2
--     elseif  rvalue_type == 3 then -- ptr
--         return rvalue.i64, 3
--     elseif  rvalue_type == 5 then -- undefined
--         return nil, 5
--     elseif  rvalue_type == 6 then -- object
--         local yyobjectbase = rvalue.yy_object_base
--         if yyobjectbase.type == 1 then
--             return rvalue.cinstance
--         elseif yyobjectbase.type == 3 then
--             return rvalue.cscriptref
--         end
--         return yyobjectbase
--     elseif  rvalue_type == 7 then -- int32
--         return rvalue.i32
--     elseif  rvalue_type == 10 then -- int64
--         return rvalue.i64
--     elseif  rvalue_type == 13 then -- bool
--         local rvalue_value = rvalue.value
--         return rvalue_value ~= nil and rvalue_value ~= 0
--     elseif  rvalue_type == 15 then -- ref (cinstance id)
--         return rvalue.i32, true
--     else                       -- unset
--         return nil
--     end
-- end

-- function rvalue_to_lua(rvalue)
--     local rvalue_type = rvalue.type
--     if      rvalue_type == 0 then -- real
--         return rvalue.value
--     elseif  rvalue_type == 1 then -- string
--         return rvalue.ref_string.m_str, 1
--     elseif  rvalue_type == 2 then -- array
--         return rvalue.i64
--     elseif  rvalue_type == 3 then -- ptr
--         return rvalue.i64 
--     elseif  rvalue_type == 5 then -- undefined
--         return nil
--     elseif  rvalue_type == 6 then -- object
--         local yyobjectbase = rvalue.yy_object_base
--         if yyobjectbase.type == 1 then
--             return rvalue.cinstance 
--         elseif yyobjectbase.type == 3 then
--             return rvalue.cscriptref
--         end
--         return yyobjectbase
--     elseif  rvalue_type == 7 then -- int32
--         return rvalue.i32
--     elseif  rvalue_type == 10 then -- int64
--         return rvalue.i64
--     elseif  rvalue_type == 13 then -- bool
--         local rvalue_value = rvalue.value
--         return rvalue_value ~= nil and rvalue_value ~= 0
--     elseif  rvalue_type == 15 then -- ref (cinstance id)
--         return rvalue.i32, true
--     else                       -- unset
--         return nil
--     end
-- end


-- The Gamemaker garbage collector frees anything that doesn't appear to be used.
-- Lua variables do not count as references, so this DS list is used to prevent unreferenced structs and other objects from disappearing
if __ref_list then
    -- clear it when hot reloading, this will garbage-collect all the old structs
    gm.ds_list_destroy(__ref_list)
end
__ref_list = gm.ds_list_create()

function add_to_ref_list(thing)
    gm.ds_list_add(__ref_list, thing)
end

local id_count = 0
local id_to_func = {}

local STRUCT_VARIABLE_NAME = "__id"
local STRUCT_VARIABLE_HASH = gm.variable_get_hash(STRUCT_VARIABLE_NAME)

--- this function takes a lua function and uses black magic to wrap it in a CScriptRef which you can give to things that accept a gamemaker function
function bind_lua_to_cscriptref(func)
    local struct = gm.struct_create()
    gm.variable_struct_set(struct, STRUCT_VARIABLE_NAME, id_count)

    id_to_func[id_count] = func
    id_count = id_count + 1
    -- bind a struct to a dummy function, so the struct is the self when this CScriptRef is executed
    local method = gm.method(struct, gm.constants.function_dummy)

    add_to_ref_list(method)

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

            --local fn = id_to_func[gm.variable_struct_get(self, STRUCT_VARIABLE_NAME)]
            local fn = id_to_func[gm.struct_get_from_hash(self, STRUCT_VARIABLE_HASH)]
            if fn then
                local arg_table = {}
                for i=0, arg_count-1 do
                    local arg, is_instance_id = rvalue_to_lua(args_typed[i])
                    if is_instance_id then
                        arg = Instance.wrap(arg)
                    else
                        arg = Wrap.wrap(arg)
                    end
                    table.insert(arg_table, arg)
                end
                local ret = fn(table.unpack(arg_table))
                if ret then result.value = ret end
            end
        end
    end,
    -- post hook
    nil
)
