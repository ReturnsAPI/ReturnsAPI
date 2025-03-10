# shitty docs generator cause idk how ldoc works

"""
Types
--$constants                            Follow this up with --[[ ]]; one per line (<name> <value> - e.g., WHITE 0xffffff)
--$enum                                 Normally auto-finds, but if not, use $name and --[[ ]]
--$static
--$instance

Fields
--$name                                 Method name (auto-finds if not provided)
--$aref                                 Section link of wiki page (only needed if a static and instance have the same name)
--$return <return value(s)>             `nil` if not provided
--$param <name> | <type(s)> | <desc>
--$optional <name> | <type(s)> | <desc>

--[[ ]]                                 Method description

In any description,
$<text to display>, <section link>$     Link to another section/page of the wiki (e.g., `$some display text, Item#LootTag$`)"
"""

import os
from enum import Enum

wiki = "https://github.com/ReturnsAPI/ReturnsAPI/wiki"

class State(Enum):
    NONE        = 0
    CONSTANTS   = 1
    ENUM        = 2
    STATIC      = 3
    INSTANCE    = 4

def parse_line(line):
    global wiki
    line = line.split("$")
    for i in range(1, len(line), 2):
        parts = [part.strip() for part in line[i].split(",")]
        line[i] = f"[{parts[0]}]({wiki}/{parts[1]})"
    return "".join(line)


core_path = os.path.join(os.path.dirname(__file__), "core")
for directory in os.listdir(core_path):
    dir_path = core_path + "/" + directory
    for file in os.listdir(dir_path):
        if file.endswith(".lua"):
            file_path = dir_path + "/" + file
            class_name = file[:-4]

            state = State.NONE
            state_var = [0 for i in range(10)]

            constants = []
            enums = []
            static = []
            instance = []

            # Get file data
            path = os.path.join(os.path.dirname(__file__), file_path)
            with open(path, "r") as f:
                lines = f.readlines()


            # Read lines
            for l in lines:
                l = l.strip()
                
                # Check for doctype
                if      "--$constants" in l:            state = State.CONSTANTS
                elif    "--$enum" in l:                 state = State.ENUM
                elif    "--$static" in l.split():       state = State.STATIC
                elif    "--$instance" in l.split():     state = State.INSTANCE

                # Process doctype
                else:
                    match state:

                        case State.CONSTANTS:
                            if state_var[0] == 0: state_var[0] = ""

                            # Add values until closing ]] is reached
                            if "--[[" in l: pass
                            elif "]]" in l:
                                state = State.NONE
                                state_var = [0 for i in range(10)]
                            else:
                                l = l.split()
                                constants.append((l[0], l[1]))


                        case State.ENUM:
                            match state_var[0]:

                                # Search for enum name
                                case 0:
                                    if "--$name" in l:
                                        state_var[1] = class_name + "." + l[7:].strip()
                                    elif "--[[" in l:
                                        state_var[0] = 2
                                        state_var[2] = []
                                    else:
                                        if state_var[1] == 0:
                                            name = l.split()
                                            if len(name) > 0: name = name[0]
                                            if "." in name:
                                                state_var[1] = name
                                                state_var[2] = []
                                        state_var[0] = 1

                                # Add values until closing } is reached
                                case 1:
                                    if len(l) < 1: pass
                                    elif l[0] != "}":
                                        state_var[2].append(l)
                                    else:
                                        enums.append((state_var[1], state_var[2]))
                                        state = State.NONE
                                        state_var = [0 for i in range(10)]

                                # Add values until closing ]] is reached
                                case 2:
                                    if "]]" in l:
                                        enums.append((state_var[1], state_var[2], True))    # len 3 to mark this as --[[ ]]
                                        state = State.NONE
                                        state_var = [0 for i in range(10)]
                                    else:
                                        state_var[2].append(l.split())


                        case State.STATIC:
                            match state_var[0]:

                                # Docstring processing
                                case 0:
                                    if state_var[2] == 0: state_var[2] = "nil"
                                    if state_var[3] == 0: state_var[3] = []
                                    if state_var[4] == 0: state_var[4] = []

                                    if "--$name" in l:    # Optional, autofinds otherwise
                                        state_var[1] = class_name + "." + l[7:].strip()
                                    elif "--$return" in l:
                                        state_var[2] = l[9:].strip()
                                    elif "--$param" in l:
                                        line = [part.strip() for part in l[8:].split("|")]
                                        line[2] = parse_line(line[2])
                                        state_var[3].append(line)
                                    elif "--$optional" in l:
                                        line = [part.strip() for part in l[11:].split("|")]
                                        line[0] = "[" + line[0] + "]"
                                        line[2] = "*Optional.* " + parse_line(line[2])
                                        state_var[3].append(line)
                                    elif "--$aref" in l:
                                        state_var[5] = l[7:].strip()
                                    elif "--[[" in l: pass
                                    elif "]]" in l:
                                        state_var[0] = 1
                                    else:
                                        state_var[4].append(parse_line(l))

                                # Search for function name
                                case 1:
                                    if state_var[1] == 0:
                                        if "function" in l:
                                            state_var[1] = l.split()[0]
                                            static.append((state_var[1], state_var[2], state_var[3], state_var[4], state_var[5]))
                                            state = State.NONE
                                            state_var = [0 for i in range(10)]
                                    else:
                                        static.append((state_var[1], state_var[2], state_var[3], state_var[4], state_var[5]))
                                        state = State.NONE
                                        state_var = [0 for i in range(10)]


                        case State.INSTANCE:
                            match state_var[0]:

                                # Docstring processing
                                case 0:
                                    if state_var[2] == 0: state_var[2] = "nil"
                                    if state_var[3] == 0: state_var[3] = []
                                    if state_var[4] == 0: state_var[4] = []

                                    if "--$name" in l:    # Optional, autofinds otherwise
                                        state_var[1] = l[7:].strip()
                                    elif "--$return" in l:
                                        state_var[2] = l[9:].strip()
                                    elif "--$param" in l:
                                        line = [part.strip() for part in l[8:].split("|")]
                                        line[2] = parse_line(line[2])
                                        state_var[3].append(line)
                                    elif "--$optional" in l:
                                        line = [part.strip() for part in l[11:].split("|")]
                                        line[0] = "[" + line[0] + "]"
                                        line[2] = "*Optional.* " + parse_line(line[2])
                                        state_var[3].append(line)
                                    elif "--$aref" in l:
                                        state_var[5] = l[7:].strip()
                                    elif "--[[" in l: pass
                                    elif "]]" in l:
                                        state_var[0] = 1
                                    else:
                                        state_var[4].append(parse_line(l))

                                # Search for function name
                                case 1:
                                    if state_var[1] == 0:
                                        if "function" in l:
                                            state_var[1] = l.split()[0]
                                            instance.append((state_var[1], state_var[2], state_var[3], state_var[4], state_var[5]))
                                            state = State.NONE
                                            state_var = [0 for i in range(10)]
                                    else:
                                        instance.append((state_var[1], state_var[2], state_var[3], state_var[4], state_var[5]))
                                        state = State.NONE
                                        state_var = [0 for i in range(10)]


            # Format
            p = os.path.join(os.path.dirname(__file__), f"docs/{class_name}.txt")
            with open(p, "w") as f:

                # Index
                if len(constants) > 0:
                    f.write(f"* [**Constants**]({wiki}/{class_name}#constants)\n\n")
                if len(enums) > 0:
                    f.write(f"* [**Enums**]({wiki}/{class_name}#enums)\n")
                    for enum in enums:
                        f.write(f"  * [`{enum[0]}`]({wiki}/{class_name}#{enum[0].split(".")[1]})\n")
                    f.write("\n")
                if len(static) > 0:
                    f.write(f"* [**Static Methods**]({wiki}/{class_name}#static-methods)\n")
                    for s in static:
                        aref = s[0].split(".")[1]
                        if s[4] != 0: aref = s[4]
                        f.write(f"  * [`{s[0]}`]({wiki}/{class_name}#{aref})\n")
                    f.write("\n")
                if len(instance) > 0:
                    f.write(f"* [**Instance Methods**]({wiki}/{class_name}#instance-methods)\n")
                    for s in instance:
                        aref = s[0]
                        if s[4] != 0: aref = s[4]
                        f.write(f"  * [`{class_name[0].lower() + class_name[1:]}:{s[0]}`]({wiki}/{class_name}#{aref})\n")
                    f.write("\n")
                f.write("<br><br>\n\n")

                # Constants
                if len(constants) > 0:
                    f.write("---\n\n")
                    f.write("## Constants\n\n")
                    f.write("```lua\n")
                    spacesn = 0
                    for const in constants:
                        spacesn = max(len(const[0]), spacesn)
                    for const in constants:
                        spaces = "".join([" " for i in range(spacesn + 4 - len(const[0]))])
                        f.write(class_name + "." + const[0] + spaces + "= " + const[1] + "\n")
                    f.write("```\n\n")
                    f.write("<br><br>\n\n")

                # Enums
                if len(enums) > 0:
                    f.write("---\n\n")
                    f.write("## Enums\n\n")
                    for enum in enums:
                        f.write(f"<a name=\"{enum[0].split(".")[1]}\"></a>\n")
                        f.write("```lua\n")
                        f.write(enum[0] + " = {")
                        if len(enum) == 2:   # Standard
                            for l in enum[1]:
                                f.write("\n    " + l)
                        else:                   # --[[ ]]
                            spacesn = 0
                            for l in enum[1]:
                                spacesn = max(len(l[0]), spacesn)
                            for l in enum[1]:
                                spaces = "".join([" " for i in range(spacesn + 4 - len(l[0]))])
                                f.write("\n    " + l[0] + spaces + "= " + l[1])
                        f.write("\n}\n")
                        f.write("```\n\n")
                    f.write("<br><br>\n\n")

                # Static
                if len(static) > 0:
                    f.write("---\n\n")
                    f.write("## Static Methods\n\n")
                    for s in static:
                        aref = s[0].split(".")[1]
                        if s[4] != 0: aref = s[4]
                        f.write(f"<a name=\"{aref}\"></a>\n")
                        f.write("```lua\n")
                        args = ""
                        for arg in s[2]:
                            if args != "": args += ", "
                            args += arg[0]
                        f.write(f"{s[0]}({args}) -> {s[1]}\n")
                        f.write("```\n")
                        for l in s[3]:
                            f.write("\n" + l + "  ")
                        f.write("\n\n**Parameters**  ")
                        if len(s[2]) > 0:
                            f.write("\nParameter | Type | Description\n| - | - | -\n")
                            for arg in s[2]:
                                f.write(f"`{arg[0]}` | {arg[1]} | {arg[2]}\n")
                        else: f.write("\nNone\n")
                        f.write("\n<br><br>\n\n")

                # Instance
                if len(instance) > 0:
                    f.write("---\n\n")
                    f.write("## Instance Methods\n\n")
                    for s in instance:
                        aref = s[0]
                        if s[4] != 0: aref = s[4]
                        f.write(f"<a name=\"{aref}\"></a>\n")
                        f.write("```lua\n")
                        args = ""
                        for arg in s[2]:
                            if args != "": args += ", "
                            args += arg[0]
                        f.write(f"{class_name[0].lower() + class_name[1:]}:{s[0]}({args}) -> {s[1]}\n")
                        f.write("```\n")
                        for l in s[3]:
                            f.write("\n" + l + "  ")
                        f.write("\n\n**Parameters**  ")
                        if len(s[2]) > 0:
                            f.write("\nParameter | Type | Description\n| - | - | -\n")
                            for arg in s[2]:
                                f.write(f"`{arg[0]}` | {arg[1]} | {arg[2]}\n")
                        else: f.write("\nNone\n")
                        f.write("\n<br><br>\n\n")