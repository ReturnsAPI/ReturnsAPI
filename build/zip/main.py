# zip

import os
import shutil

def main():
    cwd = os.path.dirname(__file__)
    out = os.path.join(cwd, "out")

    if not os.path.exists(out):
        os.mkdir(out)

    # Copy root files
    src = os.path.join(cwd, "../..")
    dest = out
    for file in [
        "main.lua",
        "envy.lua",
        "manifest.json",
        "icon.png",
        "README.md",
        "CHANGELOG.md",
    ]:
        shutil.copy(
            os.path.join(src, file),
            dest,
        )

    # Copy `core`
    src = os.path.join(cwd, "../../core")
    dest = os.path.join(out, "core")
    shutil.copytree(
        src,
        dest,
        ignore=shutil.ignore_patterns("*.md"),
        dirs_exist_ok=True,
    )

    # TODO copy other shit like language etc

    shutil.make_archive(
        os.path.join(cwd, "out"),
        "zip",
        out,
    )
    shutil.rmtree(out)

main()