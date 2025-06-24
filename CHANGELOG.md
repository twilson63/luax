# Changelog

All notable changes to Hype will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Release automation and checklist process
- Comprehensive mobile-friendly documentation website
- Version verification in install scripts

### Changed
- Improved release process with automated scripts
- Enhanced mobile responsiveness across all documentation pages

## [1.2.0] - 2024-06-24

### Added
- **HTTP Signatures module** with RFC-compliant signing and verification
- **Crypto module** with JWK support for RSA, ECDSA, and Ed25519 algorithms
- **Cyberpunk documentation styling** with tron-like blue themes and dark gray text
- **Comprehensive examples** for crypto operations and HTTP signatures
- **Complete API reference** with practical use cases
- **Mobile-optimized documentation** with touch-friendly interfaces
- **Enhanced responsive design** for all screen sizes
- **Version command** now shows proper version information

### Changed
- **Command structure**: `hype eval` renamed to `hype run` for better clarity
- **Documentation website** completely redesigned with cyberpunk aesthetic
- **Code block positioning** optimized to prevent UI collisions
- **Navigation** improved for mobile devices with touch-friendly targets

### Fixed
- **Critical security vulnerability** in HTTP signature verification
- **Digest validation** now properly prevents tampered content acceptance
- **Mobile navigation** and touch target sizing issues
- **Cross-platform binary** building process improvements

### Security
- **HTTP signature tampering protection** through proper digest validation
- **Enhanced message integrity** protection for API communications
- **Multi-algorithm support** for cryptographic operations (RS256, ES256, EdDSA)

## [1.1.0] - 2024-06-XX

### Added
- Enhanced TUI features and dashboard examples
- Comprehensive TUI method support
- Advanced terminal user interface capabilities

### Changed
- Updated macOS install script process
- Improved documentation website structure

## [1.0.5] - 2024-06-XX

### Added
- Improved HTTP server performance and reliability
- Critical HTTP and TUI component fixes

## [1.0.4] - 2024-06-XX

### Added
- Comprehensive documentation website
- Improved macOS installation experience

### Fixed
- Critical HTTP and TUI component issues

## [1.0.0] - 2024-XX-XX

### Added
- Initial release of Hype
- **TUI (Terminal User Interface)** support with tview library
- **HTTP client and server** functionality
- **Embedded key-value database** with BoltDB
- **Cross-platform executable** building (Linux, macOS, Windows)
- **Lua script packaging** into standalone executables
- **Zero external dependencies** in final executables
- **Development mode** with direct script execution
- **Command line argument** support for packaged applications

### Features
- Package Lua scripts into standalone executables
- Built-in TUI library for creating terminal applications
- HTTP client and server support for web applications
- Embedded key-value database with BoltDB
- Transaction support with ACID properties
- Database iteration and querying with cursor support
- Simple deployment with single binary distribution
- Cross-platform support (Linux, macOS, Windows)

---

## Release Notes Format

Each release should include:

### Added
- New features and capabilities

### Changed
- Changes in existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Features removed in this release

### Fixed
- Bug fixes

### Security
- Security improvements and vulnerability fixes

---

## Versioning Strategy

- **MAJOR**: Incompatible API changes
- **MINOR**: Backward-compatible functionality additions
- **PATCH**: Backward-compatible bug fixes

## Links

- [GitHub Releases](https://github.com/twilson63/hype/releases)
- [Documentation](https://twilson63.github.io/hype/)
- [Issue Tracker](https://github.com/twilson63/hype/issues)