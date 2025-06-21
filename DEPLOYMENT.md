# LuaX Deployment Guide

This guide explains how to deploy LuaX to Arweave for decentralized distribution.

## Quick Deploy

1. **Build releases:**
   ```bash
   ./build-releases.sh
   ```

2. **Upload to Arweave:**
   - Upload each file in `dist/` to Arweave
   - Note the transaction IDs for each file

3. **Update install script:**
   - Edit `dist/install.sh` 
   - Replace `ARWEAVE_BASE_URL` with your base URL pattern
   - Upload the updated install script

4. **Share installation command:**
   ```bash
   curl -sSL https://arweave.net/YOUR_INSTALL_SCRIPT_TX_ID | bash
   ```

## Detailed Steps

### 1. Build All Platform Releases

```bash
# Build all platform binaries and packages
./build-releases.sh

# Check what was created
ls -la dist/
```

This creates:
- `luax-v1.0.0-linux-amd64.tar.gz`
- `luax-v1.0.0-linux-arm64.tar.gz` 
- `luax-v1.0.0-darwin-amd64.tar.gz`
- `luax-v1.0.0-darwin-arm64.tar.gz`
- `luax-v1.0.0-windows-amd64.zip`
- `install.sh` (deployment script)
- `luax-v1.0.0-checksums.txt`

### 2. Upload Files to Arweave

You can use various methods to upload to Arweave:

#### Option A: Using ArDrive CLI
```bash
# Install ArDrive CLI
npm install -g ardrive-cli

# Upload files
ardrive upload-file --wallet-file wallet.json --file dist/luax-v1.0.0-linux-amd64.tar.gz
ardrive upload-file --wallet-file wallet.json --file dist/luax-v1.0.0-darwin-amd64.tar.gz
# ... repeat for all files
```

#### Option B: Using Arweave Deploy Tool
```bash
# Install arweave-deploy
npm install -g arweave-deploy

# Deploy directory
arweave-deploy dist/ --wallet wallet.json
```

#### Option C: Manual Upload via ArWeave Web Interface
1. Go to https://arweave.app
2. Upload each file individually
3. Note the transaction ID for each file

### 3. Update Installation Script

After uploading, update the install script with the correct URLs:

```bash
# Edit the install script
vim dist/install.sh

# Update this line:
ARWEAVE_BASE_URL="https://arweave.net/YOUR_BASE_TX_ID"

# Or use individual file URLs if using different transaction IDs
```

### 4. Upload Final Install Script

Upload the updated `install.sh` to Arweave and note its transaction ID.

### 5. Test Installation

Test the installation on different platforms:

```bash
# Test on Linux
curl -sSL https://arweave.net/YOUR_INSTALL_SCRIPT_TX_ID | bash

# Verify installation
luax --help
```

## URL Structure Options

### Option 1: Single Base URL (Recommended)
Upload all files with a consistent naming pattern:
```
https://arweave.net/BASE_TX_ID/luax-v1.0.0-linux-amd64.tar.gz
https://arweave.net/BASE_TX_ID/luax-v1.0.0-darwin-amd64.tar.gz
etc.
```

### Option 2: Individual Transaction IDs
Map each file to its own transaction ID in the install script:
```bash
case "$platform" in
    "linux-amd64")  url="https://arweave.net/TX_ID_1" ;;
    "darwin-amd64") url="https://arweave.net/TX_ID_2" ;;
    # ... etc
esac
```

## Security Considerations

1. **Verify checksums:** The script includes checksum verification
2. **HTTPS only:** Always use HTTPS URLs
3. **Signature verification:** Consider signing releases for additional security

## Distribution

Once deployed, users can install LuaX with a single command:

```bash
curl -sSL https://arweave.net/YOUR_TX_ID | bash
```

Or save and inspect first:
```bash
curl -sSL https://arweave.net/YOUR_TX_ID > install.sh
# Review the script
bash install.sh
```

## Example Usage After Installation

```bash
# Create a simple Lua TUI app
echo 'local app = tui.newApp()
local text = tui.newTextView("Hello from LuaX!")
app:SetRoot(text, true)
app:Run()' > hello.lua

# Package it into an executable
luax build hello.lua -o hello

# Run the executable
./hello
```

## Updating Releases

To update LuaX:

1. Update version in `build-releases.sh`
2. Run `./build-releases.sh`
3. Upload new files to Arweave
4. Update install script with new URLs
5. Share new install script transaction ID

The install script automatically detects the platform and downloads the appropriate binary, making distribution seamless across Linux, macOS, and Windows.