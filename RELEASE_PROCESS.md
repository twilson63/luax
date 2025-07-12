# Hype Release Process

This document outlines the automated release process for Hype and provides a checklist to ensure consistent, reliable releases.

## Quick Release (Automated)

For most releases, use the automated process:

```bash
# 1. Run pre-release checks
./scripts/pre-release-check.sh

# 2. Create release (will auto-bump patch version)
./scripts/release.sh

# OR specify version explicitly
./scripts/release.sh 1.6.0
```

## Manual Release Process

If you need more control or the automated process fails:

### Pre-Release Checklist

- [ ] **Code Quality**
  - [ ] All features are complete and tested
  - [ ] No known critical bugs
  - [ ] Code review completed
  - [ ] Documentation updated

- [ ] **Version Management**
  - [ ] Version bumped in `main.go`
  - [ ] Install scripts updated with new version
  - [ ] CHANGELOG.md updated (if exists)
  - [ ] Documentation version references updated

- [ ] **Testing**
  - [ ] `make build` succeeds
  - [ ] `make test` passes (if tests exist)
  - [ ] Manual testing on target platforms
  - [ ] Install scripts tested

- [ ] **Git Preparation**
  - [ ] Working directory is clean
  - [ ] On main branch
  - [ ] Latest changes pulled from origin
  - [ ] All commits pushed to GitHub

### Release Steps

1. **Version Update**
   ```bash
   # Update version in main.go
   sed -i 's/version = "[^"]*"/version = "NEW_VERSION"/' main.go
   
   # Update install scripts
   find . -name "install*.sh" -exec sed -i 's/hype-v[0-9]\+\.[0-9]\+\.[0-9]\+/hype-vNEW_VERSION/g' {} \;
   ```

2. **Build and Test**
   ```bash
   make build
   make test  # if available
   ```

3. **Commit and Tag**
   ```bash
   git add .
   git commit -m "chore: prepare release vNEW_VERSION"
   git tag vNEW_VERSION
   git push origin main
   git push origin vNEW_VERSION
   ```

4. **GitHub Release**
   - GitHub Actions will automatically build binaries
   - Create release notes
   - Upload artifacts

### Post-Release Checklist

- [ ] **Verification**
  - [ ] GitHub release created successfully
  - [ ] All binary artifacts uploaded
  - [ ] Install scripts work with new version
  - [ ] Documentation site updated

- [ ] **Communication**
  - [ ] Release notes published
  - [ ] Community notified (if applicable)
  - [ ] Social media announcement (if applicable)

- [ ] **Monitoring**
  - [ ] Download metrics tracked
  - [ ] Issue reports monitored
  - [ ] User feedback collected

## Release Types

### Patch Release (x.y.Z)
- Bug fixes
- Small improvements
- Documentation updates
- No breaking changes

### Minor Release (x.Y.0)
- New features
- Plugin system enhancements
- Backward compatible changes
- API additions

### Major Release (X.0.0)
- Breaking changes
- Major architectural changes
- API modifications
- Significant new features

## Automation Scripts

### `scripts/pre-release-check.sh`
Validates the codebase before release:
- Git status and branch checks
- Build and test validation
- Version consistency verification
- Documentation checks

### `scripts/release.sh`
Automates the release process:
- Version management
- Binary building
- Git tagging
- GitHub release creation

### `.github/workflows/release.yml`
GitHub Actions workflow that:
- Triggers on git tags
- Builds cross-platform binaries
- Creates GitHub releases
- Updates repository files

## Troubleshooting

### Common Issues

**Build Failures**
```bash
# Clean and rebuild
make clean
make build

# Check Go version
go version  # Requires 1.23+
```

**Version Mismatches**
```bash
# Check version consistency
grep -r "v[0-9]\+\.[0-9]\+\.[0-9]\+" install*.sh
grep "version = " main.go
```

**GitHub CLI Issues**
```bash
# Install GitHub CLI
# macOS: brew install gh
# Linux: See https://cli.github.com/

# Authenticate
gh auth login
```

**Tag Already Exists**
```bash
# Delete local tag
git tag -d vX.Y.Z

# Delete remote tag (careful!)
git push origin :refs/tags/vX.Y.Z
```

### Emergency Procedures

**Rollback Release**
```bash
# Mark release as pre-release
gh release edit vX.Y.Z --prerelease

# Or delete release entirely
gh release delete vX.Y.Z
```

**Hotfix Release**
1. Create hotfix branch from tag
2. Apply minimal fix
3. Follow normal release process
4. Merge back to main

## File Locations

- **Version Source**: `main.go` (version constant)
- **Install Scripts**: `install*.sh`
- **Release Scripts**: `scripts/`
- **GitHub Actions**: `.github/workflows/release.yml`
- **Documentation**: `docs/` (auto-updated)

## Version History

Track major releases and their impact:

| Version | Date | Type | Key Features |
|---------|------|------|--------------|
| v1.5.0 | 2024-07 | Minor | Plugin system, enhanced docs |
| v1.4.2 | 2024-06 | Patch | Bug fixes, mobile improvements |
| v1.4.1 | 2024-06 | Patch | Install script updates |

## Best Practices

1. **Always run pre-release checks** before releasing
2. **Test install scripts** on clean systems
3. **Keep releases small and focused** when possible
4. **Document breaking changes** clearly
5. **Monitor download metrics** and user feedback
6. **Have a rollback plan** for major releases
7. **Coordinate with documentation updates**

## Continuous Improvement

After each release, consider:
- What went well?
- What could be improved?
- Any manual steps that could be automated?
- Documentation gaps?
- Testing improvements needed?

Update this document based on lessons learned from each release cycle.