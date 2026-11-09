"""Build and verify the standalone MO2 ZIP for this version."""

import os
import re
import runpy
import sys
from pathlib import Path
from tempfile import NamedTemporaryFile
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo


ROOT = Path(__file__).resolve().parent
PAYLOAD = (
    "gamedata/configs/text/eng/ui_st_gacw.xml",
    "gamedata/configs/text/rus/ui_st_gacw.xml",
    "gamedata/scripts/gacw_core.script",
    "gamedata/scripts/gacw_mcm.script",
)


def verify(archive, expected):
    with ZipFile(archive) as package:
        if sorted(package.namelist()) != sorted(expected) or package.testzip() is not None:
            raise ValueError("Unexpected members or bad CRC in the MO2 ZIP")
        if any(package.read(name) != content for name, content in expected.items()):
            raise ValueError("This ZIP contains different files. Use a new version for a changed build.")


def build():
    version = (ROOT / "VERSION").read_text(encoding="ascii").strip()
    if not re.fullmatch(r"(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)", version):
        raise ValueError("VERSION must contain a three-part release version")

    expected = {name: (ROOT / "mod" / name).read_bytes() for name in PAYLOAD}
    expected["LICENSE"] = (ROOT / "LICENSE").read_bytes()
    if any(not content for content in expected.values()):
        raise ValueError("The MO2 payload contains an empty file")

    package_path = ROOT / "dist" / f"GAMMA_Adjustable_Carry_Weight_v{version}_MO2.zip"
    package_path.parent.mkdir(exist_ok=True)
    if not package_path.exists():
        with NamedTemporaryFile(dir=package_path.parent, suffix=".tmp", delete=False) as output:
            staged = Path(output.name)
        try:
            with ZipFile(staged, "w") as package:
                for name, content in expected.items():
                    package.writestr(ZipInfo(name), content, compress_type=ZIP_DEFLATED)
            verify(staged, expected)
            try:
                os.link(staged, package_path)
            except FileExistsError:
                pass  # A concurrent build already claimed this version.
        finally:
            staged.unlink()

    verify(package_path, expected)
    return package_path


def deliver(package_path):
    helper = ROOT.parent / "_tools" / "deliver_mo2.py"
    if not helper.is_file():
        print("MO2 delivery skipped. Shared helper unavailable.")
        return

    shared = runpy.run_path(str(helper))
    target = shared["DOWNLOADS"] / package_path.name
    try:
        if target.is_file() and shared["sha256"](target) != shared["sha256"](package_path):
            print(f"WARNING: MO2 delivery skipped. This version already has a different ZIP at {target}.",
                  file=sys.stderr)
            return
    except OSError:
        pass  # Let the shared helper report an access failure.
    shared["deliver_mo2_zip"](package_path)


if __name__ == "__main__":
    archive_path = build()
    print(f"Verified MO2 ZIP: {archive_path}", flush=True)
    deliver(archive_path)
