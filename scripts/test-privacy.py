#!/usr/bin/env python3
"""Check published history for personal references; no network access required."""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def git(*args):
    return subprocess.check_output(["git", "-C", str(ROOT), *args])


# This identifier must remain stable to preserve installed Accessibility access.
BUNDLE_ID = "ee.urmasrehkalt.zooom"
OWNER = BUNDLE_ID.split(".")[1]
EMAIL = re.compile(r"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}", re.I)
PERSONAL = re.compile(
    re.escape(OWNER) + r"|/(?:Users|home)/[^\s/]+|\b\w+ Local Signing\b",
    re.I,
)


def has_personal_reference(text):
    text = text.replace(BUNDLE_ID, "")
    return bool(PERSONAL.search(text)) or any(
        not email.lower().endswith((".invalid", "@users.noreply.github.com"))
        for email in EMAIL.findall(text)
    )


def main():
    failures = []
    # Internal editor snapshots and reflogs are local, not published branches.
    refs = git("for-each-ref", "--format=%(refname)", "refs/heads",
               "refs/remotes", "refs/tags").decode().splitlines()
    if not refs:
        raise RuntimeError("No branch or tag history found")
    commits = git("log", "--format=%H%x09%an <%ae> %cn <%ce>%x09%B%x00",
                  *refs).decode()
    for record in commits.split("\0"):
        if record.strip() and has_personal_reference(record):
            failures.append("commit metadata " + record.strip().split("\t")[0])
    blobs = 0
    for entry in git("rev-list", "--objects", *refs).decode().splitlines():
        oid, _, path = entry.partition(" ")
        if PERSONAL.search(path):
            failures.append("path in object " + oid)
        if git("cat-file", "-t", oid).strip() != b"blob":
            continue
        blobs += 1
        data = git("cat-file", "blob", oid)
        if has_personal_reference(data.decode("utf-8", errors="replace")):
            failures.append("file content " + oid + " (" + path + ")")
    # Include edits not yet committed, while respecting the tracked-file boundary.
    for raw_path in git("ls-files", "-z").split(b"\0"):
        if not raw_path:
            continue
        path = ROOT / raw_path.decode()
        if path.is_file() and has_personal_reference(path.read_text(errors="replace")):
            failures.append("working file " + raw_path.decode())
    for failure in failures:
        print("FAIL: " + failure)
    if failures:
        return 1
    print(f"PASS: Privacy check across {len(refs)} refs and {blobs} unique blobs")
    return 0


if __name__ == "__main__":
    sys.exit(main())
