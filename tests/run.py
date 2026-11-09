"""Run the installed GAMMA scripts with test doubles for the X-Ray engine."""

import argparse
from pathlib import Path
from xml.etree import ElementTree

from lupa.luajit21 import LuaRuntime


ROOT = Path(__file__).resolve().parents[1]
GAMEDATA = ROOT / "mod" / "gamedata"


def translations():
    keys = {
        "ui_mcm_menu_gacw",
        "ui_mcm_gacw_additional_carry_weight",
        "ui_mcm_gacw_additional_carry_weight_desc",
    }
    expected = {
        "eng": ("ascii", "GAMMA 0.9.5 Adjustable Carry Weight", "Additional Carry Weight (kg)"),
        "rus": ("cp1251", "GAMMA 0.9.5 — Настройка переносимого веса", "Дополнительный переносимый вес (кг)"),
    }
    for lang, (encoding, title, label) in expected.items():
        path = GAMEDATA / "configs" / "text" / lang / "ui_st_gacw.xml"
        xml = ElementTree.fromstring(path.read_text(encoding=encoding))
        assert xml.tag == "string_table" and len(xml) == len(keys), path
        strings = {node.attrib["id"]: node.findtext("text") for node in xml}
        assert strings.keys() == keys and all(strings.values()), path
        assert strings["ui_mcm_menu_gacw"] == title, path
        assert strings["ui_mcm_gacw_additional_carry_weight"] == label, path
    print("English and Windows-1251 Russian string tables passed.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("weight-script", "mcm-script", "axr-main"):
        parser.add_argument(f"--{name}", type=Path, required=True)
    args = parser.parse_args()
    sources = {
        "weight": args.weight_script.read_bytes(),
        "ui_mcm": args.mcm_script.read_bytes(),
        "axr_main": args.axr_main.read_bytes(),
        "gacw_core": (GAMEDATA / "scripts" / "gacw_core.script").read_bytes(),
        "gacw_mcm": (GAMEDATA / "scripts" / "gacw_mcm.script").read_bytes(),
    }
    lua = LuaRuntime()
    lua.globals().sources = lua.table_from(sources)
    lua.execute(Path(__file__).with_name("integration.lua").read_bytes())
    translations()


if __name__ == "__main__":
    main()
