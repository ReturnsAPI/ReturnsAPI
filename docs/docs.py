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
-- @ptable                                  (Optional)  Display the parameter table at this position, allowing for text after it
-- @image    <path>                         (Optional)  Display an image; path is relative to docs/out/images
"""



# ==================================================

import os

# WIKI = "https://github.com/ReturnsAPI/ReturnsAPI/wiki"



def main():
    core_path = os.path.join(os.path.dirname(__file__), "../docs_test") # debug
    
    # Loop through all directories in `core`
    for dir in os.listdir(core_path):
        dir_path = os.path.join(core_path, dir)
        if os.path.isdir(dir_path):
            
            # Loop through all Lua files in directory
            for file in os.listdir(dir_path):
                if file.endswith(".lua"):
                    file_path = os.path.join(dir_path, file)
                    parse_file(file_path)



def parse_file(file_path):

    # Initialize variables
    vars = {
        "state_stack"   : [state_none],
        "section"       : None,
        "sections"      : {
            None: []
        }
    }
    

    # Get file data
    with open(file_path, "r") as f:
        lines = f.readlines()


    # Read lines
    for line in lines:

        # TODO temp; handle when code is reached
        if "--" not in line:
            # continue
            pass

        # Strip front and back whitespace,
        # remove "--", and split line into tokens
        tokens = line.strip().strip("-").split()

        # Loop tokens until all read
        while len(tokens) > 0:

            # Pass to current state function
            vars["state_stack"][-1](vars, tokens)

    
    # Write to file
    # TODO
    print(vars)



def state_none(vars, tokens):
    # Get current token
    token = tokens[0]

    match token:

        # Set current section; if empty, default to None
        case "@section":
            tokens.pop(0)

            if len(tokens) > 0:
                vars["state_stack"].append(state_section)
                vars["section_name"] = ""
            
            else:
                vars["section_name"] = None

        
        # Start new text
        case "[[":
            tokens.pop(0)
            vars["state_stack"].append(state_text)
            vars["text"] = ""

        
        # Discard unused tokens
        case _:
            tokens.pop(0)



def state_section(vars, tokens):
    # Get current token
    token = tokens[0]

    # Add token as word to section name
    if vars["section_name"] != "":
        vars["section_name"] += " "
    vars["section_name"] += token

    # Exit state if EOL
    tokens.pop(0)
    if len(tokens) <= 0:
        vars["state_stack"].pop()
        vars["section"] = vars["section_name"]

        # Create new section dictionary if existn't
        section = vars["section"]
        dict = vars["sections"].get(section)
        if not dict:
            vars["sections"][section] = []



def state_text(vars, tokens):
    # Get current token
    token = tokens[0]

    match token:

        # End text
        case "]]":
            section_list = vars["sections"][vars["section"]]

            # A non-finalized element exists if
            # section_list[-1] is a List
            # (This list gets assembled into a string later)

            # Add text as standalone element
            if len(section_list) <= 0 or type(section_list[-1]) != list:
                section_list.append(vars["text"])

            # Add text as part of another element
            else:
                section_list[-1].append(("text", vars["text"]))

            tokens.pop(0)
            vars["state_stack"].pop()

        
        # Start new link
        case "@link":
            tokens.pop(0)
            vars["state_stack"].append(state_link)
            vars["link"] = ["", ""]
            vars["link_part"] = 0


        # Add token as word
        case _:
            word = f"{token} "
            vars["text"] += word

            # Add line break at EOL
            tokens.pop(0)
            if len(tokens) <= 0:
                vars["text"] += " \n"



def state_link(vars, tokens):

    def end_link(vars, tokens):
        # Add link to text
        link = f"[{vars["link"][0].strip()}]({vars["link"][1].strip()}) "
        vars["text"] += link

        tokens.pop(0)
        vars["state_stack"].pop()


    # Get current token
    token = tokens[0]

    match token:

        # Pass {
        case "{":
            tokens.pop(0)
            return
        

        # End link
        case "}":
            end_link(vars, tokens)
        

        # Middle break
        case "|":
            vars["link_part"] = 1
            tokens.pop(0)
        

        # Add token as word to link part
        case _:
            if "}" not in token:
                # Strip opening { if it is not spaced from the first word
                word = f"{token.strip("{")} "
                vars["link"][vars["link_part"]] += word
                tokens.pop(0)

            # End link
            else:
                end_link(vars, tokens)



main()