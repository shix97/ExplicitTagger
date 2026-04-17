#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# build_app.sh  —  Builds ExplicitTagger.app
#
# Usage:
#   cd AdvisoryTagger        (the folder containing Package.swift)
#   bash build_app.sh
#
# Output:  ExplicitTagger.app  (in this folder, ready to run or move to /Applications)
# ─────────────────────────────────────────────────────────────────────────────
set -e

APP_NAME="ExplicitTagger"
BUNDLE_ID="com.ethanshicks.explicittagger"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_BUNDLE="$SCRIPT_DIR/$APP_NAME.app"
BINARY_PATH="$SCRIPT_DIR/.build/release/$APP_NAME"
ICON_SRC="$SCRIPT_DIR/Sources/ExplicitTagger/Resources/icon.png"

# ── 1. Build universal binary (Apple Silicon + Intel) ─────────────────────────
echo "🔨  Building $APP_NAME (Release — universal)..."
cd "$SCRIPT_DIR"

ARM_SCRATCH="$SCRIPT_DIR/.build-arm64"
X86_SCRATCH="$SCRIPT_DIR/.build-x86_64"
ARM_BIN="$ARM_SCRATCH/arm64-apple-macosx/release/$APP_NAME"
X86_BIN="$X86_SCRATCH/x86_64-apple-macosx/release/$APP_NAME"

echo "  → arm64..."
swift build -c release --arch arm64   --scratch-path "$ARM_SCRATCH"

echo "  → x86_64..."
swift build -c release --arch x86_64  --scratch-path "$X86_SCRATCH"

if [ ! -f "$ARM_BIN" ] || [ ! -f "$X86_BIN" ]; then
    echo "❌  One or both architecture binaries not found."
    echo "    arm64:  $ARM_BIN"
    echo "    x86_64: $X86_BIN"
    exit 1
fi

# Merge into a fat (universal) binary
mkdir -p "$(dirname "$BINARY_PATH")"
lipo -create -output "$BINARY_PATH" "$ARM_BIN" "$X86_BIN"
echo "🔗  Universal binary created at: $BINARY_PATH"

# ── 2. Assemble .app bundle ───────────────────────────────────────────────────
echo "📦  Assembling $APP_NAME.app..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BINARY_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy icon PNG so Bundle.main can find it at runtime
if [ -f "$ICON_SRC" ]; then
    cp "$ICON_SRC" "$APP_BUNDLE/Contents/Resources/icon.png"
fi

# Copy custom fonts so Bundle.main can register them at runtime
FONT_SRC="$SCRIPT_DIR/Sources/ExplicitTagger/Resources/AppleGaramond-Light.ttf"
if [ -f "$FONT_SRC" ]; then
    cp "$FONT_SRC" "$APP_BUNDLE/Contents/Resources/AppleGaramond-Light.ttf"
fi

# ── 3. Generate .icns (app icon shown in Finder / Dock) ───────────────────────
if [ -f "$ICON_SRC" ]; then
    echo "🎨  Generating app icon..."
    TMP_ICONSET=$(mktemp -d)/AppIcon.iconset
    mkdir -p "$TMP_ICONSET"

    for SIZE in 16 32 64 128 256 512; do
        sips -z $SIZE $SIZE "$ICON_SRC" --out "$TMP_ICONSET/icon_${SIZE}x${SIZE}.png"        > /dev/null 2>&1
    done
    # @2x variants
    sips -z 32  32  "$ICON_SRC" --out "$TMP_ICONSET/icon_16x16@2x.png"  > /dev/null 2>&1
    sips -z 64  64  "$ICON_SRC" --out "$TMP_ICONSET/icon_32x32@2x.png"  > /dev/null 2>&1
    sips -z 256 256 "$ICON_SRC" --out "$TMP_ICONSET/icon_128x128@2x.png"> /dev/null 2>&1
    sips -z 512 512 "$ICON_SRC" --out "$TMP_ICONSET/icon_256x256@2x.png"> /dev/null 2>&1
    sips -z 1024 1024 "$ICON_SRC" --out "$TMP_ICONSET/icon_512x512@2x.png" > /dev/null 2>&1

    iconutil -c icns "$TMP_ICONSET" -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
    rm -rf "$(dirname "$TMP_ICONSET")"
fi

# ── 4. Write Info.plist ───────────────────────────────────────────────────────
cat > "$APP_BUNDLE/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>ExplicitTagger</string>
    <key>CFBundleDisplayName</key>
    <string>ExplicitTagger</string>
    <key>CFBundleVersion</key>
    <string>1.1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.1</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHumanReadableCopyright</key>
    <string>© 2026 Shix</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
</dict>
</plist>
PLIST

# ── 5. Ad-hoc code sign (required to run on Apple Silicon) ───────────────────
echo "✍️   Signing..."
codesign --force --deep --sign - "$APP_BUNDLE"

# ── 6. Done ───────────────────────────────────────────────────────────────────
echo ""
echo "✅  Done!  →  $APP_BUNDLE"
echo ""
echo "    • Double-click to launch, or"
echo "    • Drag to /Applications to install system-wide."
echo ""
echo "    First launch tip: if Gatekeeper blocks it,"
echo "    right-click → Open → Open to allow it once."
