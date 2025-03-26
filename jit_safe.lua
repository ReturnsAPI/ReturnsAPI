-- JIT Safe

-- Disable JIT for all gmf
-- for k, v in pairs(gmf) do
--     if type(v) == "function" then jit.off(v) end
-- end

-- Manually reenable for safe ones
-- * A function is "unsafe" if it manages to call a hooked function, either directly or through a chain reaction
-- (e.g., `instance_create` is unsafe because creating an actor using it will call `callback_execute` on the C side, which is hooked
--  Meanwhile `callback_execute` itself is safe, since nobody calls it directly)
-- The "forbidden loop" is Lua FFI -> C -> Lua
local safe = {
    _mod_net_isOnline = true,
    _mod_net_isHost = true,
    _mod_net_isClient = true,

    callback_execute = true,   -- Apparently this is fine, since we don't call `callback_execute` directly
    __input_system_tick = true,

    item_give_internal = true, -- internal versions of these are also not called directly by us
    item_take_internal = true,
    apply_buff_internal = true,
    remove_buff_internal = true,

    array_create = true,
    array_get = true,
    array_set = true,
    array_length = true,
    array_push = true,
    array_pop = true,
    array_insert = true,
    array_delete = true,
    array_contains = true,
    array_sort = true,

    ds_list_create = true,
    ds_list_destroy = true,
    ds_list_find_value = true,
    ds_list_find_index = true,
    ds_list_set = true,
    ds_list_size = true,
    ds_list_add = true,
    ds_list_insert = true,
    ds_list_delete = true,
    ds_list_clear = true,
    ds_list_sort = true,

    variable_struct_get = true,
    variable_struct_set = true,
    variable_struct_get_names = true,

    instance_number = true,
    _mod_instance_number = true,
}
-- for _, v in ipairs(safe) do jit.on(v) end    -- TODO reenable when everything is fine

for k, v in pairs(gmf) do
    if type(v) == "function" and (not safe[k]) then jit.off(v) end
end