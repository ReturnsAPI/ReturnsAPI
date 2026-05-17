# gen

import os
import shutil
from pprint import pprint
from typing import Any

def main():
    # cwd  = os.path.dirname(__file__)
    # out  = os.path.join(cwd, "out")

    # if not os.path.exists(out):
    #     os.mkdir(out)

    # # testing
    # core = os.path.join(cwd, "../../core")
    # src  = os.path.join(core, "f_callbacks/Callback.lua")
    # dest = os.path.join(out, "Callback.lua")
    # shutil.copy(
    #     src,
    #     dest,
    # )

    # with open(dest, "r") as f:
    #     lines = f.readlines()
    # parse(lines)

    # testing
    out = parse(
        tokenize([
            r"---@class MyClass",
            r"MyClass = {}",
            r"MyClass.ABC = 123",
            r"MyClass.DEF = 1 == 2",
            r"--[[ Wow ]]",
            r"",
            r"------Long comment prefix",
            r"---@class Actor: Instance",
            r"---@field value integer",
            r"---@field [string] any",
            r"---@field abc table<integer, table<integer, string>>",
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
            r"def = 456",
            r"---@class Class2",
            r"local methods = {}",
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
            r"    B = 1",
            r"    C = 2",
            r"}",
        ])
    )


class Token:
    WORD     = 0
    TAG      = 1
    SYMBOL   = 2
    TEXT     = 3  # Words in a string
    NEW_LINE = 4
    EOF      = 5

    TypeName = ["WORD", "TAG", "SYMBOL",
                "TEXT", "NEW_LINE", "EOF"]

    Symbols     = list(r""" =.,'"{}()[]<>:\|""")
    TextSymbols = list(r"""'"\]""")

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
        tokens, i, n = [], 0, len(line)
        while i < n:

            # Whitespace
            if line[i] == " ":
                while i < n and line[i] == " ":
                    i += 1

            # Regular
            if not in_text:

                # Comparison
                if line[i:i+2] == "==":
                    tokens.append(Token(Token.SYMBOL, line[i:i+2]))
                    i += 2

                # Multiline begin (comment)
                elif line[i:i+4] == "--[[":
                    in_text   = True
                    text_type = TextType.MULTI
                    i += 4

                # Multiline begin (string)
                elif line[i:i+2] == "[[":
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
                # Multiline end
                if line[i:i+2] == "]]":
                    if text_type == TextType.MULTI:
                        in_text = False
                    else:
                        tokens.append(Token(Token.TEXT, line[i:i+2]))
                    i += 2

                # Escaped ' characters
                elif line[i:i+2] == r"\'" and text_type == TextType.SINGLE:
                    tokens.append(Token(Token.TEXT, line[i+1]))
                    i += 2

                # Escaped " characters
                elif line[i:i+2] == r'\"' and text_type == TextType.DOUBLE:
                    tokens.append(Token(Token.TEXT, line[i+1]))
                    i += 2

                # ' string end
                elif line[i] == "'":
                    if text_type == TextType.SINGLE:
                        in_text = False
                    else:
                        tokens.append(Token(Token.TEXT, line[i]))
                    i += 1

                # " string end
                elif line[i] == '"':
                    if text_type == TextType.DOUBLE:
                        in_text = False
                    else:
                        tokens.append(Token(Token.TEXT, line[i]))
                    i += 1

                # Words
                else:
                    j = i
                    while j < n and line[j] not in Token.TextSymbols:
                        j += 1
                    word = line[i:j]
                    i = j
                    tokens.append(Token(Token.TEXT, word))

        # End single-line comment text mode
        if in_text and text_type == TextType.COMMENT:
            in_text = False

        tokens.append(Token(Token.NEW_LINE))
        out += tokens
    
    out.append(Token(Token.EOF))
    return out


class Field:
    def __init__(self, name: str, type=""):
        self.name = name
        self.type = type

class Method:
    def __init__(self):
        self.params:  list[Param]  = []
        self.returns: list[Return] = []
        self.desc = ""
        self.deprecated = False

class Param:
    def __init__(self, name, type="unknown", desc=""):
        self.name = name
        self.type = type
        self.desc = desc

class Return(Field):
    def __init__(self, name: str, type=""):
        super(name, type)

def parse(tokens: list[Token]) -> dict[str, dict]:
    # debug
    print("Tokens: " + str(len(tokens)))
    for t in tokens:
        typename = Token.TypeName[t.type]
        print(typename, "".join(" " for i in range(10 - len(typename))), t.text)
    print()

    var_name_to_class: dict[str, dict] = {} # Mapping of ["variables"] to out[<class>]

    out, i, n = {}, 0, len(tokens)
    while i < n:
        token = tokens[i]
        
        # Annotation tag `@class`
        if peek(tokens, i, Token.TAG, "class"):
            
            # Class name
            name = tokens[i + 1].text
            if not out.get(name):
                out[name] = {
                    "inherits": [],
                    "variables": [],  # Class tables
                    "fields": {},     # Wrapper properties
                    "constants": {},
                    "enums": {},
                    "static_methods": {},
                    "wrapper_methods": {},
                }
            d = out[name]
            i += 2

            # Inheritance
            if peek(tokens, i, Token.SYMBOL, ":"):
                i += 1

                while True:
                    # Parent
                    d_inherits = d["inherits"]
                    parent = tokens[i].text
                    if parent not in d_inherits:
                        d_inherits.append(parent)
                    i += 1

                    # If comma, consume and continue loop
                    if peek(tokens, i, Token.SYMBOL, ","):
                        i += 1
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
                token = tokens[i]
                if token.type == Token.TAG and token.text == "field":
                    i += 1
                    f_index, i = parse_type(tokens, i)
                    f_type,  i = parse_type(tokens, i)

                    if not d_fields.get(f_index):
                        d_fields[f_index] = Field(f_index)
                    d_fields[f_index].type = f_type

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
                    token = tokens[i + 1]
                    
                d_vars.append(token.text)
                var_name_to_class[token.text] = name
                i = consume_line(tokens, i)

        # Add to class dict
        elif token.type == Token.WORD and var_name_to_class.get(token.text):
            class_name = var_name_to_class[token.text]
            i += 1

            # Parse indexed field (e.g., `MyClass.foo`)
            index = None
            if peek(tokens, i, Token.SYMBOL, "."):
                i += 1
                index = tokens[i].text
            if not index or index == "internal":
                continue
            i += 1

            i, status = consume_if(tokens, i, Token.SYMBOL, "=")
            if not status:
                continue

            token = tokens[i]

            # Enum
            if peek(tokens, i, Token.SYMBOL, "{"):
                i = consume_line(tokens, i)
                enum, i = parse_enum(tokens, i)

                enums = out[class_name]["enums"]
                enums[index] = enum

            # Function
            # if token.type == Token.WORD and token.text == "function":

            else:
                constants = out[class_name]["constants"]
                constants[index] = token.text

            # TODO static and wrapper methods

        else:
            i += 1

    pprint(out)

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

def parse_type(tokens: list[Token], i: int) -> tuple[str, int]:
    """
    Parse param and field types as a single string. <br>
    Covers things such as `[string]`, `table<integer, string>`, etc.
    """
    out, open_brackets, n = "", 0, len(tokens)

    while i < n:
        token = tokens[i]
        i += 1

        text = token.text
        out += text

        # Symbols
        if token.type == Token.SYMBOL:
            # Opening bracket
            if text == "[" or text == "<":
                open_brackets += 1

            # Closing bracket
            elif text == "]" or text == ">":
                open_brackets -= 1

            # Comma (add a space)
            elif text == ",":
                out += " "

        if open_brackets <= 0:
            break

    return out, i

def parse_enum(tokens: list[Token], i: int) -> tuple[dict[str, Any], int]:
    """
    Parse enum; assumes `{` line has been consumed already.
    """
    out, n = {}, len(tokens)
    while i < n:
        # Check for end `}`
        i, status = consume_if(tokens, i, Token.SYMBOL, "}")
        if status:
            break

        # Constant
        if not peek(tokens, i, Token.WORD):
            break
        constant = tokens[i].text
        i += 1

        i, status = consume_if(tokens, i, Token.SYMBOL, "=")
        if not status:
            break

        # Value
        if not peek(tokens, i, Token.WORD):
            break
        value = tokens[i].text
        i += 1

        out[constant] = value
        i = consume_line(tokens, i)

    return out, i

main()