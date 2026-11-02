#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
# Standalone assertions work with Command Line Tools, where XCTest may be absent.
export CLANG_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/zooom-clang"
swift run --disable-sandbox --scratch-path "${TMPDIR:-/tmp}/zooom-build" ZooomCoreTests
