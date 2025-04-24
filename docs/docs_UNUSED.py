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
    while len(lines) > 0:
        line = lines[0]

        # Finalize element list into a string
        if ("--" not in line) and (state_text not in vars["state_stack"]) and (type(vars["sections"][vars["section"]][-1]) == list):
            finalize_element(vars, lines, filename)
            while len(vars["state_stack"]) > 1:
                vars["state_stack"].pop()
            continue

        # Strip front and back whitespace,
        # remove "--", and split line into tokens
        tokens = line.strip().strip("-").split()

        # Loop tokens until all read
        while len(tokens) > 0:

            # Pass to current state function
            vars["state_stack"][-1](vars, tokens)

        # Remove current line from list
        lines.pop(0)

    
    # Write to file
    # TODO
    print(vars)

    section = vars["sections"]["my section"]
    for s in section:
        print(s)



def finalize_element(vars, lines, filename):
    element = vars["sections"][vars["section"]][-1]
    class_name = filename[:-4]
    string = ""

    match element[0]:

        case "enum":
            name = ""
            values = []
            length = 0

            # Name
            for tuple in element:
                if tuple[0] == "name":
                    name = class_name + "." + tuple[1] + " = {  \n"

            # Values
            for tuple in element:
                if tuple[0] == "text":
                    values = tuple[1].split("\n")   # Split by newline
                    values = [t.strip().split() for t in values]

            # Auto-find missing fields
            # Loop code until next set of comments
            no_name = (name == "")
            no_values = (len(values) <= 0)

            for line in lines:
                if "--" not in line:
                    if "{" in line:
                        if no_name:
                            tok = line.strip().split()
                            name = tok[0] + " = {  \n"
                    elif "=" in line:
                        if no_values:
                            tok = line.strip(" ").split()
                            values.append([tok[0], tok[2].strip(",")])
                else:
                    break

            # Get longest enum value name
            for pair in values:
                if len(pair) > 0:
                    length = max(len(pair[0]), length)

            # Format pairs to string
            text = ""
            padding = length + 4    # Add 4 space padding to right
            for pair in values:
                if len(pair) > 0:
                    text += f"    {pair[0].ljust(padding)}= {pair[1]},  \n"
                else:
                    text += "  \n"
            text = text[:-4] + "  \n}"

            string = "```lua  \n" + name + text + "  \n```"


    # Replace element list with finalized string
    vars["sections"][vars["section"]][-1] = string



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

        
        # Start new enum
        case "@enum":
            tokens.pop(0)
            vars["state_stack"].append(state_enum)
            vars["sections"][vars["section"]].append([ "enum" ])

        
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
            # section_list[-1] is a list
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
        link = f"[{vars["link"][0].strip()}]({WIKI}/{vars["link"][1].strip()}) "
        vars["text"] += link

        tokens.pop(0)
        vars["state_stack"].pop()

        # Add line break at EOL
        if len(tokens) <= 0:
            vars["text"] += " \n"


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



def state_enum(vars, tokens):
    # Get current token
    token = tokens[0]

    match token:

        # Start new name
        case "@name":
            tokens.pop(0)
            vars["state_stack"].append(state_name)

        
        # Start new text
        case "[[":
            tokens.pop(0)
            vars["state_stack"].append(state_text)
            vars["text"] = ""

        
        # Discard unused tokens
        case _:
            tokens.pop(0)



def state_name(vars, tokens):
    # Get current token
    token = tokens[0]

    # Add name to element
    name = f"{token}"
    section_list = vars["sections"][vars["section"]]
    section_list[-1].append(("name", name))

    tokens.pop(0)
    vars["state_stack"].pop()



main()