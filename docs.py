# shitty docs generator cause idk how ldoc works

import os
from enum import Enum

wiki = "https://github.com/ReturnsAPI/ReturnsAPI/wiki"

class State(Enum):
    NONE        = 0
    ENUM        = 1
    STATIC      = 2
    INSTANCE    = 3


state = State.NONE
state_var = [0 for i in range(10)]

enums = []
static = []


class_name = "Item"

# Get file data
path = os.path.join(os.path.dirname(__file__), f"core/4_Class_Arrays/{class_name}_docs_test.lua")
with open(path, "r") as f:
    lines = f.readlines()


# Read lines
for l in lines:
    l = l.strip()
    
    # Check for keyword
    if      "$enum" in l:       state = State.ENUM
    elif    "$static" in l:     state = State.STATIC

    # Process keyword
    else:
        match state:

            case State.ENUM:
                match state_var[0]:

                    # Search for enum name
                    case 0:
                        name = l.split(" ")
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


            case State.STATIC:
                match state_var[0]:

                    # Docstring processing
                    case 0:
                        if state_var[3] == 0: state_var[3] = []
                        if state_var[4] == 0: state_var[4] = []

                        if "$name" in l:    # Optional, autofinds otherwise
                            state_var[1] = class_name + "." + l[8:].strip()
                        elif "$return" in l:
                            state_var[2] = l[10:].strip()
                        elif "$param" in l:
                            line = [part.strip() for part in l[9:].split("|")]
                            state_var[3].append(line)
                        elif "$optional" in l:
                            line = [part.strip() for part in l[12:].split("|")]
                            line[0] = "[" + line[0] + "]"
                            line[2] = "*Optional.* " + line[2]
                            state_var[3].append(line)
                        elif "--[[" in l: pass
                        elif "]]--" in l:
                            state_var[0] = 1
                        else:
                            state_var[4].append(l)

                    # Search for function name
                    case 1:
                        if state_var[1] == 0:
                            if "function" in l:
                                state_var[1] = l.split(" ")[0]
                                static.append((state_var[1], state_var[2], state_var[3], state_var[4]))
                                state = State.NONE
                                state_var = [0 for i in range(10)]
                        else:
                            static.append((state_var[1], state_var[2], state_var[3], state_var[4]))
                            state = State.NONE
                            state_var = [0 for i in range(10)]


            case State.INSTANCE:
                pass


# Format
p = os.path.join(os.path.dirname(__file__), f"docs/{class_name}.txt")
with open(p, "w") as f:

    # Index
    f.write(f"* [**Enums**]({wiki}/{class_name}#Enums)\n")
    for enum in enums:
        f.write(f"  * [`{enum[0]}`]({wiki}/{class_name}#{enum[0].split(".")[1]})\n")
    f.write("\n<br><br>\n\n---\n\n")

    # Enums
    f.write("## Enums\n\n")
    for enum in enums:
        f.write(f"<a name=\"{enum[0].split(".")[1]}\"></a>\n")
        f.write("```lua\n")
        f.write(enum[0] + " = {")
        for l in enum[1]:
            f.write("\n    " + l)
        f.write("\n}\n")
        f.write("```\n\n")
    f.write("<br><br>\n\n---\n\n")

    # Static
    f.write("## Static Methods\n\n")
    print(static)
    for s in static:
        f.write(f"<a name=\"{s[0].split(".")[1]}\"></a>\n")
        f.write("```lua\n")
        args = ""
        for arg in s[2]:
            if args != "": args += ", "
            args += arg[0]
        f.write(f"{s[0]}({args}) -> {s[1]}\n")
        f.write("```\n")
        for l in s[3]:
            f.write("\n" + l + "  ")
        f.write("\n\n<br><br>\n\n")
    f.write("---\n\n")