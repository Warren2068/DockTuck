#!/bin/bash

# Set variables
APP_NAME="DockTuck"
APP_PATH="build/Build/Products/Release/$APP_NAME.app"
DMG_NAME="DockTuck.dmg"
DMG_PATH="dist/$DMG_NAME"
TEMP_DIR="temp_dmg_contents"                                     # Temporary directory for DMG contents
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}" # Use environment variable or fallback to ad-hoc

# Create the build directory if it doesn't exist
mkdir -p build

# Clean previous builds
xcodebuild clean -scheme "$APP_NAME" -derivedDataPath build

# Build a universal binary (arm64 + x86_64) — ONLY_ACTIVE_ARCH=NO forces both
# slices on Intel hosts that would otherwise produce x86_64-only.
if ! xcodebuild -scheme "$APP_NAME" -configuration Release -derivedDataPath build \
    ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO; then
  echo "Build failed. Exiting."
  exit 1
fi

# Code sign the app
if ! codesign --deep --force --verify --verbose --sign "$CODE_SIGN_IDENTITY" "$APP_PATH"; then
  echo "Code signing failed. Exiting."
  exit 1
fi

# Create the dist directory if it doesn't exist
mkdir -p dist

# Create a temporary folder for DMG contents
mkdir -p "$TEMP_DIR"

# Copy the app and the license that must travel with every copy.
cp -R "$APP_PATH" "$TEMP_DIR/"
cp LICENSE "$TEMP_DIR/LICENSE"

# Finder uses this as the disk image thumbnail.
cp assets/AppIcon.icns "$TEMP_DIR/.VolumeIcon.icns"
if command -v SetFile >/dev/null; then
  SetFile -a C "$TEMP_DIR" || true
fi

# Create an alias to the Applications folder
ln -s /Applications "$TEMP_DIR/Applications"

# Create a DMG file
hdiutil create "$DMG_PATH" -srcfolder "$TEMP_DIR" -format UDZO -volname "$APP_NAME"

# Clean up temporary files
rm -rf "$TEMP_DIR"

# Check if the DMG was created successfully
if [ -f "$DMG_PATH" ]; then
  echo "DMG created successfully at $DMG_PATH"
else
  echo "Failed to create DMG."
  exit 1
fi
