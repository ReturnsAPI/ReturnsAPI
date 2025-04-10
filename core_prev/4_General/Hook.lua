-- Hook

-- if true then return end

Hook = new_class()

if not __hook_bank then __hook_bank = {} end    -- Preserve on hotload
if not __hook_id_counter then __hook_id_counter = 0 end
if not __hook_id_lookup then __hook_id_lookup = {} end



-- ========== Constants and Enums ==========

--$constants
--[[
PRE 0
POST 1
]]
Hook.PRE    = 0
Hook.POST   = 1

--$enum
Hook.Priority = ReadOnly.new({
    BEFORE  = 1000,
    AFTER   = -1000
})



-- ========== Static Methods ==========

--$static
--$return       number
--$param        script      | string    | The function to hook.
--$param        type        | number    | Either `Hook.PRE` or `Hook.POST`.
--$param        fn          | function  | The function to register. <br>The parameters for it are `self, other, result, args`.
--$optional     priority    | number    | The priority of the function. <br>Higher values run before lower ones; can be negative. <br>`0` by default.
--[[
description
]]
Hook.add = function(namespace, script, _type, fn, priority)
    -- Throw error if not numerical ID
    if type(script) ~= "string" then
        log.error("Hook.add: script should be a string", 2)
    end
    if not gm.constants[script] then
        log.error("Hook.add: script '"..script.."' does not exist", 2)
    end

    -- Throw error if _type is not 0 or 1
    if _type ~= Hook.PRE and _type ~= Hook.POST then
        log.error("Hook.add: type should be `Hook.PRE` or `Hook.POST`", 2)
    end

    -- Throw error if not function
    if type(fn) ~= "function" then
        log.error("Hook.add: No function provided", 2)
    end

    -- All hooks have the same priority (0) unless specified
    -- Higher numbers run before lower ones (can be negative)
    priority = priority or 0

    -- Create __hook_bank subtables if they do not exist
    -- Also hook the function
    if not __hook_bank[script] then __hook_bank[script] = {} end
    if not __hook_bank[script][_type] then
        __hook_bank[script][_type] = {priorities = {}}

        local hook_func = nil

        -- Builtin
        -- Script
        if GM.internal.builtin[script]
        or GM.internal.script[script] then
            local is_script = (GM.internal.script[script] ~= nil)

            hook_func = function(ret_val, self, other, result, arg_count, args)
                -- if is_script then
                --     result, self, other = self, other, result
                -- end

                local hbank_script = __hook_bank[script][_type]
                if #hbank_script.priorities <= 0 then return end

                -- Cast and wrap `self, other, result`
                local self_wrapped = nil
                local self_address = self:get_address()
                if self_address ~= 0 then
                    local self_cdata = ffi.cast("YYObjectBase*", self_address)
                    if self_cdata.type == 1 then
                        self_cdata = ffi.cast("CInstance*", self_address)
                        self_wrapped = Instance.wrap(self_cdata.id)
                    else self_wrapped = Struct.wrap_yyobjectbase(self_cdata)
                    end
                end

                local other_wrapped = nil
                local other_address = other:get_address()
                if other_address ~= 0 then
                    local other_cdata = ffi.cast("YYObjectBase*", other_address)
                    if other_cdata.type == 1 then
                        other_cdata = ffi.cast("CInstance*", other_address)
                        other_wrapped = Instance.wrap(other_cdata.id)
                    else other_wrapped = Struct.wrap_yyobjectbase(other_cdata)
                    end
                end

                local arg_count = arg_count:get()
                local args_typed = ffi.cast("struct RValue**", args:get_address())

                -- TODO fix this shit
                -- local result_wrapped = nil
                -- if _type == 1 then
                --     local result_address = result:get_address()
                --     print("result_address", result_address)
                --     if result_address ~= 0 then
                --         local result_cdata = ffi.cast("YYObjectBase*", result_address)
                --         print("result_cdata.type", result_cdata.type)
                --         if result_cdata.type == 1 then
                --             result_cdata = ffi.cast("CInstance*", result_address)
                --             result_wrapped = Instance.wrap(result_cdata.id)
                --         -- elseif result_cdata.type == 0 then
                --         --     result_wrapped = Struct.wrap_yyobjectbase(result_cdata)
                --         else
                --             result_wrapped = ffi.cast("struct RValue*", result_address)
                --             print("result_wrapped.value", result_wrapped.value)
                --             -- result_wrapped = RValue.to_wrapper(ffi.cast("struct RValue*", result_address))
                --         end
                --     end
                -- end

                -- Wrap `args`
                local wrapped_args = {}
                local wrapped_args_og = {}
                for i = 0, arg_count - 1 do
                    local arg = RValue.to_wrapper(args_typed[i])
                    table.insert(wrapped_args, arg)
                    table.insert(wrapped_args_og, arg)
                end

                -- Call functions
                local prehook_return = true
                for _, priority in ipairs(hbank_script.priorities) do
                    local hbank_priority = hbank_script[priority]

                    for _, fn_table in ipairs(hbank_priority) do
                        -- `return false` in fn skips normal script execution
                        local _return = fn_table.fn(self_wrapped, other_wrapped, result_wrapped, wrapped_args)
                        if _return == false then prehook_return = false end
                    end
                end

                -- Args modification
                for i = 0, arg_count - 1 do
                    if wrapped_args[i + 1] ~= wrapped_args_og[i + 1] then
                        args_typed[i] = RValue.from_wrapper(wrapped_args[i + 1])
                    end
                end
                -- if (_type == 1) and (result_wrapped ~= result_wrapped_og) then
                --     result_cdata.value = RValue.from_wrapper(result_wrapped)
                -- end
                
                return prehook_return
            end

        end

        -- PRE
        if _type == 0 then
            print("Hook: Added pre-hook for '"..script.."'")

            memory.dynamic_hook("RAPI.Hook.PRE."..script, "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants[script]),
                -- Pre-hook
                {hook_func,

                -- Post-hook
                nil}
            )

        -- POST
        elseif _type == 1 then
            print("Hook: Added post-hook for '"..script.."'")

            memory.dynamic_hook("RAPI.Hook.POST."..script, "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants[script]),
                -- Pre-hook
                {nil,

                -- Post-hook
                hook_func}
            )
        end
    end
    local hbank_script = __hook_bank[script][_type]
    if not hbank_script[priority] then
        hbank_script[priority] = {}
        table.insert(hbank_script.priorities, priority)
        table.sort(hbank_script.priorities, function(a, b) return a > b end)
    end

    -- Add to subtable
    __hook_id_counter = __hook_id_counter + 1

    local fn_table = {
        id          = __hook_id_counter,
        namespace   = namespace,
        fn          = fn,
        priority    = priority
    }
    local lookup_table = {script, _type, fn_table}
    __hook_id_lookup[__hook_id_counter] = lookup_table
    table.insert(__hook_bank[script][_type][priority], fn_table)

    return __hook_id_counter
end


--$static
--$param        id          | number    | The unique ID of the registered callback to remove.
--[[

]]
Hook.remove = function(id)
    local lookup_table = __hook_id_lookup[id]
    if not lookup_table then return end
    __hook_id_lookup[id] = nil

    local cbank_callback = __hook_bank[lookup_table[1]]
    for priority, cbank_priority in pairs(cbank_callback) do
        if type(priority) == "number" then
            for i, v in ipairs(cbank_priority) do
                if v == lookup_table[2] then
                    table.remove(cbank_priority, i)
                    break
                end
            end
            if #cbank_priority <= 0 then
                cbank_callback[priority] = nil
                Util.table_remove_value(cbank_callback.priorities, priority)
            end
        end
    end
end


--$static
--[[

]]
Hook.remove_all = function(namespace)
    for _, cbank_callback in pairs(__hook_bank) do
        for priority, cbank_priority in pairs(cbank_callback) do
            if type(priority) == "number" then
                for i = #cbank_priority, 1, -1 do
                    local fn_table = cbank_priority[i]
                    if fn_table.namespace == namespace then
                        __hook_id_lookup[fn_table.id] = nil
                        table.remove(cbank_priority, i)
                    end
                end
                if #cbank_priority <= 0 then
                    cbank_callback[priority] = nil
                    Util.table_remove_value(cbank_callback.priorities, priority)
                end
            end
        end
    end
end



__class.Hook = Hook