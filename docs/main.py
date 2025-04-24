# ReturnsAPI doc comment parser

"""
General
-- @section  <name>                         Sets the current page section; remains this until changed later in the file
-- @link     {<name> | <url path>}          Link to another section/page of the wiki (e.g., @link {some display text | Item#LootTag})
                                            Can be placed within the text parameters of any other keyword
                                            
Constants
-- @constants                               Denotes a set of constants

Enums
-- @enum                                    Denotes an enum; normally auto-finds, but use the keywords below if not
-- @name                                    (Optional)  The name of the enum; auto-prepended with class name (e.g., Class.<name>)

Methods
-- @static                                  Denotes a static method; normally auto-finds
-- @instance                                Denotes an instance method; normally auto-finds
-- @name                                    (Optional)  The name of the method
-- @href                                    (Optional)  Section link of wiki page (only needed if multiple methods have the same name)
-- @return   <return value(s)>              (Optional)  Takes the remainder of the line as the return value; "nil" if not provided
-- @param    <name> | <type(s)> | <desc>    (Optional)  A required parameter of the method
-- @optional <name> | <type(s)> | <desc>    (Optional)  An optional parameter of the method
-- @overload                                (Optional)  @name, @return, @param, and @optional keywords after this will be displayed separately
                                                        If @name is not specified, uses previous name
-- @ptable                                  (Optional)  Display the parameter table at this position, allowing for text after it
-- @image    <path>                         (Optional)  Display an image; path is relative to docs/out/images
"""



# ==================================================

import os
from pprint import pprint

from states import *
from element_types import *



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
            
            line = line.lstrip("- ")
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

    
    # DEBUG
    pprint(docs)

    print("\nMY SECTION\n")
    print(docs["sections"]["my section"][0].text)
    
    pprint(docs["sections"]["my section"][1].name)
    pprint(docs["sections"]["my section"][1].text)
    
    pprint(docs["sections"]["my section"][2].name)
    pprint(docs["sections"]["my section"][2].text)

    pprint(docs["sections"]["my section"][3].text)
    
    pprint(docs["sections"]["my section"][4].signatures[0].name)
    pprint(docs["sections"]["my section"][4].signatures[0].ret)



def parse_block(block, docs):

    # DEBUG
    pprint(block)

    # Initialize variables
    state = [ state_none ]  # State stack
    docs["element"] = None

    # Loop through lines
    # and pass to current state
    for line in block:
        state[-1](line, docs, state)

    # Add finalized element to section
    section_id = docs["section"]
    docs["sections"][section_id].append(docs["element"])



main()