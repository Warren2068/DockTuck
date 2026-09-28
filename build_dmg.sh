#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

APP_PATH="build/Build/Products/Release/DockTuck.app"
DMG_PATH="dist/DockTuck.dmg"
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/DockTuck-dmg.XXXXXX")"
trap 'rm -rf "$TEMP_DIR"' EXIT

xcodebuild -project DockTuck.xcodeproj -scheme DockTuck \
  -configuration Release -destination 'generic/platform=macOS' \
  -derivedDataPath build ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO -quiet build

codesign --force --deep --sign "$CODE_SIGN_IDENTITY" "$APP_PATH"
codesign --verify --deep --strict "$APP_PATH"

ARCHITECTURES="$(lipo -archs "$APP_PATH/Contents/MacOS/DockTuck")"
if [[ "$ARCHITECTURES" != *arm64* || "$ARCHITECTURES" != *x86_64* ]]; then
  echo "Expected arm64 and x86_64; found: $ARCHITECTURES" >&2
  exit 1
fi

STAGE_DIR="$TEMP_DIR/contents"
mkdir -p "$STAGE_DIR" dist
cp -R "$APP_PATH" "$STAGE_DIR/"
cp LICENSE "$STAGE_DIR/LICENSE"
cp assets/AppIcon.icns "$STAGE_DIR/.VolumeIcon.icns"
ln -s /Applications "$STAGE_DIR/Applications"
if command -v SetFile >/dev/null; then
  SetFile -a C "$STAGE_DIR" || true
fi

hdiutil create "$TEMP_DIR/DockTuck.dmg" -srcfolder "$STAGE_DIR" \
  -format UDZO -volname DockTuck -quiet
mv -f "$TEMP_DIR/DockTuck.dmg" "$DMG_PATH"
echo "DMG created successfully at $DMG_PATH ($ARCHITECTURES)"
