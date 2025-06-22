#!/bin/bash
# Code signing and notarization script for macOS binaries
# Requires: Apple Developer account, certificates, and app-specific password

DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)"
BUNDLE_ID="com.yourcompany.hype"
APP_PASSWORD="your-app-specific-password"

echo "Signing macOS binaries..."
codesign --force --verify --verbose --sign "$DEVELOPER_ID" dist/hype-darwin-amd64
codesign --force --verify --verbose --sign "$DEVELOPER_ID" dist/hype-darwin-arm64

echo "Creating zip for notarization..."
ditto -c -k --keepParent dist/hype-darwin-amd64 dist/hype-darwin-amd64.zip
ditto -c -k --keepParent dist/hype-darwin-arm64 dist/hype-darwin-arm64.zip

echo "Submitting for notarization..."
xcrun notarytool submit dist/hype-darwin-amd64.zip --bundle-id "$BUNDLE_ID" --apple-id "your-email@example.com" --password "$APP_PASSWORD" --wait
xcrun notarytool submit dist/hype-darwin-arm64.zip --bundle-id "$BUNDLE_ID" --apple-id "your-email@example.com" --password "$APP_PASSWORD" --wait

echo "Stapling notarization..."
xcrun stapler staple dist/hype-darwin-amd64
xcrun stapler staple dist/hype-darwin-arm64