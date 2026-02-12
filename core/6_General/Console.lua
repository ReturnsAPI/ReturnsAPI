-- Console
-- Port of Kris' EnableConsole

Console = new_class()

run_once(function()
    __console = nil
    __console_prev_open = false
    __console_fns = {}
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
--@param        signature       | string    | The signature of the argument. <br>Format: `"command_name (required) [optional] ..."`
--@optional     fn              | function  | The function to register. <br>The parameters for it is `args`. <br>If there is an existing function, <br>this will replace it.
--[[
Creates a new console command.
]]
Console.new = function(signature, fn)
    if not signature then log.error("Console.set: No signature provided", 2) end
    
    gm._mod_console_registerCommandSignature(signature)

    -- Store callback function
    if not fn then return end
    local name = signature
    local whitespace = string.find(signature, "%s")
	if whitespace then name = signature:sub(1, whitespace - 1) end
    __console_fns[name] = fn
end


--@static
--@param        message         | string    | The message to print to the console.
--@optional     col             | color     | The color of the message. <br>`Color.Console.BLUE` by default.
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



-- Public export
__class.Console = Console