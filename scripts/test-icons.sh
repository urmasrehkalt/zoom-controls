#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
export CLANG_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/zooom-clang"
test_binary="${TMPDIR:-/tmp}/zooom-icon-tests"
swiftc -module-cache-path "${TMPDIR:-/tmp}/zooom-build/arm64-apple-macosx/release/ModuleCache" -target arm64-apple-macosx13.0 Sources/Zooom/MenuIcon.swift Tests/IconTests/main.swift -o "$test_binary"
"$test_binary" "${1:-dist/Zooom.app}"
