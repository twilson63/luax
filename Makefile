# Makefile for Hype

# Get version information from git
VERSION := $(shell git describe --tags --always --dirty)
COMMIT := $(shell git rev-parse --short HEAD)
DATE := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

# If we're exactly on a tag, use just the tag
ifeq ($(shell git describe --exact-match --tags HEAD 2>/dev/null),)
else
    VERSION := $(shell git describe --exact-match --tags HEAD)
endif

# Build flags
LDFLAGS := -X main.version=$(VERSION) -X main.commit=$(COMMIT) -X main.date=$(DATE)

.PHONY: build clean dev install test help

# Default target
build: ## Build hype executable
	@echo "Building hype $(VERSION) (commit: $(COMMIT))"
	go build -ldflags "$(LDFLAGS)" -o hype .

dev: ## Build development version with debug info
	@echo "Building hype $(VERSION) (commit: $(COMMIT)) - development build"
	go build -ldflags "$(LDFLAGS)" -race -o hype .

clean: ## Clean build artifacts
	rm -f hype
	rm -rf dist/

install: build ## Install hype to /usr/local/bin (requires sudo)
	sudo cp hype /usr/local/bin/

test: ## Run tests
	go test ./...

releases: ## Build releases for all platforms
	./build-releases.sh

help: ## Show this help message
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Version information
version: ## Print version information
	@echo "Version: $(VERSION)"
	@echo "Commit:  $(COMMIT)"
	@echo "Date:    $(DATE)"

# Release automation targets
pre-release-check: ## Run pre-release validation checks
	@./scripts/pre-release-check.sh

release: ## Create a new release (interactive)
	@./scripts/release.sh

release-patch: ## Create a patch release (auto-bump)
	@./scripts/release.sh

release-minor: ## Create a minor release (requires manual version)
	@echo "For minor releases, specify version manually:"
	@echo "  make release VERSION=x.y.0"

release-major: ## Create a major release (requires manual version)
	@echo "For major releases, specify version manually:"
	@echo "  make release VERSION=x.0.0"