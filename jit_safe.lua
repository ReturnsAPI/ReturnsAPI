-- JIT Safe

-- Disable JIT for all gmf
for k, v in pairs(gmf) do
    if type(v) == "function" then jit.off(v) end
end

-- Manually reenable for safe ones
-- * A function is "unsafe" if it manages to call a hooked function, either directly or through a chain reaction
-- (e.g., `instance_create` is unsafe because creating an actor using it will call `callback_execute` on the C side, which is hooked
--  Meanwhile `callback_execute` itself is safe, since nobody calls it directly)
-- The "forbidden loop" is Lua FFI -> C -> Lua
local safe = {
    gmf._mod_net_isOnline,
    gmf._mod_net_isHost,
    gmf._mod_net_isClient,

    gmf.callback_execute,   -- Apparently this is fine, since we don't call `callback_execute` directly

    gmf.item_give_internal, -- internal versions of these are also not called directly by us
    gmf.item_take_internal,

    gmf.array_create,
    gmf.array_get,
    gmf.array_set,
    gmf.array_length,
    gmf.array_push,
    gmf.array_pop,
    gmf.array_insert,
    gmf.array_delete,
    gmf.array_contains,
    gmf.array_sort,

    gmf.ds_list_create,
    gmf.ds_list_destroy,
    gmf.ds_list_find_value,
    gmf.ds_list_find_index,
    gmf.ds_list_set,
    gmf.ds_list_size,
    gmf.ds_list_add,
    gmf.ds_list_insert,
    gmf.ds_list_delete,
    gmf.ds_list_clear,
    gmf.ds_list_sort,

    gmf.variable_struct_get,
    gmf.variable_struct_set,
    gmf.variable_struct_get_names,
}
for _, v in ipairs(safe) do jit.on(v) end