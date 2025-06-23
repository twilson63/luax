#!/bin/bash

# Build script that includes version information from git

set -e

# Get version information from git
VERSION=$(git describe --tags --always --dirty)
COMMIT=$(git rev-parse --short HEAD)
DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# If we're exactly on a tag, use just the tag
if git describe --exact-match --tags HEAD 2>/dev/null; then
    VERSION=$(git describe --exact-match --tags HEAD)
fi

echo "Building hype $VERSION (commit: $COMMIT, date: $DATE)"

# Build with version information
go build -ldflags "
    -X main.version=$VERSION 
    -X main.commit=$COMMIT 
    -X main.date=$DATE
" -o hype .

echo "Build complete: ./hype"