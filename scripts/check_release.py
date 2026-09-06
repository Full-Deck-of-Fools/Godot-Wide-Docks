#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "addons" / "wide_docks"
SCRIPT = ADDON / "wide_docks.gd"
CFG = ADDON / "plugin.cfg"
VERSION_FILE = ROOT / "VERSION"

LOCKED_FORBIDDEN_CODE_PATTERNS = {
    "editor-control reparenting": r"\breparent\s*\(",
    "global input interception": r"^\s*func\s+_input\s*\(",
    "per-frame correction loop": r"^\s*func\s+_process\s*\(",
    "split_offsets mutation/use": r"\bsplit_offsets\b",
    "parallel ScreenDrag path": r"\bInputEventScreenDrag\b",
}

REQUIRED_CODE_PATTERNS = {
    "native dragger gui_input hook": r"\.gui_input\.connect\s*\(",
    "internal center cap": r"_center_split\.custom_maximum_size\s*=",
    "center minimum invalidation": r"_center_container\.update_minimum_size\s*\(",
    "post-sort visual latch": r"_latch_internal_center_to_actual_width\s*\(",
}

REQUIRED_FILES = [
    ROOT / "README.md",
    ROOT / "LICENSE",
    ROOT / "CHANGELOG.md",
    ROOT / "CONTRIBUTING.md",
    ROOT / ".gitignore",
    ROOT / ".gitattributes",
    ADDON / "README.md",
    ADDON / "LICENSE",
    CFG,
    SCRIPT,
]


def executable_source(text: str) -> str:
    return "\n".join(
        line for line in text.splitlines()
        if not line.lstrip().startswith("#")
    )


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)


def check() -> str:
    for path in REQUIRED_FILES:
        if not path.is_file():
            fail(f"missing required file: {path.relative_to(ROOT)}")

    version = VERSION_FILE.read_text(encoding="utf-8").strip()
    cfg = CFG.read_text(encoding="utf-8")
    source = SCRIPT.read_text(encoding="utf-8")
    code = executable_source(source)

    if f'version="{version}"' not in cfg:
        fail("plugin.cfg version does not match VERSION")

    if 'name="Wide Docks"' not in cfg:
        fail("plugin.cfg name is not Wide Docks")

    root_license = (ROOT / "LICENSE").read_text(encoding="utf-8")
    addon_license = (ADDON / "LICENSE").read_text(encoding="utf-8")

    if not root_license.startswith("FDOF Tooling Attribution License 1.0"):
        fail("root LICENSE is not the FDOF Tooling Attribution License 1.0")

    if root_license != addon_license:
        fail("root and addon LICENSE files differ")

    for label, pattern in LOCKED_FORBIDDEN_CODE_PATTERNS.items():
        if re.search(pattern, code, flags=re.MULTILINE):
            fail(f"locked v1 invariant violated: {label}")

    for label, pattern in REQUIRED_CODE_PATTERNS.items():
        if not re.search(pattern, code, flags=re.MULTILINE):
            fail(f"locked v1 behavior missing: {label}")

    print(f"PASS: Wide Docks {version} release checks")
    print("PASS: locked v1 architecture preserved")
    return version


def package(version: str) -> Path:
    out_dir = ROOT / "dist"
    out_dir.mkdir(exist_ok=True)
    output = out_dir / f"wide-docks-v{version}.zip"

    if output.exists():
        output.unlink()

    with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as zf:
        for path in sorted(ADDON.rglob("*")):
            if path.is_file():
                zf.write(path, path.relative_to(ROOT))

    print(f"PACKAGED: {output.relative_to(ROOT)}")
    return output


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--package",
        action="store_true",
        help="also create a plugin-only release ZIP under dist/",
    )
    args = parser.parse_args()

    version = check()
    if args.package:
        package(version)


if __name__ == "__main__":
    main()
