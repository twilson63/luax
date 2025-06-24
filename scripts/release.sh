#!/bin/bash

# Hype Release Automation Script
# Usage: ./scripts/release.sh <version>
# Example: ./scripts/release.sh 1.3.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if version is provided
if [ $# -eq 0 ]; then
    log_error "Version number required"
    echo "Usage: $0 <version>"
    echo "Example: $0 1.3.0"
    exit 1
fi

VERSION="$1"

# Validate version format (basic semver check)
if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log_error "Invalid version format. Use semantic versioning (e.g., 1.2.3)"
    exit 1
fi

log_info "Starting release process for version $VERSION"

# Check if we're in the right directory
if [ ! -f "main.go" ] || [ ! -f "go.mod" ]; then
    log_error "Must be run from the hype project root directory"
    exit 1
fi

# Check if working directory is clean
if [ -n "$(git status --porcelain)" ]; then
    log_warning "Working directory is not clean. Uncommitted changes:"
    git status --short
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Aborting release"
        exit 1
    fi
fi

# Check if we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    log_warning "Not on main branch (currently on: $CURRENT_BRANCH)"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Aborting release"
        exit 1
    fi
fi

# Update version in main.go
log_info "Updating version in main.go"
sed -i.bak "s/version = \".*\"/version = \"$VERSION\"/" main.go
rm main.go.bak
log_success "Updated version to $VERSION in main.go"

# Update version in install scripts
log_info "Updating install scripts"
if [ -f "install-mac.sh" ]; then
    sed -i.bak "s/VERSION=\"v.*\"/VERSION=\"v$VERSION\"/" install-mac.sh
    rm install-mac.sh.bak
    log_success "Updated install-mac.sh to v$VERSION"
fi

# Build for all platforms
log_info "Building executables for all platforms"

# Clean previous builds
rm -f hype-*

# Build macOS Intel
log_info "Building for macOS Intel (amd64)"
GOOS=darwin GOARCH=amd64 go build -ldflags "-X main.version=$VERSION -X main.date=$(date -u +%Y-%m-%dT%H:%M:%SZ)" -o hype-darwin-amd64 .

# Build macOS Apple Silicon
log_info "Building for macOS Apple Silicon (arm64)"
GOOS=darwin GOARCH=arm64 go build -ldflags "-X main.version=$VERSION -X main.date=$(date -u +%Y-%m-%dT%H:%M:%SZ)" -o hype-darwin-arm64 .

# Build Linux
log_info "Building for Linux (amd64)"
GOOS=linux GOARCH=amd64 go build -ldflags "-X main.version=$VERSION -X main.date=$(date -u +%Y-%m-%dT%H:%M:%SZ)" -o hype-linux-amd64 .

# Build Windows
log_info "Building for Windows (amd64)"
GOOS=windows GOARCH=amd64 go build -ldflags "-X main.version=$VERSION -X main.date=$(date -u +%Y-%m-%dT%H:%M:%SZ)" -o hype-windows-amd64.exe .

log_success "All binaries built successfully"

# Test local binary
log_info "Testing local binary version"
go build -ldflags "-X main.version=$VERSION -X main.date=$(date -u +%Y-%m-%dT%H:%M:%SZ)" -o hype-test .
BINARY_VERSION=$(./hype-test version | head -n1 | awk '{print $2}')
if [ "$BINARY_VERSION" != "$VERSION" ]; then
    log_error "Version mismatch! Expected: $VERSION, Got: $BINARY_VERSION"
    exit 1
fi
rm hype-test
log_success "Version test passed"

# Commit changes
log_info "Committing version changes"
git add main.go install-mac.sh
git commit -m "Bump version to $VERSION

- Update version in main.go
- Update install scripts to download v$VERSION

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Create and push tag
log_info "Creating git tag v$VERSION"
git tag "v$VERSION"

# Push changes and tags
log_info "Pushing changes and tags to GitHub"
git push origin main
git push origin "v$VERSION"

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    log_warning "GitHub CLI (gh) not found. Please create the release manually:"
    echo "1. Go to https://github.com/twilson63/hype/releases/new"
    echo "2. Tag: v$VERSION"
    echo "3. Upload binaries: hype-darwin-amd64, hype-darwin-arm64, hype-linux-amd64, hype-windows-amd64.exe"
    echo "4. Add release notes"
    exit 0
fi

# Create GitHub release
log_info "Creating GitHub release"
RELEASE_NOTES="## 🎉 Hype v$VERSION

### ✨ Features in this Release
- Enhanced mobile documentation experience
- Improved responsive design for all screen sizes
- Better touch targets and mobile navigation

### 🔧 Technical Improvements
- Updated version handling for better release tracking
- Automated release process improvements

### 📱 Mobile Enhancements
- Touch-friendly interface elements
- Optimized typography for mobile readability
- Better code block handling on small screens

### 📦 Installation
- **macOS (Easy Install):** \`curl -sSL https://raw.githubusercontent.com/twilson63/hype/main/install-mac.sh | bash\`
- **Manual Download:** Download from [GitHub Releases](https://github.com/twilson63/hype/releases/tag/v$VERSION)

Built with ❤️ for the Lua community."

gh release create "v$VERSION" \
    --title "v$VERSION - Enhanced Mobile Experience" \
    --notes "$RELEASE_NOTES" \
    hype-darwin-amd64 \
    hype-darwin-arm64 \
    hype-linux-amd64 \
    hype-windows-amd64.exe

log_success "GitHub release created successfully"

# Verify installation
log_info "Verifying release installation"
sleep 5  # Wait for GitHub to process the release

# Test that the release is accessible
RELEASE_URL="https://github.com/twilson63/hype/releases/tag/v$VERSION"
if curl -f -s "$RELEASE_URL" > /dev/null; then
    log_success "Release is accessible at: $RELEASE_URL"
else
    log_warning "Release may not be immediately accessible"
fi

# Cleanup
log_info "Cleaning up build artifacts"
rm -f hype-*

log_success "Release $VERSION completed successfully!"
log_info "Next steps:"
echo "1. Test the install script: curl -sSL https://raw.githubusercontent.com/twilson63/hype/main/install-mac.sh | bash"
echo "2. Verify the release page: https://github.com/twilson63/hype/releases/tag/v$VERSION"
echo "3. Test that 'hype version' shows the correct version"
echo "4. Update any documentation that references the old version"

log_info "Release metrics to track:"
echo "- Download count after 24 hours"
echo "- GitHub stars/forks increase"
echo "- Issues reported post-release"