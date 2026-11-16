#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
export CLANG_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/zooom-clang"
build_dir="${TMPDIR:-/tmp}/zooom-build"
swift build --disable-sandbox --scratch-path "$build_dir" -c release --product Zooom
bin_dir=$(swift build --disable-sandbox --scratch-path "$build_dir" -c release --show-bin-path)
app_dir="$PWD/dist/Zooom.app"
mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
cp assets/Zooom.icns "$app_dir/Contents/Resources/Zooom.icns"
cp "$bin_dir/Zooom" "$app_dir/Contents/MacOS/Zooom"
cat > "$app_dir/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>Zooom</string>
<key>CFBundleIdentifier</key><string>ee.urmasrehkalt.zooom</string>
<key>CFBundleIconFile</key><string>Zooom</string>
<key>CFBundleName</key><string>Zooom</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$app_dir"
printf '%s\n' "$app_dir"
