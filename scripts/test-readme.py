#!/usr/bin/env python3
"""Validate README links and user-facing instructions against this checkout."""
import re
from pathlib import Path

root = Path(__file__).resolve().parent.parent
readme = (root / "README.md").read_text()
app = (root / "Sources/Zooom/main.swift").read_text()
build = (root / "scripts/build-app.sh").read_text()
package = (root / "Package.swift").read_text()
failures = []


def check(condition, message):
    print(("PASS: " if condition else "FAIL: ") + message)
    if not condition:
        failures.append(message)


for target in re.findall(r"\[[^\]]+\]\(([^)]+)\)", readme):
    if "://" not in target and not target.startswith("#"):
        check((root / target.split("#", 1)[0]).exists(), "Local link: " + target)

for block in re.findall(r"```sh\n(.*?)```", readme, re.S):
    for script in re.findall(r"(?:\./|python3 )(scripts/[\w.-]+)", block):
        check((root / script).is_file(), "Documented command: " + script)

check("kVK_Escape" in app and "UInt32(controlKey)" in app
      and "**Control + Escape**" in readme, "Main shortcut matches implementation")
for label in ["Restore controls", "Restore and quit", "Hide / restore controls"]:
    check(label in app and label in readme, "Menu label: " + label)
check('dist/Zooom.app' in build and 'dist/Zooom.app' in readme,
      "Build output matches installation instructions")
check('swift-tools-version: 5.9' in package and '.macOS(.v13)' in package
      and 'Swift 5.9' in readme and 'macOS 13' in readme,
      "Requirements match package")
check('complete live Zoom screen-sharing session has not been verified' in readme,
      "Live-validation status is explicit")
check(not re.search(r"/(?:Users|home)/[^\s/]+|[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}", readme),
      "README has no personal home paths or email addresses")
raise SystemExit(bool(failures))
