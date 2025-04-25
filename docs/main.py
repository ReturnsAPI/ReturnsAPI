# ReturnsAPI doc comment parser

"""
General
-- @section  <name>                         Sets the current page section; remains this until changed later in the file
-- @link     {<name> | <url path>}          Link to another section/page of the wiki (e.g., @link {some display text | Item#LootTag})
                                            Can be placed within the text parameters of any other keyword
-- @image    <path>                         (Optional)  Display an image; path is relative to docs/out/images
--[[ ]]                                     Multiline text, used for method descriptions, etc.
                                            
Constants
-- @constants                               Denotes a set of constants

Enums
-- @enum                                    Denotes an enum; normally auto-finds, but use the keywords below if not
-- @name                                    (Optional)  The name of the enum; auto-prepended with class name (e.g., Class.<name>)

Methods
-- @static                                  Denotes a static method; normally auto-finds
-- @instance                                Denotes an instance method; normally auto-finds
-- @overload                                (Optional)  @name, @return, @param, and @optional keywords after this will be displayed separately
                                                        If @name is not specified, uses previous name
-- @name                                    (Optional)  The name of the method
-- @href     <#tag (w/o class name)>        (Optional)  Section link of wiki page (only needed if multiple methods have the same name)
-- @return   <return value(s)>              (Optional)  Takes the remainder of the line as the return value; "nil" if not provided
-- @param    <name> | <type(s)> | <desc>    (Optional)  A required parameter of the method
-- @optional <name> | <type(s)> | <desc>    (Optional)  An optional parameter of the method
-- @ptable                                  (Optional)  Display the parameter table at this position, allowing for text after it
"""



# ==================================================

import os
from pprint import pprint

from element_types import *

global WIKI; WIKI = "https://github.com/ReturnsAPI/ReturnsAPI/wiki"



def main():
    core_path = os.path.join(os.path.dirname(__file__), "../core")
    
    # Loop through all directories in `core`
    for dir in os.listdir(core_path):
        dir_path = os.path.join(core_path, dir)
        if os.path.isdir(dir_path):
            
            # Loop through all Lua files in directory
            for filename in os.listdir(dir_path):
                if filename.endswith(".lua"):
                    file_path = os.path.join(dir_path, filename)
                    parse_file(file_path, filename.split(".")[0])



def parse_file(file_path, filename):

    # Log current file
    print("Processing " + filename)


    # Get file data
    with open(file_path, "r") as f:
        lines = f.readlines()
        lines.append("\n")  # To force last block to
        lines.append("--")  # be added to blocks

    # Initialize variables
    blocks = []
    current_block = []
    in_multiline = False
    in_code = True

    # Loop through lines
    for line in lines:
        line = line.strip()
        
        if in_code:
            if line.startswith("--"):
                in_code = False
                if current_block:
                    # Remove trailing newlines from block
                    while current_block and (current_block[-1] == ""):
                        current_block.pop(-1)

                    blocks.append(current_block)
                    current_block = []

                # Start multiline
                if line.startswith("--[["):
                    in_multiline = True
                    line = "@mlstart"

                else:
                    line = line.lstrip("-")
            
            line = line.lstrip(" ")
            current_block.append(line)

        else:
            # Start multiline
            if line.startswith("--[["):
                in_multiline = True
                current_block.append("@mlstart")

            # Parse multiline content
            elif in_multiline:

                # End multiline
                if line.startswith("]]"):
                    in_multiline = False
                    current_block.append("@mlend")

                else:
                    current_block.append(line)

            # Standard comment
            elif line.startswith("--"):
                line = line.lstrip("- ")
                current_block.append(line)

            # End block
            else:
                in_code = True
                current_block.append(line)


    # Initialize variables
    docs = {
        "section"       : None,
        "sections"      : {
            None: []
        }
    }

    # Parse blocks
    for block in blocks:
        parse_block(block, docs)


    # Generate md files
    generate(docs, filename)



def parse_block(block, docs):

    # Initialize variables
    docs["element"] = None
    code = []


    # Loop through lines
    while len(block) > 0:
        line = block.pop(0)
        tokens = line.split()
    
        if len(tokens) <= 0:
            continue

        match tokens[0]:

            # Set current section; if empty, default to None
            case "@section":

                # Get section name
                tokens = line.split(None, 1)
                section_id = None
                if len(tokens) >= 2:
                    section_id = tokens[1]
                docs["section"] = section_id

                # Create new section list if existn't
                section = docs["sections"].get(section_id)
                if not section:
                    docs["sections"][section_id] = []


            # Parse text
            case "@mlstart":
                # Start new standalone text element
                # if not adding as part of another element
                if not docs["element"]:
                    docs["element"] = Text()
                
                docs["element"].text = parse_text(block, docs)


            # Start new constants
            case "@constants":
                docs["element"] = Constants()


            # Start new enum
            case "@enum":
                docs["element"] = Enum()


            # Start new static method
            case "@static":
                docs["element"] = Method()


            # Start new instance method
            case "@instance":
                docs["element"] = Method()
                docs["element"].is_instance = True


            # Start new signature for method
            case "@overload":
                signature = Signature()

                # Take name of previous signature by default
                signature.name = docs["element"].signatures[-1].name
                
                docs["element"].signatures.append(signature)


            # Set name; if empty, autofinds
            case "@name":
                _type = typeof(docs["element"])
                match _type:

                    case "Enum":
                        docs["element"].name = tokens[1]

                    case "Method":
                        docs["element"].signatures[-1].name = tokens[1]


            # Set href; if empty, autosets based on name
            case "@href":
                docs["element"].href = tokens[1]


            # Set return; if empty, will be `nil`
            case "@return":
                ret = line.split(None, 1)
                docs["element"].signatures[-1].ret = ret[1]


            # Add required parameter
            case "@param":
                parts = [p.strip() for p in line.split(None, 1)[1].split("|", 2)]
                param = Param(parts[0], parts[1], parse_line(parts[2]))
                docs["element"].signatures[-1].params.append(param)


            # Add optional parameter
            case "@optional":
                parts = [p.strip() for p in line.split(None, 1)[1].split("|", 2)]
                param = Param(parts[0], parts[1], parse_line(parts[2]))
                docs["element"].signatures[-1].optional.append(param)

            
            # Add code
            case _:
                code.append(line)


    # Autofind unset properties from code
    parse_code(code, docs)


    # Constants, Enum : Parse text into value pairs
    _type = typeof(docs["element"])
    if (_type == "Constants") or (_type == "Enum"):
        docs["element"].values = convert_text_to_pairs(docs["element"].text)


    # Add finalized element to section
    section_id = docs["section"]
    if docs["element"]:
        docs["sections"][section_id].append(docs["element"])



def parse_text(block, docs):
    text = []

    # Loop through lines
    while len(block) > 0:
        line = block.pop(0)
        parsed = parse_line(line)

        # End text
        if "@mlend" in parsed:
            return text

        # Add parsed line to element.text
        text.append(parsed)



def parse_line(line):
    parsed = ""

    tokens = line.split()
    while len(tokens) > 0:
        token = tokens.pop(0)

        if token.startswith("<br>"):
            parsed += "<br>"
            token = token[4:]

        match token:

            # Add link
            case "@link":
                
                # Join remaining tokens together
                remainder = " ".join(tokens).lstrip(" {")

                # Split by | and } to get three parts
                parts = [p.strip() for p in remainder.replace("}", "|").split("|")]

                # Add link-formatted part
                parsed += f"[{parts[0]}]({WIKI}/{parts[1]}) "

                # Place last part back into remaining tokens
                tokens = parts[2].strip().split()


            # Add image
            case "@image":
                pass

            
            # Add line to text
            case _:
                parsed += token + " "

    return parsed.strip()



def parse_code(code, docs):
    _type = typeof(docs["element"])
    match _type:
    
        case "Enum":

            # Name
            if not docs["element"].name:
                line = code[0]

                # Get first part of assignment (which has the name)
                name = line.split("=")[0].strip()
                if "." in name:
                    name = name.split(".")[1]

                docs["element"].name = name


            # href
            if not docs["element"].href:
                docs["element"].href = docs["element"].name

                
            # Set text to be code
            if not docs["element"].text:
                code.pop(0)
                code.pop()
                for line in code:
                    docs["element"].text.append(line)
                    if "}" in line:
                        break


        case "Method":
            if len(code) <= 0:
                return
            
            # Name
            line = code[0]

            # Get first part of assignment (which has the name)
            name = line.split("=")[0].strip()
            if "." in name:
                name = name.split(".")[1]

            # Set name for all unassigned signatures
            for signature in docs["element"].signatures:
                if not signature.name:
                    signature.name = name


            # href
            if not docs["element"].href:
                docs["element"].href = docs["element"].signatures[0].name



def convert_text_to_pairs(text):
    pairs = []

    for line in text:
        if ("function" not in line) and ("{" not in line) and ("}" not in line):
            
            # Split correctly
            pair = line.split()
            if "=" in line:
                pair = line.rstrip(",").split("=")

            # If empty line, add empty pair
            if len(pair) >= 2:
                pair = (pair[0].strip(), pair[1].strip())
                pairs.append(pair)
            else:
                pairs.append(("", ""))

    return pairs



def generate(docs, filename):
    section_order = [
        "Constants",
        "Enums",
        "Properties",
        "Static Methods",
        "Instance Methods"
    ]

    # Add sections that are not part of the above (if they exist)
    for key in docs["sections"].keys():
        if key and (key not in section_order):
            section_order.append(key)

    
    out = ""


    # Class top description
    section = docs["sections"].get(None)
    if len(section) > 0:
        for line in section[0].text:
            out += line + "\n"
        out += "\n"


    # Index
    for section_id in section_order:
        section = docs["sections"].get(section_id)

        if not section:
            continue

        # Section name
        href = "-".join([p.strip("()").lower() for p in section_id.split()])
        out += f"* [**{section_id}**]({WIKI}/{filename}#{href})  \n"

        # Element names
        for element in section:

            # Get name
            name = ""
            prefix = f"{filename}."
            if hasattr(element, "name"):
                name = element.name
            elif typeof(element) == "Method":
                name = element.signatures[0].name
                if element.is_instance:
                    prefix = f"{filename[0].lower() + filename[1:]}:"

            # Add if name is valid
            if name:
                out += f"  * [`{prefix}{name}`]({WIKI}/{filename}#{element.href})  \n"

        out += "\n"

    out = out[:-2]  # Remove 2 \n


    # Loop through sections in order
    for section_id in section_order:
        section = docs["sections"].get(section_id)

        if not section:
            continue

        # Section name
        if section_id:
            out += f"\n\n<br><br>\n\n---\n\n## {section_id}  "

        # Loop through section elements in order
        for i in range(len(section)):
            element = section[i]

            # Insert <br> for consecutive elements
            if i > 0:
                out += "\n\n<br><br>"


            # Get element type
            _type = typeof(element)
            match _type:

                case "Text":
                    out += "\n\n"

                    for line in element.text:
                        out += line + "  \n"

                    out = out[:-1]  # Remove a \n


                case "Constants":
                    # If previous element is Constants or Enum,
                    # remove the <br>
                    if i > 0:
                        prev_type = typeof(section[i - 1])
                        if (prev_type == "Constants") or (prev_type == "Enum"):
                            out = out[:-10]

                    # Code block opener
                    out += "\n\n```lua\n"

                    # Get longest constant name
                    length = 0
                    for pair in element.values:
                        length = max(len(pair[0]), length)

                    # Add pairs
                    for pair in element.values:
                        if pair[0]:
                            out += f"{filename}.{pair[0].ljust(length)}    = {pair[1]}  \n"
                        else:
                            out += "  \n"
                    
                    # Code block closer
                    out += "```"


                case "Enum":
                    # If previous element is Constants or Enum,
                    # remove the <br>
                    if i > 0:
                        prev_type = typeof(section[i - 1])
                        if (prev_type == "Constants") or (prev_type == "Enum"):
                            out = out[:-10]

                    # <a>
                    out += f"\n\n<a name=\"{element.href}\"></a>"

                    # Code block opener
                    out += "\n```lua\n"
                    out += filename + "." + element.name + " = {\n"

                    # Get longest constant name
                    length = 0
                    for pair in element.values:
                        length = max(len(pair[0]), length)

                    # Add pairs
                    for pair in element.values:
                        if pair[0]:
                            out += f"    {pair[0].ljust(length)}    = {pair[1]}  \n"
                        else:
                            out += "  \n"
                    
                    # Code block closer
                    out += "}\n```"


                case "Method":
                    # Prefix
                    prefix = filename + "."
                    if element.is_instance:
                        prefix = filename[0].lower() + filename[1:] + ":"

                    # <a>
                    out += f"\n\n<a name=\"{element.href}\"></a>"

                    # Code block opener
                    out += "\n```lua\n"

                    # Method signature(s)
                    for signature in element.signatures:

                        # Name
                        out += prefix + signature.name + "("

                        # Params
                        has_one = False

                        for p in signature.params:
                            if has_one:
                                out += ", "
                            out += p.name
                            has_one = True

                        for p in signature.optional:
                            if has_one:
                                out += ", "
                            out += f"[{p.name}]"
                            has_one = True

                        # Return
                        out += f") -> {signature.ret}  \n"

                    # Code block closer
                    out += "```\n\n"


                    # Parameter table display function
                    def parameter_table():
                        string = "**Parameters**  "
                        has_one = False
                        for signature in element.signatures:
                            if has_one:
                                string += "\n"
                            has_one = True
                            if len(signature.params) + len(signature.optional) > 0:
                                string += "\nParameter | Type | Description\n| - | - | -"
                                for p in signature.params:
                                    string += f"\n`{p.name}` | {p.type} | {p.text}"
                                for p in signature.optional:
                                    string += f"\n`[{p.name}]` | {p.type} | {p.text}"
                        return string
                    
                    ptable_shown = False


                    # Description
                    for line in element.text:
                        # Parameters
                        if "@ptable" in line:
                            out += parameter_table() + "  \n"
                            ptable_shown = True
                        
                        else:
                            out += line + "  \n"

                    # Display parameter table if not already shown
                    if not ptable_shown:
                        out += "\n" + parameter_table()
                    else:
                        out = out[:-2]  # Remove a \n


    # Write to file
    if out:
        # Make directory if existn't
        path = os.path.join(os.path.dirname(__file__), "out")
        if not os.path.exists(path):
            os.makedirs(path)

        path = os.path.join(path, f"{filename}.md")
        with open(path, "w") as f:
            f.write(out)



main()