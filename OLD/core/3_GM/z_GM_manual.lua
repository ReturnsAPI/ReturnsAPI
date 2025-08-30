-- Manually populate `__GM_function_cache` with specific wrap/unwrap
-- to achieve a higher level of performance for common builtin functions
-- than the automatic wrapping done in GM

-- Format:
-- key          function name
-- table[1]     `*.wrap` method for return value; `""` for no wrapping, and `false` for no return
-- table[2]     A table containing bools; table length is arg count
                -- `true`   - `Wrap.unwrap`
                -- `false`  - raw input
                -- `1`      - `Wrap.unwrap` (CInstance ver)


local funcs = {

    -- Globals
    variable_global_get     = {"Wrap",      {false}},               -- name
    variable_global_set     = {false,       {false, 1}},            -- name, value

    -- Instance
    instance_find           = {"Instance",  {true, false}},         -- object, index
    instance_exists         = {"",          {true}},                -- inst
    instance_create         = {"Instance",  {true, true, true}},    -- x, y, object
    instance_destroy        = {false,       {true}},                -- inst
    instance_number         = {"",          {true}},                -- object

}


-- Parser
for name, data in pairs(funcs) do
    local str = "__GM_function_cache[\""..name.."\"] = "

    -- Signature
    local args = ""
    for i, bool in ipairs(data[2]) do
        if i > 1 then args = args..", " end
        args = args.."arg"..i
    end
    str = str.."function("..args..")\n    "
        
    -- return
    local wrapped = false
    if data[1] then
        str = str.."return "
        if data[1] ~= "" then
            wrapped = true
            str = str..data[1]..".wrap("
        end
    end

    -- Function call
    str = str.."gm."..name.."("

    -- Arguments
    for i, bool in ipairs(data[2]) do
        if i > 1 then str = str..", " end
        if bool == 1 then   str = str.."Wrap.unwrap(arg"..i..", true)"
        elseif bool then    str = str.."Wrap.unwrap(arg"..i..")"
        else                str = str.."arg"..i
        end
    end

    -- Function call )
    str = str..")"

    -- return )
    if wrapped then str = str..")" end

    -- end
    str = str.."\nend"

    -- print(str)
    local fn = loadstring(str)
    envy.setfenv(fn, envy.getfenv())
    fn()


    -- Script
    -- Performance gain(?) is inconsistent so just skip
    -- else
    --     local arg_count = #data[2]
    --     local holder = "nil"

    --     if arg_count > 0 then
    --         -- Holder
    --         holder = "holder"
    --         str = str.."local holder = RValue.new_holder_scr("..arg_count..")"

    --         -- Arguments
    --         for i, bool in ipairs(data[2]) do
    --             str = str.."\n    holder["..(i - 1).."] = "
    --             if bool then    str = str.."RValue.from_wrapper(arg"..i..")"
    --             else            str = str.."RValue.new(arg"..i..")"
    --             end
    --         end
    --     end

    --     -- Function call
    --     str = str.."\n    local out = RValue.new(0)"
    --     str = str.."\n    gmf."..name.."(nil, nil, out, "..arg_count..", "..holder..")"

    --     -- return
    --     if data[1] then
    --         str = str.."\n    return RValue.to_wrapper(out)"
    --     end

    --     -- end
    --     str = str.."\nend"

    --     print(str)
    --     local fn = loadstring(str)
    --     envy.setfenv(fn, envy.getfenv())
    --     fn()
end