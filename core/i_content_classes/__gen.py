import os
import re

def main():
    cwd  = os.path.dirname(__file__)

    ignore = [
        "__template.lua",
        "Item.lua",
    ]
    vowels = list("aeiou")

    with open(os.path.join(cwd, "__template.lua"), "r") as f:
        template = f.read()

    for filename in os.listdir(cwd):
        if filename.endswith(".lua") and filename not in ignore:
            with open(os.path.join(cwd, filename), "w") as f:
                upper = filename.split(".")[0]
                lower = re.sub('([a-z0-9])([A-Z])', r'\1 \2', re.sub('(.)([A-Z][a-z]+)', r'\1 \2', upper)).lower()
                an    = "Returns an " + lower + " wrapper" if lower[0] in vowels else "Returns a " + lower + " wrapper"
                out   = template.replace("CLASS_UPPER", upper).replace("CLASS_LOWER", lower).replace("Returns a " + lower + " wrapper", an).replace("if true then return end\n\n", "")
                f.write(out)

main()