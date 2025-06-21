#!/bin/bash

# LuaX Install Script
# Detects platform and installs the appropriate luax binary
# Usage: curl -sSL <arweave-url> | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LUAX_VERSION="v1.0.0"
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="luax"

# Arweave base URL (replace with actual Arweave transaction ID)
ARWEAVE_BASE_URL="https://arweave.net"
# Example: ARWEAVE_BASE_URL="https://arweave.net/your-transaction-id"

print_banner() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════╗"
    echo "║              LuaX Installer          ║"
    echo "║   Lua Script to Executable Packager ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"
}

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

detect_platform() {
    local os arch
    
    # Detect OS
    case "$(uname -s)" in
        Linux*)     os="linux" ;;
        Darwin*)    os="darwin" ;;
        CYGWIN*|MINGW*|MSYS*) os="windows" ;;
        *)          
            log_error "Unsupported operating system: $(uname -s)"
            exit 1
            ;;
    esac
    
    # Detect architecture
    case "$(uname -m)" in
        x86_64|amd64)   arch="amd64" ;;
        arm64|aarch64)  arch="arm64" ;;
        armv7l)         arch="arm" ;;
        i386|i686)      arch="386" ;;
        *)              
            log_error "Unsupported architecture: $(uname -m)"
            exit 1
            ;;
    esac
    
    echo "${os}-${arch}"
}

check_dependencies() {
    log_info "Checking dependencies..."
    
    # Check for curl or wget
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        log_error "Either curl or wget is required for installation"
        exit 1
    fi
    
    # Check for unzip/tar
    if ! command -v unzip >/dev/null 2>&1 && ! command -v tar >/dev/null 2>&1; then
        log_error "Either unzip or tar is required for installation"
        exit 1
    fi
    
    log_success "Dependencies check passed"
}

download_file() {
    local url="$1"
    local output="$2"
    
    log_info "Downloading from: $url"
    
    if command -v curl >/dev/null 2>&1; then
        curl -sSL "$url" -o "$output"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$url" -O "$output"
    else
        log_error "No download tool available"
        exit 1
    fi
}

get_install_dir() {
    # Try to find a writable directory in PATH
    local dirs=("/usr/local/bin" "$HOME/.local/bin" "$HOME/bin")
    
    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" && -w "$dir" ]]; then
            echo "$dir"
            return 0
        fi
    done
    
    # Create ~/.local/bin if it doesn't exist
    if [[ ! -d "$HOME/.local/bin" ]]; then
        mkdir -p "$HOME/.local/bin"
        echo "$HOME/.local/bin"
        return 0
    fi
    
    log_error "No writable directory found in PATH"
    exit 1
}

add_to_path() {
    local install_dir="$1"
    local shell_rc=""
    
    # Detect shell and corresponding RC file
    case "$SHELL" in
        */bash)     shell_rc="$HOME/.bashrc" ;;
        */zsh)      shell_rc="$HOME/.zshrc" ;;
        */fish)     shell_rc="$HOME/.config/fish/config.fish" ;;
        *)          shell_rc="$HOME/.profile" ;;
    esac
    
    # Check if directory is already in PATH
    if [[ ":$PATH:" == *":$install_dir:"* ]]; then
        return 0
    fi
    
    # Add to PATH in shell RC file
    if [[ "$SHELL" == */fish ]]; then
        echo "set -gx PATH $install_dir \$PATH" >> "$shell_rc"
    else
        echo "export PATH=\"$install_dir:\$PATH\"" >> "$shell_rc"
    fi
    
    log_info "Added $install_dir to PATH in $shell_rc"
    log_warning "Please restart your shell or run: source $shell_rc"
}

install_luax() {
    local platform="$1"
    local temp_dir
    
    temp_dir=$(mktemp -d)
    trap 'rm -rf "$temp_dir"' EXIT
    
    log_info "Installing LuaX for platform: $platform"
    
    # Determine file extension and binary name
    local file_ext="tar.gz"
    local binary_name="luax"
    
    if [[ "$platform" == *"windows"* ]]; then
        file_ext="zip"
        binary_name="luax.exe"
    fi
    
    # Construct download URL
    local download_url="${ARWEAVE_BASE_URL}/luax-${LUAX_VERSION}-${platform}.${file_ext}"
    local archive_file="$temp_dir/luax.${file_ext}"
    
    # Download archive
    log_info "Downloading LuaX binary..."
    download_file "$download_url" "$archive_file"
    
    # Extract archive
    log_info "Extracting archive..."
    cd "$temp_dir"
    
    if [[ "$file_ext" == "zip" ]]; then
        unzip -q "$archive_file"
    else
        tar -xzf "$archive_file"
    fi
    
    # Find the binary
    local extracted_binary
    if [[ -f "$binary_name" ]]; then
        extracted_binary="$binary_name"
    elif [[ -f "luax/$binary_name" ]]; then
        extracted_binary="luax/$binary_name"
    else
        log_error "Could not find luax binary in archive"
        exit 1
    fi
    
    # Install binary
    local install_dir
    if [[ -w "/usr/local/bin" ]]; then
        install_dir="/usr/local/bin"
    else
        install_dir=$(get_install_dir)
    fi
    
    log_info "Installing to: $install_dir"
    
    # Copy binary and make executable
    cp "$extracted_binary" "$install_dir/$BINARY_NAME"
    chmod +x "$install_dir/$BINARY_NAME"
    
    # Add to PATH if necessary
    if [[ "$install_dir" != "/usr/local/bin" && "$install_dir" != "/usr/bin" ]]; then
        add_to_path "$install_dir"
    fi
    
    log_success "LuaX installed successfully!"
}

verify_installation() {
    log_info "Verifying installation..."
    
    if command -v luax >/dev/null 2>&1; then
        local version
        version=$(luax --version 2>/dev/null || echo "unknown")
        log_success "LuaX is installed and available in PATH"
        log_info "Version: $version"
    else
        log_warning "LuaX is installed but not found in current PATH"
        log_info "You may need to restart your shell or add the install directory to your PATH"
    fi
}

show_usage() {
    echo
    echo -e "${GREEN}LuaX is now installed!${NC}"
    echo
    echo "Usage examples:"
    echo "  luax build script.lua                 # Build executable"
    echo "  luax build script.lua -o myapp       # Custom output name"
    echo "  luax build script.lua -t linux       # Cross-platform build"
    echo
    echo "TUI API documentation:"
    echo "  https://github.com/your-repo/luax#tui-api"
    echo
}

main() {
    print_banner
    
    # Check if running as root for system-wide install
    if [[ $EUID -eq 0 ]]; then
        log_warning "Running as root - installing system-wide"
        INSTALL_DIR="/usr/local/bin"
    fi
    
    # Detect platform
    local platform
    platform=$(detect_platform)
    log_info "Detected platform: $platform"
    
    # Check dependencies
    check_dependencies
    
    # Install LuaX
    install_luax "$platform"
    
    # Verify installation
    verify_installation
    
    # Show usage information
    show_usage
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "LuaX Installer"
        echo "Usage: curl -sSL <install-url> | bash"
        echo "       bash install.sh [--help]"
        exit 0
        ;;
    --version|-v)
        echo "LuaX Installer $LUAX_VERSION"
        exit 0
        ;;
esac

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi