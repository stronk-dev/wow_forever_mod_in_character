#!/usr/bin/env python3
"""Validate installable manifests, bindings, and every Lua chunk without executing addon code."""
from pathlib import Path
import os
import subprocess
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent
ADDON = ROOT / "InCharacter"
toc = (ADDON / "InCharacter.toc").read_text()
assert toc == (ADDON / "InCharacter_Camelot.toc").read_text(), "Flavor TOCs differ"
for required in (
    "## Interface: 16001", "## Title: In Character",
    "## Notes: Emotes, reactions, and roleplay dialogue", "## SavedVariables: InCharacterDB",
    "## SavedVariablesPerCharacter: InCharacterCharDB",
):
    assert required in toc, f"Missing TOC metadata: {required}"
entries = [line.strip() for line in toc.splitlines() if line.strip() and not line.startswith("#")]
assert len(entries) == len(set(entries)), "Duplicate TOC entries"
for entry in entries:
    assert (ADDON / entry).is_file(), f"Missing TOC file: {entry}"
lua_files = sorted(ADDON.rglob("*.lua"))
assert set(entries) == {str(path.relative_to(ADDON)) for path in lua_files}, "Unlisted Lua file"
lua = os.environ.get("LUA", "lua")
for path in [*lua_files, *sorted((ROOT / "tests").glob("*.lua"))]:
    subprocess.run(
        [lua, "-e", "assert(loadfile(os.getenv('IC_VERIFY_LUA_PATH')))"],
        env={**os.environ, "IC_VERIFY_LUA_PATH": str(path)}, check=True,
    )
bindings = ET.parse(ADDON / "Bindings.xml").getroot()
assert bindings.tag == "Bindings"
names = [binding.attrib["name"] for binding in bindings]
assert len(names) == len(set(names)) == 7
wheel = next(binding for binding in bindings if binding.attrib["name"] == "INCHARACTER_WHEEL")
assert wheel.attrib.get("runOnUp") == "true"
print(f"PASS: matching 16001 TOCs, {len(lua_files)} Lua modules, all test chunks, and 7 XML bindings")
