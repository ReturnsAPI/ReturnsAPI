-- Console

---@class Console
Console = new_class()
C.Console = Console

run_on_initial_load(function()
    P.console = nil
    P.console_prev_open = false

    ---@type table<string, true> List of console command names in use; populated by vanilla ones to begin.
    P.console_commands = {
        build_id   = true,
        toggle_hud = true,
        iphost     = true,
        ipconnect  = true,
    }
    P.console_fns  = {} ---@type table<string, function>
    P.console_help = {} ---@type table<string, table> Format: `["command"] = {description = "This is a command.", args = { ... }}`
end)

local console          = P.console
local console_commands = P.console_commands
local console_fns      = P.console_fns
local console_help     = P.console_help

local settings

local type         = type
local tostring     = tostring
local tonumber     = tonumber
local table_insert = table.insert
local table_remove = table.remove
local table_sort   = table.sort
local gm           = gm
local to_bool      = Util.bool


-- ========== Internal ==========

-- Create `oConsole` if it does not exist
if gm.instance_number(gm.constants.oConsole) == 0 then
	P.console = gm.instance_create_depth(0, 0, -100000001, gm.constants.oConsole)
    console = P.console
end

-- Log command usage in chat during online multiplayer
local log_command_locally = function(name, input)
    local str = "<w>"..name.."</c> used the command '<y>"..input.."</c>'"
    gm.chat_add_message(Struct.new(gm.constants.ChatMessage, str))
end

run_on_initialize(function()
    local file = TOML.new(RAPI_NAMESPACE)
    settings = file:read() or {}

    if settings.simplerConsoleBind == nil then settings.simplerConsoleBind = true end

    -- Add toggle to disable online button blocking
    -- TODO
    -- local options = ModOptions.new(RAPI_NAMESPACE)
    -- local checkbox = options:add_checkbox("simplerConsoleBind")
    -- checkbox:add_getter(function()
    --     return settings.simplerConsoleBind
    -- end)
    -- checkbox:add_setter(function(value)
    --     settings.simplerConsoleBind = value
    --     file:write(settings)
    -- end)

    -- Command chat logging sync
    -- TODO
    -- packet_syncConsole = Packet.new(RAPI_NAMESPACE, "syncConsole")
    -- packet_syncConsole:set_serializers(
    --     function(buffer, name, input)
    --         buffer:write_string(name)
    --         buffer:write_string(input)
    --     end,

    --     function(buffer, player)
    --         log_command_locally(buffer:read_string(), buffer:read_string())
    --     end
    -- )
end)


-- ========== Static Methods ==========

--[[
Creates a new console command.

--@ptable

E.g.,
```lua
Console.new{
    "my_command (some_parameter) [some_optional]",
    {
        "Does a thing.",
        {"(some_parameter)", "number", "Some numerical value."},
        {"[some_optional]",  "string", "Some optional string value."},
    },
    function(args)
        if #args < 1 then
            Console.print("Enter a valid number.")
            return
        end

        -- Do something
        -- ...
    end
}
```
]]
---@param data table A table containing data about the command to add. <br>The signature should have the format `"command_name (required) [optional] ..."` <br>See example below.
Console.new = function(data)
    if type(data) ~= "table" then throw("Data must be provided as a table") end

    local signature, fn, help

    for _, d in ipairs(data) do
        local  type_d =  type(d)
        if     type_d == "string"   then signature = d
        elseif type_d == "function" then fn = d
        elseif type_d == "table"    then
            -- `help` command data
            local t = {args = {}}

            for __, a in ipairs(d) do
                local  type_a =  type(a)
                if     type_a == "string" then t.description = a
                elseif type_a == "table"  then table_insert(t.args, a)
                end
            end

            if not t.description then
                throw("`help` data is missing description")
            end
            help = t
        end
    end

    if not signature then throw("No signature provided") end
    
    gm._mod_console_registerCommandSignature(signature)

    -- Get command name
    local name = signature
    local whitespace = string.find(signature, "%s")
	if whitespace then name = signature:sub(1, whitespace - 1) end
    
    -- Store command data
    console_commands[name] = true
    console_fns[name]      = fn
    console_help[name]     = help
end

--[[
Prints a message to the console.
]]
---@param message string The message to print to the console.
---@param col? number The color of the message. <br>@link {`Color.Console.BLUE` | Color#Console} by default.
Console.print = function(message, col)
    if not message then throw("No message provided") end
    if col and type(col) ~= "number" then throw("Invalid col argument") end
    gm.console_add_message(tostring(message), col or Color.Console.BLUE, 0)
end


-- ========== Hooks ==========

-- Change console bind to just "`"
gm.post_code_execute("gml_Object_oConsole_Step_1", function(self, other)
    if not settings
    or not settings.simplerConsoleBind then return end

    local open = console.open

    -- "`" is already set by the game to close the console if open
    if  to_bool(gm.keyboard_check_pressed(192))
    and (P.console_prev_open == open) then
        console.set_visible(self, other, true)
    end

    P.console_prev_open = open
end)

Callback.add(RAPI_NAMESPACE, Callback.CONSOLE_ON_COMMAND, Callback.internal.FIRST, function(input)
    local cmd, i = {}, 1
    for split in string.gmatch(input, "[^%s]+") do
        cmd[i] = split
        i = i + 1
    end

    local fn = console_fns[cmd[1]:lower()]
    if not fn then return end

    -- Remove command name
    table_remove(cmd, 1)

    -- Convert non-string arguments to non-strings
    for i, arg in ipairs(cmd) do
        local num = tonumber(arg)
        if     num            then cmd[i] = num
        elseif arg == "true"  then cmd[i] = true
        elseif arg == "false" then cmd[i] = false
        end
    end

    -- Log usage in chat in online multiplayer
    -- TODO
    -- if Net.online then
    --     local name = "Player"
    --     local p = Player.get_local()
    --     if p ~= Instance.INVALID then name = p.user_name end

    --     log_command_locally(name, input)
    --     packet_syncConsole:send_to_all(name, input)
    -- end

    fn(cmd)
end)


-- ========== Vanilla and RAPI Built-in ==========

console_help["build_id"] = {
    description = "Display the current build information of the game.",
    args = {}
}

console_help["toggle_hud"] = {
    description = "Toggle the hud. \nCan only be called during a run.",
    args = {}
}

console_help["iphost"] = {
    description = "Open a new online lobby without Steam.",
    args = {
        {"(port)", "number", "The port to host on."},
    }
}

console_help["ipconnect"] = {
    description = "Directly connect to an online lobby via IP.",
    args = {
        {"(ip)",   "number", "The IP address of the host to connect to."},
        {"(port)", "number", "The port to connect to."},
    }
}

Console.new{
    "help (command)",
    {
        "Display usage information for a command.",
        {"(command)", "string", "The command to get help for."},
    },
    function(args)
        if #args < 1 then
            Console.print("Enter a valid command. \nType <y>list</c> to display valid commands.")
            return
        end

        if not console_commands[args[1]] then
            Console.print("'"..args[1].."' is not a known command. \nType <y>list</c> to display valid commands.")
            return
        end

        local help = console_help[args[1]]

        if not help then
            Console.print("No help information found.")
            return
        end

        local str = help.description
        if #help.args > 0 then
            for _, arg in ipairs(help.args) do
                local name  = string.pad_right_to_width(arg[1], 120).." "
                local _type = string.pad_right_to_width(arg[2], 80).." "
                local desc  = tostring(arg[3])
                str = str.."\n"..name.._type..desc
            end
        end
        Console.print(str)
    end
}

Console.new{
    "list",
    {
        "Display a list of all commands in alphabetical order.",
    },
    function(args)
        -- Sort in alphabetical order
        local t, i = {}, 1
        for _, cmd in ipairs(List.wrap(console.commands)) do
            t[i] = cmd
            i = i + 1
        end
        table_sort(t, function(a, b) return a < b end)

        -- Rearrange into 20 rows
        local rows = {}
        local row_count = 20
        for i, cmd in ipairs(t) do
            -- Create row if it does not exist, and insert `cmd`
            local row = ((i - 1) % row_count) + 1
            rows[row] = rows[row] or {}
            table_insert(rows[row], cmd)
        end

        -- Format and print
        local str = "Type <y>help (command)</c> for more information on a command.\n"
        for i, row in ipairs(rows) do
            local line = ""

            for j, cmd in ipairs(row) do
                local name = string.pad_right_to_width(cmd, 120)

                if j > 1 then line = line.."| " end
                line = line.."<y>"..name.."</c>".." "
            end

            str = str.."\n"..line
        end
        Console.print(str)
    end
}

Console.new{
    "clear",
    {
        "Clear console history.",
    },
    function(args)
        List.wrap(console.history):clear()
    end
}