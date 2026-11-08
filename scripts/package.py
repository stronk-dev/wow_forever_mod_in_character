#!/usr/bin/env python3
"""Build a deterministic, dependency-free WoW addon ZIP from the working tree."""
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parent.parent
output = ROOT / "dist" / "InCharacter-0.3.0.zip"
output.parent.mkdir(exist_ok=True)
files = {str(path.relative_to(ROOT)): path for path in (ROOT / "InCharacter").rglob("*") if path.is_file()}
for name in ("README.md", "LICENSE", "CONTRIBUTING.md", "LIBRARY.md", "FOREVER_TEST_CHECKLIST.md"):
    files[f"InCharacter/{name}"] = ROOT / name
with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED) as archive:
    for name, path in sorted(files.items()):
        info = zipfile.ZipInfo(name, date_time=(2026, 11, 8, 0, 0, 0))
        info.compress_type = zipfile.ZIP_DEFLATED
        info.external_attr = 0o100644 << 16
        archive.writestr(info, path.read_bytes())
with zipfile.ZipFile(output) as archive:
    assert archive.testzip() is None
    assert "InCharacter/InCharacter.toc" in archive.namelist()
    assert "InCharacter/InCharacter_Camelot.toc" in archive.namelist()
    assert "InCharacter/Bindings.xml" in archive.namelist()
    assert all(name.startswith("InCharacter/") for name in archive.namelist())
print(output)
