# gen

"""
TODO
- Descriptions for `@class`
- Store appearance order for enums and methods
"""

import os
import shutil
import json
import re
from typing import Any

def main():
    cwd  = os.path.dirname(__file__)
    core = os.path.join(cwd, "../../core")
    out  = os.path.join(cwd, "out")

    if not os.path.exists(out):
        os.mkdir(out)

    # Parse every Lua file
    for dir in os.listdir(core):
        dir_path = os.path.join(core, dir)
        if os.path.isdir(dir_path):

            # Create dest directory in `out/`
            out_path = os.path.join(out, dir)
            if not os.path.exists(out_path):
                os.mkdir(out_path)
            
            # Loop through every Lua file in src directory
            for filename in os.listdir(dir_path):
                if filename.endswith(".lua"):
                    src = os.path.join(dir_path, filename)
                    with open(src, "r") as f:
                        lines = f.readlines()

                    # Check if any public classes exist
                    # (e.g., `C.<class_name> = <class_table>`)
                    public = False
                    for line in lines:
                        if re.search(r"C\..*=", line):
                            public = True
                            break
                    if not public:
                        continue

                    tokens = tokenize(lines)
                    ast    = parse(tokens)
                    with open(os.path.join(out_path, filename.split(".")[0]) + ".json", "w") as f:
                        json.dump(ast, f, indent=4)

    return

    # testing
    tokens = tokenize([
        r"---@class MyClass",
        r"MyClass = {}",
        r"MyClass.ABC = 123   -- Description for ABC!",
        r"MyClass.DEF = 1 == 2",
        r"--[[ Wow ]]",
        r"",
        r"------Long comment prefix",
        r"---@class Actor: Instance",
        r"---@field value integer Some description <br>Line 2",
        r"---@field [string] any Some description <br><br>Line 2",
        r"---@field abc table<integer, table<integer, string>>",
        r"---@field var_field integer | string",
        r"Actor = {}",
        r"---@field RAPI2 string",
        r"",
        r"---@field RAPI string",
        r'"This is a test string"',
        r"abc = 123",
        r'"String 2 with \"escaped quotes\""',
        r"abc = 123",
        r"[[",
        r"words in 'multiline'",
        r"]]",
        r"",
        r"def = 456",
        r"---@class Class2",
        r"local methods = {}",
        r"--[[",
        r"Hoo hah!",
        r"]]",
        r"methods.foo = function(self)",
        r"    print(self)",
        r"end",
        r"---@class A: B",
        r"---@class B: C, D",
        r"---@class C: D",
        r"---@class C: E",
        r"",
        r"MyClass.Enum = {",
        r"    A = 0",
        r"    B = 1  -- Description for   Enum.B!",
        r"    C = 2",
        r"}",
        r"",
        r"--[[",
        r"This function does a thing. <br>",
        r"Line 2 of the description.",
        r"",
        r"Line 4 (skipping a line)",
        r"]]",
        r"---@deprecated",
        r"---@param a integer An integer param.",
        r"---@param b? string | float A string param. <br>`balls` by default.",
        r"---@return integer | string",
        r"---@return integer | string foo Some description. <br>Line 2",
        r"---@return integer bar, integer | string baz",
        r"---@return table qux, table quux Some description.",
        r"MyClass.bar = function(a, b)",
        r"    print(a, b)",
        r"end",
        r"",
        r"--[[",
        r"This is an overload",
        r"]]",
        r"---@param c table Some table.",
        r"---@return table",
        r"MyClass.bar = function(c)",
        r"    print(c)",
        r"end",
        r"",
        r"MyClass.bar = function(d, e)",
        r"end",
        r"",
        r"---@param a integer",
        r"W.MyClass.bar = function(a, b, c) end",
    ])
    log_tokens(os.path.join(cwd, "tokens.txt"), tokens)

    out = parse(tokens)
    with open(os.path.join(cwd, "out.json"), "w") as f:
        json.dump(out, f, indent=4)


class Token:
    WORD        = 0
    TAG         = 1
    SYMBOL      = 2
    TEXT        = 3  # Words in a string
    NEW_LINE    = 4
    EMPTY_LINE  = 5
    MULTI_BEGIN = 6
    MULTI_END   = 7
    WHITESPACE  = 8
    EOF         = 9

    TypeName = ["WORD", "TAG", "SYMBOL", "TEXT", "NEW_LINE", "EMPTY_LINE",
                "MULTI_BEGIN", "MULTI_END", "WHITESPACE", "EOF"]

    Symbols       = list(r""" =.,'"{}()[]<>:\|?""")
    TextSymbols   = list(r"""'"\]""")
    DoubleSymbols = ["==", ".."]

    def __init__(self, type: int, text=""):
        self.type = type
        self.text = text

class TextType:
    SINGLE  = 0  # Text was opened with '
    DOUBLE  = 1  # Text was opened with "
    MULTI   = 2  # Text was opened with [[
    COMMENT = 3  # Text was opened with --

def tokenize(lines: list[str]) -> list[str]:
    out = []
    in_text, text_type = False, 0

    for line in lines:
        line = line.rstrip()
        tokens, i, n = [], 0, len(line)
        while i < n:

            # Whitespace
            if line[i] == " ":
                ws = ""
                while i < n and line[i] == " ":
                    ws += " "
                    i += 1
                tokens.append(Token(Token.WHITESPACE, ws))

            # Regular
            if not in_text:

                # Double symbols (`==`, `..`)
                if line[i:i+2] in Token.DoubleSymbols:
                    tokens.append(Token(Token.SYMBOL, line[i:i+2]))
                    i += 2

                # Multiline begin (comment)
                elif line[i:i+4] == "--[[":
                    tokens.append(Token(Token.MULTI_BEGIN))
                    in_text   = True
                    text_type = TextType.MULTI
                    i += 4

                # Multiline begin (string)
                elif line[i:i+2] == "[[":
                    tokens.append(Token(Token.MULTI_BEGIN))
                    in_text   = True
                    text_type = TextType.MULTI
                    i += 2

                # Annotation tag
                elif line[i:i+4] == "---@":
                    i += 4
                    j = i + 1
                    while j < n and line[j] != " ":
                        j += 1
                    name = line[i:j]
                    i = j
                    tokens.append(Token(Token.TAG, name))

                # Comment
                elif line[i:i+2] == "--":
                    while i < n and line[i] == "-":
                        i += 1
                    in_text   = True
                    text_type = TextType.COMMENT

                # ' string begin
                elif line[i] == "'":
                    in_text   = True
                    text_type = TextType.SINGLE
                    i += 1

                # " string begin
                elif line[i] == '"':
                    in_text   = True
                    text_type = TextType.DOUBLE
                    i += 1

                # Other symbols
                elif line[i] in Token.Symbols:
                    tokens.append(Token(Token.SYMBOL, line[i]))
                    i += 1

                # Words
                else:
                    j = i
                    while j < n and line[j] not in Token.Symbols:
                        j += 1
                    word = line[i:j]
                    i = j
                    tokens.append(Token(Token.WORD, word))

            # Text
            else:
                text_line = ""
                add_multi_end = False
                while i < n and in_text:

                    # Multiline end
                    if line[i:i+2] == "]]":
                        if text_type == TextType.MULTI:
                            in_text = False
                            add_multi_end = True
                        else:
                            text_line += line[i:i+2]
                        i += 2
                    
                    # Single `]`
                    elif line[i] == "]":
                        text_line += line[i]
                        i += 1

                    # Escaped ' characters
                    elif line[i:i+2] == r"\'" and text_type == TextType.SINGLE:
                        text_line += line[i+1]
                        i += 2

                    # Escaped " characters
                    elif line[i:i+2] == r'\"' and text_type == TextType.DOUBLE:
                        text_line += line[i+1]
                        i += 2

                    # Newline
                    elif line[i:i+2] == r"\n":
                        text_line += line[i:i+2]
                        i += 2

                    # Single `\`
                    elif line[i] == "\\":
                        text_line += line[i]
                        i += 1

                    # ' string end
                    elif line[i] == "'":
                        if text_type == TextType.SINGLE:
                            in_text = False
                        else:
                            text_line += line[i]
                        i += 1

                    # " string end
                    elif line[i] == '"':
                        if text_type == TextType.DOUBLE:
                            in_text = False
                        else:
                            text_line += line[i]
                        i += 1

                    # Words
                    else:
                        j = i
                        while j < n and line[j] not in Token.TextSymbols:
                            j += 1
                        word = line[i:j]
                        i = j
                        text_line += word

                if text_line:
                    tokens.append(Token(Token.TEXT, text_line))
                if add_multi_end:
                    tokens.append(Token(Token.MULTI_END))

        # End single-line comment text mode
        if in_text and text_type == TextType.COMMENT:
            in_text = False

        if len(tokens) <= 0:
            tokens.append(Token(Token.EMPTY_LINE))

        tokens.append(Token(Token.NEW_LINE))
        out += tokens
    
    out.append(Token(Token.EOF))
    return out

def log_tokens(path: str, tokens: list[Token]):
    with open(path, "w") as f:
        f.write("Tokens: " + str(len(tokens)) + "\n")
        i = 0
        for t in tokens:
            typename = Token.TypeName[t.type]
            line = "".join([
                str(i),
                "".join(" " for i in range(5 - len(str(i)))),
                typename,
                "".join(" " for i in range(11 - len(typename))),
                t.text,
                "\n"
            ])
            f.write(line)
            i += 1


def new_method_def() -> dict:
    return {
        "params":     {},  # Annotation order does not matter; use order as appears in signature
        "returns":    [],
        "desc":       [],
        "deprecated": False,
    }

def parse(tokens: list[Token]) -> dict[str, dict]:
    out, i, n = {}, 0, len(tokens)

    var_name_to_class: dict[str, dict] = {}  # Mapping of ["variables"] to out[<class>]
    method_def = new_method_def()            # def property collection for method signature in a subsequent line
    in_multi = False

    while i < n:
        token = tokens[i]

        if peek(tokens, i, Token.NEW_LINE):
            i += 1

        elif peek(tokens, i, Token.EMPTY_LINE):
            i += 1

            # Clear `method_def` if an empty line is
            # encountered outside of a multiline comment
            # (i.e., no following method signature)
            if not in_multi:
                method_def = new_method_def()
            else:
                method_def["desc"].append("")

        elif peek(tokens, i, Token.MULTI_BEGIN):
            i += 1
            in_multi = True

        elif peek(tokens, i, Token.MULTI_END):
            i += 1
            in_multi = False

        elif peek(tokens, i, Token.TEXT):
            method_def["desc"].append(tokens[i].text)
            i += 1
        
        # Annotation tag `@class`
        elif peek(tokens, i, Token.TAG, "class"):
            i = consume_whitespace(tokens, i + 1)
            
            # Class name
            name = tokens[i].text
            if not out.get(name):
                out[name] = {
                    "inherits":        [],
                    "variables":       [],  # Class tables
                    "fields":          {},  # Wrapper properties
                    "constants":       {},
                    "enums":           {},
                    "static_methods":  {},
                    "wrapper_methods": {},
                }
            d = out[name]
            i = consume_whitespace(tokens, i + 1)

            # Inheritance
            if peek(tokens, i, Token.SYMBOL, ":"):
                i = consume_whitespace(tokens, i + 1)

                while True:
                    # Parent
                    d_inherits = d["inherits"]
                    parent = tokens[i].text
                    if parent not in d_inherits:
                        d_inherits.append(parent)
                    i = consume_whitespace(tokens, i + 1)

                    # If comma, consume and continue loop
                    if peek(tokens, i, Token.SYMBOL, ","):
                        i = consume_whitespace(tokens, i + 1)
                    else:
                        break

            i = consume_line(tokens, i)
            if i >= n:
                break

            # Search for `@field`s in *consecutive* lines
            # (i.e., stop at line without `@field`) and
            # add them to the class dict
            while i < n:
                d_fields = d["fields"]
                if peek(tokens, i, Token.TAG, "field"):
                    i = consume_whitespace(tokens, i + 1)

                    # Field name (index)
                    f_index, i = parse_type(tokens, i)
                    if not d_fields.get(f_index):
                        d_fields[f_index] = {
                            "name":  f_index,
                            "types": [],
                            "desc":  [],
                        }

                    # Field types
                    type_list = d_fields[f_index]["types"]
                    while i < n:
                        i = consume_whitespace(tokens, i)
                        f_type, i = parse_type(tokens, i)

                        if f_type not in type_list:
                            type_list.append(f_type)

                        # Check for more types if `|`
                        i = consume_whitespace(tokens, i)
                        i, status = consume_if(tokens, i, Token.SYMBOL, "|")
                        if not status:
                            break

                    # Description
                    desc, line = d_fields[f_index]["desc"], ""
                    while not peek(tokens, i, Token.NEW_LINE):
                        if peek(tokens, i, Token.SYMBOL, "<") and peek(tokens, i + 1, Token.WORD, "br") and peek(tokens, i + 2, Token.SYMBOL, ">"):
                            desc.append(line.rstrip())
                            line = ""
                            i += 3
                        else:
                            line += tokens[i].text
                            i += 1
                    if line:
                        desc.append(line.rstrip())
                    
                    i = consume_line(tokens, i)

                else:
                    break

            # Assign the `@class` tag to the variable
            # on the line below (if applicable)
            d_vars = d["variables"]
            token = tokens[i]
            if token.type == Token.WORD:

                # Skip `local` keyword
                if token.text == "local":
                    i = consume_whitespace(tokens, i + 1)
                    token = tokens[i]
                    
                d_vars.append(token.text)
                var_name_to_class[token.text] = name
                i = consume_line(tokens, i)

        # Annotation tag `@param`
        elif peek(tokens, i, Token.TAG, "param"):
            i = consume_whitespace(tokens, i + 1)
            
            # Param name
            params: dict = method_def["params"]
            name = tokens[i].text
            if not params.get(name):
                params[name] = {
                    "name":     name,
                    "types":    [],
                    "desc":     [],
                    "optional": False,
                }
            param: dict = params[name]
            i = consume_whitespace(tokens, i + 1)

            # Optional?
            if peek(tokens, i, Token.SYMBOL, "?"):
                param["optional"] = True
                i = consume_whitespace(tokens, i + 1)

            # Param types
            types: list = param["types"]
            while i < n:
                i = consume_whitespace(tokens, i)
                p_type, i = parse_type(tokens, i)

                if p_type not in types:
                    types.append(p_type)

                # Check for more types if `|`
                i = consume_whitespace(tokens, i)
                i, status = consume_if(tokens, i, Token.SYMBOL, "|")
                if not status:
                    break

            # Description
            desc, line = param["desc"], ""
            while not peek(tokens, i, Token.NEW_LINE):
                if peek(tokens, i, Token.SYMBOL, "<") and peek(tokens, i + 1, Token.WORD, "br") and peek(tokens, i + 2, Token.SYMBOL, ">"):
                    desc.append(line.rstrip())
                    line = ""
                    i += 3
                else:
                    line += tokens[i].text
                    i += 1
            if line:
                desc.append(line.rstrip())
            
            i = consume_line(tokens, i)

        # Annotation tag `@return`
        elif peek(tokens, i, Token.TAG, "return"):
            i = consume_whitespace(tokens, i + 1)
            returns: list = method_def["returns"]
            
            ret_added_this_tag = []  # Description applies to all return values in the same `@return`

            while i < n:
                ret = {
                    "name":  "",
                    "types": [],
                    "desc":  [],
                }

                # Return types
                types: list = ret["types"]
                while i < n:
                    i = consume_whitespace(tokens, i)
                    r_type, i = parse_type(tokens, i)

                    if r_type not in types:
                        types.append(r_type)

                    # Check for more types if `|`
                    i = consume_whitespace(tokens, i)
                    i, status = consume_if(tokens, i, Token.SYMBOL, "|")
                    if not status:
                        break

                # Return name (optional)
                if peek(tokens, i, Token.WORD):
                    ret["name"] = tokens[i].text
                    i = consume_whitespace(tokens, i + 1)

                returns.append(ret)
                ret_added_this_tag.append(ret)

                # Check for more return values if `,`
                i = consume_whitespace(tokens, i)
                i, status = consume_if(tokens, i, Token.SYMBOL, ",")
                if not status:
                    break

            # Description
            desc, line = [], ""
            while not peek(tokens, i, Token.NEW_LINE):
                if peek(tokens, i, Token.SYMBOL, "<") and peek(tokens, i + 1, Token.WORD, "br") and peek(tokens, i + 2, Token.SYMBOL, ">"):
                    desc.append(line.rstrip())
                    line = ""
                    i += 3
                else:
                    line += tokens[i].text
                    i += 1
            if line:
                desc.append(line.rstrip())
            if desc:
                for ret in ret_added_this_tag:
                    ret["desc"] = desc
            
            i = consume_line(tokens, i)

        # Annotation tag `@deprecated`
        elif peek(tokens, i, Token.TAG, "deprecated"):
            i = consume_whitespace(tokens, i + 1)
            method_def["deprecated"] = True

        # Consume `.` indexes (e.g., `.b` in `a.b`)
        # This prevents class variable names used
        # as indices from triggering the event below
        #   (e.g., `W.MyClass`)
        elif peek(tokens, i, Token.SYMBOL, "."):
            i = consume_whitespace(tokens, i + 1)
            i, status = consume_if(tokens, i + 1, Token.WORD)

        # Add to class dict
        elif token.type == Token.WORD and var_name_to_class.get(token.text):
            class_name = var_name_to_class[token.text]
            i = consume_whitespace(tokens, i + 1)

            # Parse indexed field (e.g., `MyClass.foo`)
            index = None
            if peek(tokens, i, Token.SYMBOL, "."):
                i = consume_whitespace(tokens, i + 1)
                index = tokens[i].text
            if not index or index == "internal":
                continue
            i = consume_whitespace(tokens, i + 1)

            i, status = consume_if(tokens, i, Token.SYMBOL, "=")
            if not status:
                continue
            
            i = consume_whitespace(tokens, i)
            
            # Function
            if peek(tokens, i, Token.WORD, "function"):
                i = consume_whitespace(tokens, i + 1)

                # Check if there are any annotations
                # Do not add if there aren't
                if method_def["params"] or method_def["returns"] or method_def["desc"]:

                    # Parameters
                    params: list[dict] = []
                    open_brackets = 0
                    while not peek(tokens, i, Token.NEW_LINE):

                        # Exit signature at closing `)`
                        if peek(tokens, i, Token.SYMBOL, "("):
                            open_brackets += 1
                        elif peek(tokens, i, Token.SYMBOL, ")"):
                            open_brackets -= 1
                            if open_brackets <= 0:
                                break

                        param = tokens[i]
                        i = consume_whitespace(tokens, i + 1)

                        if param.type == Token.WORD:
                            param_name = param.text
                            param_def = method_def["params"].get(param_name)
                            if param_def:
                                params.append(param_def)
                            else:
                                params.append({
                                    "name":     param_name,
                                    "types":    [],
                                    "desc":     [],
                                    "optional": False,
                                })

                    # Wrapper method if first parameter is `self`
                    _type = "static_methods"
                    if params and params[0]["name"] == "self":
                        _type = "wrapper_methods"

                    methods = out[class_name][_type]
                    if not methods.get(index):
                        methods[index] = []
                    methods[index].append({
                        "name":       index,
                        "params":     params,
                        "returns":    method_def["returns"],
                        "desc":       method_def["desc"],
                        "deprecated": method_def["deprecated"],
                    })

                method_def = new_method_def()

            # Enum
            elif peek(tokens, i, Token.SYMBOL, "{"):
                i = consume_line(tokens, i)
                enum, i = parse_enum(tokens, i)

                enums = out[class_name]["enums"]
                enums[index] = enum

            # Constant
            else:
                constants = out[class_name]["constants"]
                value, desc = "", ""

                # Value
                i = consume_whitespace(tokens, i)
                while not peek(tokens, i, Token.NEW_LINE) and not peek(tokens, i, Token.TEXT):
                    value += tokens[i].text
                    i += 1
                value = value.rstrip()

                # Description
                i = consume_whitespace(tokens, i)
                while not peek(tokens, i, Token.NEW_LINE):
                    desc += tokens[i].text
                    i += 1
                desc = desc.rstrip()

                if value or desc:
                    constants[index] = {
                        "value": value,
                        "desc":  desc,
                    }

            i = consume_line(tokens, i)

        else:
            i += 1

    return out

def peek(tokens: list[Token], i: int, type: int, text=None) -> bool:
    """
    Look at token position `i` (without moving), and return `True` if it matches the expected token.
    """
    token = tokens[i]
    if token.type == type and (text == None or token.text == text):
        return True
    return False

def consume(tokens: list[Token], i: int, type: int, text=None) -> tuple[int, bool]:
    """
    Progress token position by 1, and return `True` if the expected token was consumed.
    """
    status = peek(tokens, i, type, text)
    i += 1
    return i, status

def consume_if(tokens: list[Token], i: int, type: int, text=None) -> tuple[int, bool]:
    """
    Progress token position by 1 *only if* the expected <br>
    token is to be consumed, and return `True` if so.
    """
    status = peek(tokens, i, type, text)
    if status:
        i += 1
    return i, status

def consume_line(tokens: list[Token], i: int) -> int:
    """
    Progress token position until after the next `NEW_LINE`.
    """
    while tokens[i].type != Token.NEW_LINE:
        i += 1
    i += 1
    return i

def consume_whitespace(tokens: list[Token], i: int) -> int:
    """
    Progress token position until the next non-`WHITESPACE`.
    """
    while tokens[i].type == Token.WHITESPACE:
        i += 1
    return i

def parse_type(tokens: list[Token], i: int) -> tuple[str, int]:
    """
    Parse param and field types as a single string. <br>
    Covers things such as `[string]`, `table<integer, string>`, etc.
    """
    out, open_brackets, n, dot = "", 0, len(tokens), 0

    if peek(tokens, i, Token.WORD):
        out += tokens[i].text
        i = consume_whitespace(tokens, i + 1)

        while i < n:
            token = tokens[i]
            text = token.text

            # Symbols
            if token.type == Token.SYMBOL:
                # Opening bracket
                if text == "[" or text == "<":
                    open_brackets += 1

                # Closing bracket
                elif text == "]" or text == ">":
                    open_brackets -= 1

                # Dot (continue as part of type)
                elif text == ".":
                    dot = 2

            # Messy but I'm tired
            if open_brackets <= 0 and dot <= 0:
                if token.type == Token.SYMBOL and (token.text == "]" or token.text == ">"):
                    out += text
                    i += 1
                break
            dot -= 1

            out += text
            i += 1
    
    elif peek(tokens, i, Token.SYMBOL, "[") or peek(tokens, i, Token.SYMBOL, "<"):
        while i < n:
            token = tokens[i]
            text = token.text
            out += text
            i += 1

            # Symbols
            if token.type == Token.SYMBOL:
                # Opening bracket
                if text == "[" or text == "<":
                    open_brackets += 1

                # Closing bracket
                elif text == "]" or text == ">":
                    open_brackets -= 1

                # Dot (continue as part of type)
                elif text == ".":
                    dot = 2

            if open_brackets <= 0 and dot <= 0:
                break
            dot -= 1

    return out, i

def parse_enum(tokens: list[Token], i: int) -> tuple[dict[str, Any], int]:
    """
    Parse enum; assumes `{` line has been consumed already.
    """
    out, n = {}, len(tokens)
    while i < n:
        i = consume_whitespace(tokens, i)

        # Check for end `}`
        i, status = consume_if(tokens, i, Token.SYMBOL, "}")
        if status:
            break

        # Constant
        i = consume_whitespace(tokens, i)
        if not peek(tokens, i, Token.WORD):
            break
        constant = tokens[i].text
        i = consume_whitespace(tokens, i + 1)

        i, status = consume_if(tokens, i, Token.SYMBOL, "=")
        if not status:
            break

        value, desc = "", ""

        # Value
        i = consume_whitespace(tokens, i)
        while not peek(tokens, i, Token.NEW_LINE) and not peek(tokens, i, Token.TEXT):
            value += tokens[i].text
            i += 1
        value = value.rstrip().rstrip(",")

        # Description
        i = consume_whitespace(tokens, i)
        while not peek(tokens, i, Token.NEW_LINE):
            desc += tokens[i].text
            i += 1
        desc = desc.rstrip()

        if value or desc:
            out[constant] = {
                "value": value,
                "desc":  desc,
            }

        i = consume_line(tokens, i)

    return out, i

main()