# States

from element_types import *

global WIKI; WIKI = "https://github.com/ReturnsAPI/ReturnsAPI/wiki"



def state_none(line, docs, state):
    tokens = line.split()
    
    if len(tokens) <= 0:
        return

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


        # Start new text
        case "@mlstart":
            state.append(state_text)

            # Create new standalone text element
            # if not adding as part of another element
            if not docs["element"]:
                docs["element"] = Text()


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


        # Set name; if empty, autofinds
        case "@name":
            if isinstance(docs["element"], Enum):
                docs["element"].name = tokens[1]

            elif isinstance(docs["element"], Method):
                docs["element"].signatures[-1].name = tokens[1]


        # Set return; if empty, will be `nil`
        case "@return":
            ret = line.split(None, 1)
            if len(ret) >= 2:
                docs["element"].signatures[-1].ret = ret[1]



def state_text(line, docs, state):
    parsed = ""

    # Parse through line
    tokens = line.split()
    while len(tokens) > 0:
        token = tokens.pop(0)
        match token:

            # End text
            case "@mlend":
                state.pop()
                return


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

            
            # Add line to text
            case _:
                parsed += token + " "


    # Add parsed line to element.text
    docs["element"].text.append(parsed)