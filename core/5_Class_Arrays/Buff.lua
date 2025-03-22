-- Buff

local rapi_name = class_gm_to_rapi["class_buff"]
Buff = __class[rapi_name]



-- ========== Static Methods ==========

Buff.new = function(namespace, identifier)
    Initialize.internal.check_if_done()
    if not identifier then log.error("No identifier provided", 2) end

    -- Return existing buff if found
    local buff = Buff.find(identifier, namespace)
    if buff then return buff end

    -- Create new
    -- TODO: Pass proper args for this
    buff = Buff.wrap(GM.buff_create(
        namespace,
        identifier
    ))

    -- Set default stack_number_col to pure white
    buff.stack_number_col = Array.new(1, Color.WHITE)

    return buff
end



-- ========== Instance Methods ==========

methods_class[rapi_name] = {

    show_properties = function(self)
        local array = Class.Buff:get(self.value)
        local str = ""
        for i, v in ipairs(array) do
            str = str.."\n"..Util.pad_string_right(Buff.Property[i - 1], 32)..tostring(v)
        end
        print(str)
    end

}



-- ========== Hooks ==========

-- Extend buff_stack if necessary

memory.dynamic_hook("RAPI.Buff.init_actor_default", "void*", {"CInstance*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.init_actor_default),
    -- Pre-hook
    {nil,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
        -- This is pretty bad ngl
        -- but also this only runs once per actor so whatever
        local array_i64 = Instance.wrap(self.id).buff_stack.value

        if array_i64 then
            local holder = RValue.new_holder(2)
            holder[0] = RValue.new(array_i64, RValue.Type.ARRAY)
            holder[1] = RValue.new(Global.count_buff)
            gmf.array_resize(RValue.new(0), nil, nil, 2, holder)
        end
    end}
)