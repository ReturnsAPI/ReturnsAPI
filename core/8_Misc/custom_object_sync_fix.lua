
-- packet ids used for instance serialization
local packet_ids = {
	[103] = true,
	[104] = true,
	[105] = true,
}

-- patch for the server messages that serialize instances to correctly use the custom object index instead of the raw object_index
memory.dynamic_hook("RAPI.Fix.server_message_send", "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.server_message_send),
    -- Pre-hook
    {function(ret_val, self, other, result, arg_count, args)
        local arg_count = arg_count:get()
        local args_typed = ffi.cast(__args_typed_scr, args:get_address())

		if packet_ids[tonumber(args_typed[1].i64)] then
			args_typed[2].value = Instance.wrap(args_typed[4].i32):get_object_index()
		end
    end,

    -- Post-hook
    nil}
)