
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
        local args_typed = ffi.cast("struct RValue**", args:get_address())

		if packet_ids[args_typed[2].value] then	-- this might be i64 idk
			args_typed[3].value = args_typed[5].value:get_object_index_self()	-- Instance.wrap this if needed
		end
    end,

    -- Post-hook
    nil}
)