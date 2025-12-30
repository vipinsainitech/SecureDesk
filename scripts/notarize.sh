#!/bin/bash

# SecureDesk Notarization Script
# This script builds, signs, and notarizes the app for distribution
#
# Prerequisites:
# - Xcode Command Line Tools
# - Valid Developer ID Application certificate
# - App-specific password stored in keychain
#
# Usage: ./scripts/notarize.sh [--skip-build]

set -e

# Configuration
APP_NAME="SecureDesk"
BUNDLE_ID="com.kf.SecureDesk"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
ARCHIVE_PATH="${BUILD_DIR}/${APP_NAME}.xcarchive"
EXPORT_PATH="${BUILD_DIR}/export"
DMG_PATH="${BUILD_DIR}/${APP_NAME}.dmg"

# Developer ID (set these via environment variables or modify here)
TEAM_ID="${TEAM_ID:-ZTB426F89W}"
APPLE_ID="${APPLE_ID:-your-apple-id@example.com}"
KEYCHAIN_PROFILE="${KEYCHAIN_PROFILE:-SecureDesk-Notarize}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse arguments
SKIP_BUILD=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Clean previous builds
log_info "Cleaning previous builds..."
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Build and archive
if [ "$SKIP_BUILD" = false ]; then
    log_info "Building and archiving ${APP_NAME}..."
    xcodebuild archive \
        -project "${PROJECT_DIR}/${APP_NAME}.xcodeproj" \
        -scheme "${APP_NAME}" \
        -archivePath "${ARCHIVE_PATH}" \
        -configuration Release \
        CODE_SIGN_STYLE=Automatic \
        DEVELOPMENT_TEAM="${TEAM_ID}"
else
    log_info "Skipping build (--skip-build flag set)"
fi

# Export the archive
log_info "Exporting archive..."
cat > "${BUILD_DIR}/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>${TEAM_ID}</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
EOF

xcodebuild -exportArchive \
    -archivePath "${ARCHIVE_PATH}" \
    -exportPath "${EXPORT_PATH}" \
    -exportOptionsPlist "${BUILD_DIR}/ExportOptions.plist"

APP_PATH="${EXPORT_PATH}/${APP_NAME}.app"

# Verify code signature
log_info "Verifying code signature..."
codesign --verify --deep --strict --verbose=2 "${APP_PATH}"

# Create DMG
log_info "Creating DMG..."
hdiutil create -volname "${APP_NAME}" \
    -srcfolder "${APP_PATH}" \
    -ov -format UDZO \
    "${DMG_PATH}"

# Sign the DMG
log_info "Signing DMG..."
codesign --sign "Developer ID Application" --options runtime "${DMG_PATH}"

# Notarize
log_info "Submitting for notarization..."
log_info "This may take several minutes..."

# Store credentials in keychain (run once manually):
# xcrun notarytool store-credentials "SecureDesk-Notarize" \
#     --apple-id "your-apple-id@example.com" \
#     --team-id "ZTB426F89W" \
#     --password "app-specific-password"

xcrun notarytool submit "${DMG_PATH}" \
    --keychain-profile "${KEYCHAIN_PROFILE}" \
    --wait

# Staple the notarization ticket
log_info "Stapling notarization ticket..."
xcrun stapler staple "${DMG_PATH}"

# Verify notarization
log_info "Verifying notarization..."
spctl --assess --type open --context context:primary-signature -v "${DMG_PATH}"

log_info "✅ Build complete!"
log_info "Output: ${DMG_PATH}"
echo ""
log_info "To set up notarization credentials, run:"
echo "  xcrun notarytool store-credentials \"${KEYCHAIN_PROFILE}\" \\"
echo "      --apple-id \"${APPLE_ID}\" \\"
echo "      --team-id \"${TEAM_ID}\" \\"
echo "      --password \"<app-specific-password>\""
