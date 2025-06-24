# Hype Release Checklist

This document provides a comprehensive checklist for releasing new versions of Hype, ensuring all necessary steps are completed and nothing is missed.

## Pre-Release Preparation

### 1. Version Planning
- [ ] Determine version number (semantic versioning: MAJOR.MINOR.PATCH)
- [ ] Review all changes since last release
- [ ] Ensure all features are complete and tested
- [ ] Update version constant in source code

### 2. Code Quality & Testing
- [ ] Run all existing tests
- [ ] Perform manual regression testing:
  - [ ] Test `hype build` with various Lua scripts
  - [ ] Test `hype run` with development scripts
  - [ ] Test cross-platform builds (Linux, macOS, Windows)
  - [ ] Test TUI functionality with example scripts
  - [ ] Test HTTP client/server functionality
  - [ ] Test key-value database operations
  - [ ] Test crypto module functionality
  - [ ] Test HTTP signatures functionality
- [ ] Verify all command-line options work correctly
- [ ] Test install scripts on clean systems

### 3. Documentation Updates
- [ ] Update README.md with any new features or changes
- [ ] Update API documentation (docs/api.html)
- [ ] Update examples documentation (docs/examples.html)
- [ ] Add new examples if significant features were added
- [ ] Verify all documentation links work
- [ ] Update version references in documentation

## Release Process

### 4. Version Update
- [ ] Update version constant in `main.go`
- [ ] Update version in `install-mac.sh`
- [ ] Update version in `install.sh` (if applicable)
- [ ] Verify `hype version` command shows correct version

### 5. Build & Test Executables
- [ ] Build for all platforms:
  - [ ] `GOOS=darwin GOARCH=amd64 go build -o hype-darwin-amd64`
  - [ ] `GOOS=darwin GOARCH=arm64 go build -o hype-darwin-arm64`
  - [ ] `GOOS=linux GOARCH=amd64 go build -o hype-linux-amd64`
  - [ ] `GOOS=windows GOARCH=amd64 go build -o hype-windows-amd64.exe`
- [ ] Test each binary on respective platforms (if possible)
- [ ] Verify file sizes are reasonable
- [ ] Test that executables work standalone

### 6. Git & GitHub Preparation
- [ ] Ensure all changes are committed
- [ ] Create and test changelog entry
- [ ] Tag release commit: `git tag vX.Y.Z`
- [ ] Push commits: `git push origin main`
- [ ] Push tags: `git push origin vX.Y.Z`

### 7. GitHub Release
- [ ] Create GitHub release with tag
- [ ] Write comprehensive release notes including:
  - [ ] New features added
  - [ ] Bug fixes
  - [ ] Breaking changes (if any)
  - [ ] Security improvements
  - [ ] Performance improvements
  - [ ] Documentation updates
- [ ] Upload all platform binaries to release
- [ ] Mark release as latest

### 8. Install Script Updates
- [ ] Update `install-mac.sh` version reference
- [ ] Update any other install scripts
- [ ] Test install scripts work with new release
- [ ] Commit and push install script updates

### 9. Post-Release Verification
- [ ] Test installation from GitHub releases
- [ ] Verify `curl` install script works
- [ ] Test that `hype version` shows correct version
- [ ] Check that documentation website reflects changes
- [ ] Verify all download links work

## Release Automation Script

### Quick Release Commands
```bash
# Set version
export VERSION="1.3.0"

# Run automated release process
./scripts/release.sh $VERSION
```

## Rollback Plan

### If Issues Are Found Post-Release
- [ ] Create hotfix branch from release tag
- [ ] Apply minimal fix
- [ ] Follow release process for patch version
- [ ] Update release notes with fix information

## Release Notes Template

```markdown
## 🎉 Hype vX.Y.Z

### ✨ New Features
- Feature 1 description
- Feature 2 description

### 🐛 Bug Fixes
- Fix 1 description
- Fix 2 description

### 🔒 Security Improvements
- Security improvement 1
- Security improvement 2

### 📚 Documentation
- Documentation update 1
- Documentation update 2

### 🛠️ Technical Changes
- Technical change 1
- Technical change 2

### 📦 Installation
- macOS: `curl -sSL https://raw.githubusercontent.com/twilson63/hype/main/install-mac.sh | bash`
- Manual: Download from [GitHub Releases](https://github.com/twilson63/hype/releases/tag/vX.Y.Z)

Built with ❤️ for the Lua community.
```

## Changelog Maintenance

### Changelog Format (CHANGELOG.md)
```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [X.Y.Z] - YYYY-MM-DD

### Added
- New feature descriptions

### Changed
- Changed feature descriptions

### Fixed
- Bug fix descriptions

### Security
- Security fix descriptions

### Removed
- Removed feature descriptions
```

## Testing Matrix

### Platform Testing
| Platform | Architecture | Status | Notes |
|----------|-------------|---------|-------|
| macOS | Intel (x64) | ✅ | |
| macOS | Apple Silicon (arm64) | ✅ | |
| Linux | x64 | ✅ | |
| Windows | x64 | ✅ | |

### Feature Testing
| Feature | Status | Test Script |
|---------|--------|-------------|
| TUI Components | ✅ | `examples/showcase.lua` |
| HTTP Client | ✅ | `examples/http-client.lua` |
| HTTP Server | ✅ | `examples/webserver.lua` |
| Key-Value DB | ✅ | `examples/kv-test.lua` |
| Crypto Module | ✅ | `examples/crypto-basic.lua` |
| HTTP Signatures | ✅ | `examples/httpsig-basic.lua` |
| Cross-platform Build | ✅ | Manual verification |

## Common Issues & Solutions

### Issue: Version command not working
**Solution:** Ensure version constant is updated in source code and binary is rebuilt

### Issue: Install script downloads wrong version
**Solution:** Update version reference in install scripts and test

### Issue: Binary doesn't work on target platform
**Solution:** Verify GOOS and GOARCH settings, test on target platform

### Issue: Documentation out of sync
**Solution:** Review all docs before release, update version references

## Release Metrics

Track these metrics for each release:
- [ ] Download count after 24 hours
- [ ] Download count after 1 week
- [ ] GitHub stars/forks increase
- [ ] Issues reported post-release
- [ ] Documentation page views

---

**Note:** This checklist should be updated as the project evolves. Keep it current with any new processes or requirements.