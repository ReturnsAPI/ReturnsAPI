-- Enable console

if gm.instance_number(gm.constants.oConsole) == 0 then
	gm.instance_create_depth(0, 0, -100000001, gm.constants.oConsole)
end