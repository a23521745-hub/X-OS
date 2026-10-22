#!/usr/bin/env python3
"""X-OS test runner (no external dependencies).

Covers the parts that must never drift:
  1. token generation is in sync (--check)
  2. QML tree passes structural lint
  3. live-build / session / packaging files reference each other correctly
  4. icon sprite order matches IconGlyph.names
  5. brand safety: no third-party logos/trademarks in the tree
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
failures: list[str] = []


def ok(name: str, cond: bool, detail: str = "") -> None:
    status = "PASS" if cond else "FAIL"
    print(f"[{status}] {name}" + (f" — {detail}" if detail and not cond else ""))
    if not cond:
        failures.append(f"{name}: {detail}")


def run(cmd: list[str]) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)


def test_tokens_in_sync() -> None:
    r = run([sys.executable, "tools/gen-tokens.py", "--check"])
    ok("tokens in sync", r.returncode == 0, r.stderr.strip())


def test_qml_lint() -> None:
    r = run([sys.executable, "tools/qml-lint.py"])
    ok("qml structural lint", r.returncode == 0, r.stdout + r.stderr)


def test_icon_sprite_order() -> None:
    icon_glyph = (ROOT / "shell/qml/PlasmaX/components/IconGlyph.qml").read_text(encoding="utf-8")
    m = re.search(r'readonly property var names: \[(.*?)\]', icon_glyph, re.S)
    ok("IconGlyph names block present", bool(m))
    if not m:
        return
    names = re.findall(r'"([^"]+)"', m.group(1))
    svg = (ROOT / "design/branding/icons.svg").read_text(encoding="utf-8")
    # Each sprite cell must exist as a translate(i,0) group comment or group.
    cells = len(re.findall(r'transform="translate\((\d+),0\)"', svg))
    ok("sprite cell count matches names", cells == len(names),
       f"{cells} cells vs {len(names)} names")
    # The ordered comment header must list the same names in the same order.
    # Numbers appear in the prose too ("19 symbols", "24 px"), so only accept
    # a run that counts up strictly from 0.
    header = re.search(r"<!--(.*?)-->", svg, re.S)
    if header:
        found: list[str] = []
        for n, word in re.findall(r"\b(\d+)\s+([a-z]+)\b", header.group(1)):
            if int(n) == len(found):
                found.append(word)
        ok("sprite comment covers every name in order",
           found == names, f"{found[:5]}… vs {names[:5]}…")


def test_session_files() -> None:
    root = ROOT / "system/live-build/config/includes.chroot"
    session = root / "usr/share/wayland-sessions/plasmax.desktop"
    ok("plasmax wayland session exists", session.exists())
    if session.exists():
        text = session.read_text(encoding="utf-8")
        ok("session Exec points at xos-session",
           "Exec=" in text and "xos-session" in text, text[:200])
    ok("xos-session script exists",
       (root / "usr/local/bin/xos-session").exists())
    lists = ROOT / "system/live-build/config/package-lists/xos.list.chroot"
    ok("package list exists", lists.exists())
    if lists.exists():
        pkgs = lists.read_text(encoding="utf-8")
        for need in ("sddm", "kwin", "layer-shell-qt", "qt6-wayland", "polkitd"):
            ok(f"package list has {need}", need in pkgs)
    # Canlı açılış için includes.chroot kritik dosyalar
    sddm = root / "etc/sddm.conf.d/10-xos.conf"
    ok("sddm autologin conf exists", sddm.exists())
    if sddm.exists():
        conf = sddm.read_text(encoding="utf-8")
        ok("sddm autologins into plasmax as xos",
           "User=xos" in conf and "Session=plasmax.desktop" in conf)
    # .gitignore'daki *.d kuralı sddm.conf.d DİZİNİNİ yutup commit'e
    # sokmamıştı: dosya git'e tracked olmalı (repo dışındaysa atla).
    r = run(["git", "ls-files", "--error-unmatch",
             "system/live-build/config/includes.chroot/etc/sddm.conf.d/10-xos.conf"])
    if "not a git repository" in (r.stderr + r.stdout):
        pass  # git yoksa bu kontrol yapılamaz
    else:
        ok("sddm conf is tracked in git", r.returncode == 0, r.stderr.strip())
    ok("hostname include exists", (root / "etc/hostname").exists())
    kbd = root / "etc/default/keyboard"
    ok("xkb default keyboard include exists", kbd.exists())
    if kbd.exists():
        ok("default keyboard layout is tr",
           'XKBLAYOUT="tr"' in kbd.read_text(encoding="utf-8"))
    cfg = (ROOT / "system/live-build/auto/config").read_text(encoding="utf-8")
    ok("auto/config creates username=xos live user", "username=xos" in cfg)
    ok("live boot requests tr locale (live-config)", "locales=tr_TR.UTF-8" in cfg)


def test_brand_safety() -> None:
    # Assembled at runtime so this runner doesn't flag itself.
    banned = [
        "apple" + ".com", "apple" + " logo", "",
        "linear" + ".app", "linear" + " app",
        "apple" + " inc", "developer." + "apple",
    ]
    hits = []
    for pattern_dir in ("design", "shell", "docs", "system", "tools", "integrations", ".github"):
        d = ROOT / pattern_dir
        if not d.exists():
            continue
        for f in d.rglob("*"):
            if not f.is_file() or f.suffix not in {".qml", ".md", ".svg", ".html", ".css",
                                                   ".py", ".sh", ".yml", ".json", ".js", ".txt",
                                                   ".desktop", ".list", ".conf"}:
                continue
            if f.name == Path(__file__).name:
                continue  # this runner assembles the banned list at runtime
            try:
                text = f.read_text(encoding="utf-8", errors="ignore").lower()
            except OSError:
                continue
            for b in banned:
                if b.lower() in text:
                    # Allow *legal* mentions in docs/BRANDING.md (policy text).
                    if "docs/branding" in str(f) or "docs/design" in str(f):
                        continue
                    hits.append(f"{f.relative_to(ROOT)}: {b}")
    ok("no third-party logos/brand names in artifacts", not hits, "; ".join(hits[:5]))


def test_license_and_readme() -> None:
    ok("LICENSE is GPLv3", (ROOT / "LICENSE").read_text(encoding="utf-8").startswith(
        "                    GNU GENERAL PUBLIC LICENSE"))
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    ok("README mentions X-OS and PlasmaX", "X-OS" in readme and "PlasmaX" in readme)


def main() -> int:
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_") and callable(v)]
    for t in tests:
        try:
            t()
        except Exception as exc:  # noqa: BLE001 — surface as a failure
            ok(t.__name__, False, repr(exc))
    print()
    if failures:
        print(f"{len(failures)} test(s) failed")
        return 1
    print(f"All {len(tests)} test groups passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
