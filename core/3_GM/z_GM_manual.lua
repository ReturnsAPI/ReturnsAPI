-- Manually populate __GM_function_cache with specific amounts of wrap/unwrap
-- to achieve a higher level of performance for common functions than
-- the automatic wrapping done in GM

-- Format:
-- key          function name
-- table[1]     `*.wrap` method for return value; `""` for no wrapping, and `0` for no return
-- table[2]     A table containing bools; `true` for `Wrap.unwrap`, `false` for raw input; table length is arg count


local funcs = {

    -- Globals
    variable_global_get     = {"Wrap",      {false}},               -- name
    variable_global_set     = {0,           {false, true}},         -- name, value

    -- Instance
    instance_find           = {"Instance",  {true, false}},         -- object, index
    instance_exists         = {"",          {true}},                -- inst
    instance_create         = {"Instance",  {true, true, true}},    -- x, y, object
    instance_destroy        = {0,           {true}},                -- inst
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
    if data[1] ~= 0 then
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
        if bool then    str = str.."Wrap.unwrap(arg"..i..")"
        else            str = str.."arg"..i
        end
    end

    -- Function call )
    str = str..")"

    -- return )
    if wrapped then str = str..")" end

    -- end
    str = str.."\nend"

    print(str)
    local fn = loadstring(str)
    envy.setfenv(fn, envy.getfenv())
    fn()
end