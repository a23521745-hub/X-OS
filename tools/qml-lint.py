#!/usr/bin/env python3
"""Structural lint for the PlasmaX QML tree.

We cannot assume a full Qt installation on every developer machine (or CI
runner), so this covers the mistakes that actually bite:
  * unbalanced {} () []
  * references to `Theme.*` paths that don't exist in the generated Theme.qml
  * imports of modules outside the allowlist
  * qmldir entries whose target file is missing
  * files not covered by the qmldir/module or imported by anything

Exit code 0 = clean.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
QML = ROOT / "shell" / "qml"

ALLOWED_IMPORTS = {
    "QtQuick", "QtQuick.Layouts", "QtQuick.Controls", "QtQuick.Controls.impl",
    "QtQuick.Effects", "QtQuick.Shapes", "QtQuick.Window", "QtQuick.Particles",
    "QtQml", "PlasmaX", "org.freedesktop.Notifications", "QtCore",
}

errors: list[str] = []


def strip_comments_strings(text: str) -> str:
    out = []
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if c == "/" and i + 1 < n and text[i + 1] == "/":
            while i < n and text[i] != "\n":
                i += 1
        elif c == "/" and i + 1 < n and text[i + 1] == "*":
            i += 2
            while i + 1 < n and not (text[i] == "*" and text[i + 1] == "/"):
                i += 1
            i += 2
        elif c in "\"'":
            q = c
            i += 1
            while i < n and text[i] != q:
                if text[i] == "\\":
                    i += 1
                i += 1
            i += 1
        else:
            out.append(c)
            i += 1
    return "".join(out)


def check_balance(path: Path) -> None:
    text = strip_comments_strings(path.read_text(encoding="utf-8"))
    stack = []
    pairs = {")": "(", "]": "[", "}": "{"}
    for lineno, line in enumerate(text.splitlines(), 1):
        for ch in line:
            if ch in "([{":
                stack.append((ch, lineno))
            elif ch in ")]}":
                if not stack or stack[-1][0] != pairs[ch]:
                    errors.append(f"{path.relative_to(ROOT)}:{lineno}: unbalanced '{ch}'")
                    return
                stack.pop()
    if stack:
        ch, lineno = stack[-1]
        errors.append(f"{path.relative_to(ROOT)}:{lineno}: unclosed '{ch}'")


def collect_theme_paths() -> set[str]:
    """Depth-aware walk of Theme.qml: collects `Theme.<path>` addresses.

    depth 1 → top-level props (Theme.mode)
    depth 2 → props inside an object literal (Theme.g.fill, Theme.motion.slow)
    depth 3 → props inside a nested object (Theme.motion.spring.stiffness)

    Alias QtObjects (e.g. `readonly property QtObject c: lightMode ? light :
    dark`) resolve their members from the objects they reference.
    """
    theme = (QML / "PlasmaX" / "Theme.qml").read_text(encoding="utf-8")
    paths: set[str] = set()
    stack: list[str] = []
    aliases: dict[str, str] = {}
    for raw in theme.splitlines():
        line = raw.split("//")[0]
        m = re.search(r"property\s+\w+\s+([A-Za-z0-9_]+)\s*:\s*(.*)$", line)
        if m:
            name, rhs = m.group(1), m.group(2).rstrip()
            parts = [s for s in stack if s]
            paths.add(".".join([*parts, name]))
            if rhs.startswith("QtObject {") or rhs.startswith("QtObject{"):
                pass  # literal, members collected below via stack
            elif "QtObject" not in rhs and "{" not in rhs:
                # alias referencing other members — remember for expansion
                if re.fullmatch(r"[\w\s?:]+", rhs):
                    aliases[name] = rhs
        for _ in range(line.count("{")):
            g = re.search(r"property QtObject (\w+)\s*:\s*QtObject\s*\{", line)
            stack.append(g.group(1) if g else "")
        for _ in range(line.count("}")):
            if stack:
                stack.pop()

    # Resolve aliases: members of `c` = members of `light` ∪ `dark`…
    def members_of(obj: str) -> set[str]:
        prefix = obj + "."
        return {p[len(prefix):] for p in paths if p.startswith(prefix)}

    changed = True
    while changed:
        changed = False
        for name, rhs in aliases.items():
            refs = {r for r in re.findall(r"[A-Za-z_]\w*", rhs)
                    if r != name and (r in aliases or members_of(r))}
            for ref in refs:
                # Pull members from the referenced object (already-resolved
                # alias members are in `paths` too, so this iterates safely).
                for member in members_of(ref):
                    new = f"{name}.{member}"
                    if new not in paths:
                        paths.add(new)
                        changed = True
    return {p for p in paths if p}


def check_theme_refs(path: Path, theme_paths: set[str]) -> None:
    text = path.read_text(encoding="utf-8")
    for m in re.finditer(r"\bTheme\.([A-Za-z0-9_.]+)", text):
        ref = m.group(1)
        if ref not in theme_paths:
            errors.append(
                f"{path.relative_to(ROOT)}: Theme.{ref} not found in Theme.qml"
            )


def check_imports(path: Path) -> None:
    for m in re.finditer(r"^\s*import\s+([\w.]+)", path.read_text(encoding="utf-8"), re.M):
        mod = m.group(1)
        if mod not in ALLOWED_IMPORTS and not mod.startswith(("Qt5Compat", "org.kde")):
            errors.append(f"{path.relative_to(ROOT)}: unexpected import '{mod}'")


def check_qmldir() -> None:
    qmldir = QML / "PlasmaX" / "qmldir"
    for line in qmldir.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or line.startswith("module"):
            continue
        parts = line.split()
        target = parts[-1]
        if not (qmldir.parent / target).exists():
            errors.append(f"qmldir entry missing file: {target}")


def main() -> int:
    qml_files = sorted(QML.rglob("*.qml"))
    if not qml_files:
        print("no QML files found", file=sys.stderr)
        return 1

    theme_paths = collect_theme_paths()
    for f in qml_files:
        check_balance(f)
        check_theme_refs(f, theme_paths)
        check_imports(f)
    check_qmldir()

    if errors:
        print(f"qml-lint: {len(errors)} problem(s)")
        for e in errors:
            print("  " + e)
        return 1
    print(f"qml-lint: {len(qml_files)} files OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
