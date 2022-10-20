from typing import Set
from pathlib import Path
from shutil import copy2, copytree, rmtree
import yaml

DIST = Path("dist")
SRC = Path("src")
ASSETS = Path("assets")
LIB = Path("tmbslib")


def process_info(filename: str):
    with open(filename, "r", encoding="utf-8") as file:
        info = yaml.safe_load(file)

        (DIST / "info.txt").unlink(True)
        with (DIST / "info.txt").open("w") as output:
            output.write(
                f"name = {info['name']}\n"
                f"author = {info['author']}\n"
                f"description = [noupload]{info['description']}\n"
                f"tags={','.join(info['tags'])}"
            )

        (DIST / "id.txt").unlink(True)
        if (mod_id := dict.get(info, "id")) is not None:
            with (DIST / "id.txt").open("w") as output:
                output.write(str(mod_id))


def process_file(filename: str, included: Set[str] = None):
    def include(path):
        nonlocal output
        if path not in included:
            try:
                output += process_file(path, included)
            except FileNotFoundError:
                print(
                    f'At "{filename}", line {lineno}: Can\'t include "{path}" (file not found)'
                )

    def get_arg(line):
        start = line.find('"')
        end = line.rfind('"')
        return line[start + 1 : end]

    if included is None:
        included = set()

    lineno = 0
    output = ""
    module = None
    deps = []
    with (SRC / filename).with_suffix(".lua").open("r") as file:
        included.add(filename)  # Add early to prevent recursion

        while (line := file.readline()) != "":
            lineno += 1

            if line.startswith("_include"):
                include(get_arg(line))
            elif line.startswith("_module"):
                module = get_arg(line)
            elif line.startswith("_requires"):
                dep = get_arg(line)
                deps.append(dep)
                include(dep)
            else:
                output += line

    if module is not None:
        output += f'\n_Module("{module}"'
        if len(deps) > 0:
            output += ", {" + ",".join(f'"{dep}"' for dep in deps) + "}"
        output += ")\n"
    return output


def process_entrypoint(file: str):
    with (DIST / file).with_suffix(".lua").open("w") as output:
        with (LIB / "internal" / "modulesystem.lua").open("r") as tmbs_modulesystem:
            output.write(tmbs_modulesystem.read())

        output.write(process_file(file))


if __name__ == "__main__":
    DIST.mkdir(exist_ok=True)

    try:
        rmtree(DIST / "assets")
    except FileNotFoundError:
        pass

    copytree(ASSETS, DIST / "assets")

    copy2("preview.jpg", DIST)

    process_info("info.yml")
    process_entrypoint("main")
    process_entrypoint("options")
