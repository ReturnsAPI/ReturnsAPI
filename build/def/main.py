# def

import os
import shutil
import re

def main():
    # Copy `core`
    cwd = os.path.dirname(__file__)
    out_path = os.path.join(cwd, "out")
    core_path = os.path.join(cwd, "../../core")
    shutil.copytree(
        core_path,
        out_path,
        ignore=shutil.ignore_patterns("*.md"),
        dirs_exist_ok=True,
    )

    # Parse every Lua file
    for dir in os.listdir(out_path):
        dir_path = os.path.join(out_path, dir)
        if os.path.isdir(dir_path):
            for filename in os.listdir(dir_path):
                if filename.endswith(".lua"):
                    file_path = os.path.join(dir_path, filename)
                    parse_file(file_path)

    # extra_file(os.path.join(out_path, "extra.lua"))

def parse_file(file_path):
    with open(file_path, "r") as f:
        lines = f.readlines()

    # Check if file is a public class
    # (i.e., has `C. = `)
    public = False
    for line in lines:
        if re.search(r"C\..*=", line):
            public = True
            break
    if not public:
        os.remove(file_path)
        return

    in_metatable = False
    in_local_function_body = False
    in_function_body = False

    parsed = []
    for line in lines:
        line = line.rstrip()

        # if re.search(r"P\..*=", line) or re.search(r"G\..*=", line) or re.search(r"C\..*=", line) or re.search(r"local.*=", line) or re.search(r"= W.", line):
        if re.search(r"P\..*=", line) or re.search(r"G\..*=", line) or re.search(r"C\..*=", line) or re.search(r"= P.", line) or re.search(r"= G.", line) or re.search(r"= W.", line) or re.search(r"= M.", line):
            pass

        elif "new_class()" in line:
            line = line.replace("new_class()", "{}")
            parsed.append(line + "\n")

        elif in_metatable:
            if line[:1] == "}":
                in_metatable = False

        elif line[:2] == "W." or line[:2] == "M.":
            in_metatable = True

        elif in_local_function_body:
            if line[:3] == "end":
                in_local_function_body = False

        elif "local function" in line:
            if " end" not in line:
                in_local_function_body = True

        elif in_function_body:
            if line[:3] == "end":
                in_function_body = False
                parsed.append(line + "\n")

        elif "= function(" in line or re.search(r"run_.*function\(", line):
            line = line.replace("NAMESPACE, ", "")
            line = line.replace("NAMESPACE", "")
            line = line.replace(", namespace_is_specified", "")
            parsed.append(line + "\n")

            if " end" not in line:
                in_function_body = True

        else:
            parsed.append(line + "\n")

    with open(file_path, "w") as f:
        f.write("---@meta\n")
        for line in parsed:
            f.write(line)

def extra_file(file_path):
    with open(file_path, "w") as f:
        f.write("---@meta\n")

        for t in ["G", "P", "C", "M", "W"]:
            f.write("-- Inaccessible; used by ReturnsAPI internally.\n")
            f.write(f"{t} = nil\n")

main()