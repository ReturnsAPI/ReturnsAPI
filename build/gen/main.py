# gen

import os
import shutil
from pprint import pprint

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
        ])
    )


class Token:
    WORD        = 0
    TAG         = 1
    SYMBOL      = 2
    COMMENT     = 3
    MULTI_BEGIN = 4
    MULTI_END   = 5
    TEXT        = 6  # Words in a string
    NEW_LINE    = 7
    EOF         = 8

    Symbols = list(r""" =.,'"{}()[]<>:\|""")
    TypeName = ["WORD", "TAG", "SYMBOL", "COMMENT",
                "MULTI_BEGIN", "MULTI_END", "TEXT",
                "NEW_LINE", "EOF"]

    def __init__(self, type: int, text=""):
        self.type = type
        self.text = text

class TextType:
    SINGLE = 0  # Text was opened with '
    DOUBLE = 1  # Text was opened with "
    MULTI  = 2  # Text was opened with [[

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
                    tokens.append(Token(Token.SYMBOL))
                    i += 2

                # Multiline begin
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
                    j = i
                    while j < n and line[j] == "-":
                        j += 1
                    hyphens = line[i:j]
                    i = j
                    tokens.append(Token(Token.COMMENT))

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
                        tokens.append(Token(Token.MULTI_END))
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
                    while j < n and line[j] not in Token.Symbols:
                        j += 1
                    word = line[i:j]
                    i = j
                    tokens.append(Token(Token.TEXT, word))

        tokens.append(Token(Token.NEW_LINE))
        out += tokens
    
    out.append(Token(Token.EOF))
    return out


class Field:
    def __init__(self, name: str, type=""):
        self.name = name
        self.type = type

def parse(tokens: list[Token]) -> dict[str, dict]:
    # debug
    print("Tokens: " + str(len(tokens)))
    for t in tokens:
        typename = Token.TypeName[t.type]
        print(typename, "".join(" " for i in range(10 - len(typename))), t.text)
    print()

    out, i, n = {}, 0, len(tokens)
    while i < n:
        token = tokens[i]
        
        # Annotation tag `@class`
        if token.type == Token.TAG and token.text == "class":
            
            # Class name
            name = tokens[i + 1].text
            if not out.get(name):
                out[name] = {
                    "variables": [],
                    "fields": {},
                }
            d = out[name]
            i += 2

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

            # Assign the `@class` tag to the variable below
            d_vars = d["variables"]
            token = tokens[i]
            if token.type == Token.WORD:
                d_vars.append(token.text)
            i = consume_line(tokens, i)

        else:
            i += 1

    pprint(out)

    return out

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

def consume_line(tokens: list[Token], i: int) -> int:
    """
    Progress token position until after the next `NEW_LINE`.
    """
    while tokens[i].type != Token.NEW_LINE:
        i += 1
    i += 1
    return i

main()