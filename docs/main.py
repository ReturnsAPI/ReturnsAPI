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
    core_path = os.path.join(os.path.dirname(__file__), "../docs_test") # debug
    
    # Loop through all directories in `core`
    for dir in os.listdir(core_path):
        dir_path = os.path.join(core_path, dir)
        if os.path.isdir(dir_path):
            
            # Loop through all Lua files in directory
            for filename in os.listdir(dir_path):
                if filename.endswith(".lua"):
                    file_path = os.path.join(dir_path, filename)
                    parse_file(file_path, filename)



def parse_file(file_path, filename):

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
        line = line.rstrip()
        
        if in_code:
            if line.startswith("--"):
                in_code = False
                if current_block:
                    # Remove trailing newlines from block
                    while current_block[-1] == "":
                        current_block.pop(-1)

                    blocks.append(current_block)
                    current_block = []

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


    # Generate wiki files
    generate(docs)

    
    # DEBUG
    pprint(docs)

    print("\nMY SECTION\n")
    print(docs["sections"]["my section"][0]["element"].text)
    
    pprint(docs["sections"]["my section"][1]["element"].name)
    pprint(docs["sections"]["my section"][1]["element"].text)
    
    pprint(docs["sections"]["my section"][2]["element"].name)
    pprint(docs["sections"]["my section"][2]["element"].text)

    pprint(docs["sections"]["my section"][3]["element"].text)
    
    pprint(docs["sections"]["my section"][4]["element"].signatures[0].name)
    pprint(docs["sections"]["my section"][4]["element"].signatures[0].ret)
    pprint(docs["sections"]["my section"][4]["code"])

    pprint(docs["sections"]["my section"][4]["element"].signatures[0].params[0].name)
    pprint(docs["sections"]["my section"][4]["element"].signatures[0].params[0].type)
    pprint(docs["sections"]["my section"][4]["element"].signatures[0].params[0].text)

    pprint(docs["sections"]["my section"][4]["element"].signatures[0].params[1].name)
    pprint(docs["sections"]["my section"][4]["element"].signatures[0].params[1].type)
    pprint(docs["sections"]["my section"][4]["element"].signatures[0].params[1].text)

    pprint(docs["sections"]["my section"][4]["element"].signatures[1].optional[0].name)
    pprint(docs["sections"]["my section"][4]["element"].signatures[1].optional[0].type)
    pprint(docs["sections"]["my section"][4]["element"].signatures[1].optional[0].text)



def parse_block(block, docs):

    # DEBUG
    pprint(block)

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

                # Take name of original signature by default
                signature.name = docs["element"].signatures[0].name
                
                docs["element"].signatures.append(signature)


            # Set name; if empty, autofinds
            case "@name":
                if isinstance(docs["element"], Enum):
                    docs["element"].name = tokens[1]

                elif isinstance(docs["element"], Method):
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
                parts = [p.strip() for p in line.split(None, 1)[1].split("|")]
                param = Param(parts[0], parts[1], parse_line(parts[2]))
                docs["element"].signatures[-1].params.append(param)


            # Add optional parameter
            case "@optional":
                parts = [p.strip() for p in line.split(None, 1)[1].split("|")]
                param = Param(parts[0], parts[1], parse_line(parts[2]))
                docs["element"].signatures[-1].optional.append(param)

            
            # Add code
            case _:
                code.append(line)


    # Add finalized element to section
    section_id = docs["section"]
    docs["sections"][section_id].append({
        "element"   : docs["element"],
        "code"      : code
    })



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



def generate(docs):
    section_order = [
        None,
        "Constants",
        "Enums",
        "Properties",
        "Static Methods",
        "Instance Methods"
    ]

    # TODO



main()