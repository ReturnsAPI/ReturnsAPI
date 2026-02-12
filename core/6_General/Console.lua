-- Console
-- Port of Kris' EnableConsole

Console = new_class()

run_once(function()
    __console = nil
    __console_prev_open = false

    __console_commands = {
        build_id   = true,
        toggle_hud = true,
        iphost     = true,
        ipconnect  = true,
    }
    __console_fns = {}
    __console_help = {} -- ["command"] = {description = "This is a command.", args = { ... }}
end)

local settings



-- ========== Internal ==========

-- Create oConsole if existn't
if gm.instance_number(gm.constants.oConsole) == 0 then
	__console = gm.instance_create_depth(0, 0, -100000001, gm.constants.oConsole)
end


table.insert(_rapi_initialize, function()
    local file = TOML.new(RAPI_NAMESPACE)
    settings = file:read() or {}

    if settings.simplerConsoleBind == nil then settings.simplerConsoleBind = true end

    -- Add toggle to disable online button blocking
    local options = ModOptions.new(RAPI_NAMESPACE)
    local checkbox = options:add_checkbox("simplerConsoleBind")
    checkbox:add_getter(function()
        return settings.simplerConsoleBind
    end)
    checkbox:add_setter(function(value)
        settings.simplerConsoleBind = value
        file:write(settings)
    end)
end)



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@param        data            | table     | A table containing data about the command to add. <br>The signature should have the format `"command_name (required) [optional] ..."` <br>See example below.
--[[
Creates a new console command.

E.g.,
```lua
Console.new{
    "my_command (some_parameter) [some_optional]",
    {
        "Does a thing.",
        {"(some_parameter)", "number", "Some numerical value."},
        {"[some_optional]",  "string", "Some optional string value."},
    }
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
Console.new = function(data)
    local signature
    local fn
    local help

    if type(data) ~= "table" then log.error("Console.new: Data must be provided as a table", 2) end

    for _, d in ipairs(data) do
        local  type_d =  type(d)
        if     type_d == "string"   then signature = d
        elseif type_d == "function" then fn = d
        elseif type_d == "table"    then
            local t = {args = {}}

            for __, a in ipairs(d) do
                local  type_a =  type(a)
                if     type_a == "string" then t.description = a
                elseif type_a == "table"  then table.insert(t.args, a)
                end
            end

            if not t.description then
                log.error("Console.new: `help` data is missing description", 2)
            end

            help = t
        end
    end

    if not signature then log.error("Console.new: No signature provided", 2) end
    
    gm._mod_console_registerCommandSignature(signature)

    -- Get command name
    local name = signature
    local whitespace = string.find(signature, "%s")
	if whitespace then name = signature:sub(1, whitespace - 1) end
    
    -- Store command data
    __console_commands[name] = true
    __console_fns[name]      = fn
    __console_help[name]     = help
end


--@static
--@param        message         | string    | The message to print to the console.
--@optional     col             | color     | The color of the message. <br>@link {`Color.Console.BLUE` | Color#Console} by default.
--[[
Prints a message to the console.
]]
Console.print = function(message, col)
    if not message then log.error("Console.print: No message provided", 2) end
    gm.console_add_message(tostring(message), col or Color.Console.BLUE, 0)
end



-- ========== Hooks ==========

-- Change console bind to just "`"
Hook.add_post(RAPI_NAMESPACE, "gml_Object_oConsole_Step_1", function(self, other)
    if (not settings)
    or (not settings.simplerConsoleBind) then return end

    local open = __console.open

    -- "`" is already set by the game to close the console if open
    if  Util.bool(gm.keyboard_check_pressed(192))
    and (__console_prev_open == open) then
        __console.set_visible(self.value, other.value, true)
    end

    __console_prev_open = open
end)


Callback.add(RAPI_NAMESPACE, Callback.CONSOLE_ON_COMMAND, Callback.internal.FIRST, function(input)
    local cmd = {}
    for split in string.gmatch(input, "[^%s]+") do
        table.insert(cmd, split)
    end

    local fn = __console_fns[cmd[1]:lower()]
    if fn then
        table.remove(cmd, 1)
        fn(cmd)
    end
end)



-- ========== Built-in ==========

Console.new{
    "help (command)",
    {
        "Displays usage information for a command.",
        {"(command)", "string", "The command to get help for."},
    },
    function(args)
        if (#args < 1)
        or (not __console_commands[args[1]]) then
            Console.print("Enter a valid command.")
            return
        end

        local help = __console_help[args[1]]

        if not help then
            Console.print("No help information found.")
            return
        end

        local str = help.description
        if #help.args > 0 then
            for _, arg in ipairs(help.args) do
                local name  = Util.pad_string_right(arg[1], 24)
                local _type = Util.pad_string_right(arg[2], 16)
                local desc  = tostring(arg[3])
                str = str.."\n"..name.._type..desc
            end
        end
        Console.print(str)
    end
}


__console_help["build_id"] = {
    description = "Display the current build information of the game.",
    args = {}
}

__console_help["toggle_hud"] = {
    description = "Toggle the hud. \nCan only be called during a run.",
    args = {}
}

__console_help["iphost"] = {
    description = "Open a new online lobby without Steam.",
    args = {
        {"(port)", "number", "The port to host on."},
    }
}

__console_help["ipconnect"] = {
    description = "Directly connect to an online lobby via IP.",
    args = {
        {"(ip)",   "number", "The IP address of the host to connect to."},
        {"(port)", "number", "The port to connect to."},
    }
}



-- Public export
__class.Console = Console