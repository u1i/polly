#!/bin/bash

# Configuration
APP_NAME="Polly"
APP_DIR="${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "Building ${APP_NAME}..."

# Clean previous build
rm -rf "${APP_DIR}"

# Create directories
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Copy Info.plist and Icon
cp Info.plist "${CONTENTS_DIR}/"
cp PollyIcon.icns "${RESOURCES_DIR}/AppIcon.icns"

# Generate raw template images directly into Resources (NSImage can find them here natively)
sips -z 22 22 logo-transparent.png --out "${RESOURCES_DIR}/ParrotTemplate.png"
sips -z 44 44 logo-transparent.png --out "${RESOURCES_DIR}/ParrotTemplate@2x.png"


# Compile Swift files
swiftc -o "${MACOS_DIR}/${APP_NAME}" \
    Main.swift \
    SettingsView.swift \
    AudioRecorder.swift \
    GroqAPI.swift \
    PasteManager.swift \
    OverlayManager.swift

# Check for success
if [ $? -eq 0 ]; then
    echo "Build successful! Created ${APP_DIR}."
    echo "You can now run: open ${APP_DIR}"
else
    echo "Build failed."
    exit 1
fi
