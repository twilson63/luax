#!/bin/bash
# Pre-release validation script for Hype
# Ensures everything is ready for a release

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

log_info() {
    echo -e "${BLUE}[CHECK]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARNINGS++))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((ERRORS++))
}

echo -e "${BLUE}🔍 Hype Pre-Release Validation${NC}"
echo "================================"

# Check 1: Git status
log_info "Checking git status..."
if [ -n "$(git status --porcelain)" ]; then
    log_warning "Working directory has uncommitted changes"
    git status --short
else
    log_success "Working directory is clean"
fi

# Check 2: Current branch
log_info "Checking current branch..."
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    log_warning "Not on main branch (currently on: $CURRENT_BRANCH)"
else
    log_success "On main branch"
fi

# Check 3: Go version
log_info "Checking Go version..."
GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
if [[ "$GO_VERSION" < "1.23" ]]; then
    log_error "Go version $GO_VERSION is too old (require 1.23+)"
else
    log_success "Go version $GO_VERSION is compatible"
fi

# Check 4: Build test
log_info "Testing build..."
if make build > /dev/null 2>&1; then
    log_success "Build successful"
else
    log_error "Build failed"
fi

# Check 5: Test execution (if tests exist)
log_info "Checking for tests..."
if [ -f "Makefile" ] && grep -q "test:" Makefile; then
    log_info "Running tests..."
    if make test > /dev/null 2>&1; then
        log_success "Tests passed"
    else
        log_error "Tests failed"
    fi
else
    log_warning "No tests found in Makefile"
fi

# Check 6: Version consistency
log_info "Checking version consistency..."
MAIN_VERSION=$(grep 'version = ' main.go | sed 's/.*version = "\([^"]*\)".*/\1/')
INSTALL_VERSIONS=$(grep -o 'hype-v[0-9]\+\.[0-9]\+\.[0-9]\+' install*.sh | sort -u)

echo "Version in main.go: $MAIN_VERSION"
echo "Versions in install scripts:"
echo "$INSTALL_VERSIONS"

EXPECTED_VERSION="hype-v$MAIN_VERSION"
if echo "$INSTALL_VERSIONS" | grep -q "$EXPECTED_VERSION"; then
    log_success "Version consistency check passed"
else
    log_error "Version mismatch between main.go and install scripts"
fi

# Check 7: Documentation references
log_info "Checking documentation version references..."
if [ -f "README.md" ]; then
    README_VERSIONS=$(grep -o 'hype-v[0-9]\+\.[0-9]\+\.[0-9]\+' README.md | sort -u)
    if [ -n "$README_VERSIONS" ]; then
        echo "Versions in README.md:"
        echo "$README_VERSIONS"
        if echo "$README_VERSIONS" | grep -q "$EXPECTED_VERSION"; then
            log_success "README.md version references are current"
        else
            log_warning "README.md may have outdated version references"
        fi
    else
        log_success "No version references found in README.md"
    fi
fi

# Check 8: Install script URLs
log_info "Checking install script download URLs..."
for script in install*.sh; do
    if [ -f "$script" ]; then
        URLS=$(grep -o 'https://github.com/[^/]*/[^/]*/releases/download/[^/]*/[^"]*' "$script")
        if [ -n "$URLS" ]; then
            echo "URLs in $script:"
            echo "$URLS" | while read url; do
                echo "  $url"
                # Extract version from URL
                URL_VERSION=$(echo "$url" | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+')
                if [ "$URL_VERSION" = "v$MAIN_VERSION" ]; then
                    log_success "URL version matches main.go version"
                else
                    log_warning "URL version ($URL_VERSION) differs from main.go (v$MAIN_VERSION)"
                fi
            done
        fi
    fi
done

# Check 9: GitHub CLI availability
log_info "Checking GitHub CLI availability..."
if command -v gh &> /dev/null; then
    GH_VERSION=$(gh version | head -1 | awk '{print $3}')
    log_success "GitHub CLI available (version $GH_VERSION)"
else
    log_warning "GitHub CLI not available - releases will need to be created manually"
fi

# Check 10: Latest tag
log_info "Checking latest git tag..."
LATEST_TAG=$(git tag --sort=-version:refname | head -1)
if [ -n "$LATEST_TAG" ]; then
    log_success "Latest tag: $LATEST_TAG"
    TAG_VERSION=$(echo "$LATEST_TAG" | sed 's/^v//')
    if [ "$TAG_VERSION" = "$MAIN_VERSION" ]; then
        log_warning "Current version ($MAIN_VERSION) matches latest tag - consider bumping version"
    else
        log_success "Version ($MAIN_VERSION) is different from latest tag ($TAG_VERSION)"
    fi
else
    log_warning "No git tags found"
fi

# Check 11: Makefile targets
log_info "Checking Makefile targets..."
if [ -f "Makefile" ]; then
    TARGETS=$(grep '^[a-zA-Z][^:]*:' Makefile | cut -d: -f1)
    echo "Available Makefile targets:"
    echo "$TARGETS" | sed 's/^/  /'
    
    # Check for essential targets
    if echo "$TARGETS" | grep -q "build"; then
        log_success "build target found"
    else
        log_error "build target missing from Makefile"
    fi
    
    if echo "$TARGETS" | grep -q "releases"; then
        log_success "releases target found"
    else
        log_warning "releases target not found - may need manual build"
    fi
else
    log_error "Makefile not found"
fi

# Check 12: Go modules
log_info "Checking Go modules..."
if go mod verify > /dev/null 2>&1; then
    log_success "Go modules verified"
else
    log_error "Go module verification failed"
fi

if go mod tidy -diff > /dev/null 2>&1; then
    log_success "Go modules are tidy"
else
    log_warning "go mod tidy would make changes"
fi

echo ""
echo -e "${BLUE}📊 Pre-Release Summary${NC}"
echo "======================"
echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"

if [ $ERRORS -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}✅ All checks passed! Ready for release.${NC}"
        exit 0
    else
        echo -e "${YELLOW}⚠️  All checks passed with $WARNINGS warnings. Review warnings before proceeding.${NC}"
        exit 0
    fi
else
    echo -e "${RED}❌ $ERRORS errors found. Fix errors before releasing.${NC}"
    exit 1
fi