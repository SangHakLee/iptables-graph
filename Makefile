# Makefile for iptables-graph project

SHELL := /bin/bash

APP_NAME = iptables-graph
SCRIPT = src/iptables_graph/__main__.py
DIST_DIR = dist
BUILD_DIR = build
EXAMPLE = examples/example.iptables

# Python command (can be overridden: make pypi-build PYTHON=python)
PYTHON ?= python3

# Version management (read from pyproject.toml)
VERSION := $(shell grep '^version = ' pyproject.toml | head -1 | cut -d '"' -f 2)

# Docker configuration
DOCKER_IMAGE = $(APP_NAME)
DOCKER_TAG ?= $(VERSION)
DOCKER_REGISTRY ?= sanghaklee
DOCKER_FULL_IMAGE = $(DOCKER_REGISTRY)/$(DOCKER_IMAGE):$(DOCKER_TAG)

.PHONY: all build test test-svg test-png clean help
.PHONY: docker-build docker-build-exe docker-run docker-test docker-test-run docker-push docker-clean
.PHONY: pypi-build pypi-check pypi-upload pypi-test-upload pypi-clean
.PHONY: release version-bump changelog version-check

all: build

# Build standalone executable with PyInstaller
build:
	@echo "==> Building executable with PyInstaller..."
	pyinstaller $(APP_NAME).spec
	@echo "==> Build complete: $(DIST_DIR)/$(APP_NAME)"

# Test with example iptables file (DOT output)
test:
	@echo "==> Testing with $(EXAMPLE)..."
	cat $(EXAMPLE) | ./$(SCRIPT)

# Test SVG generation
test-svg:
	@echo "==> Generating SVG from $(EXAMPLE)..."
	cat $(EXAMPLE) | ./$(SCRIPT) -f svg -o test-output.svg
	@echo "==> SVG generated: test-output.svg"

# Test PNG generation
test-png:
	@echo "==> Generating PNG from $(EXAMPLE)..."
	cat $(EXAMPLE) | ./$(SCRIPT) -f png -o test-output.png
	@echo "==> PNG generated: test-output.png"

# Run the built executable
run: build
	@echo "==> Running built executable (pipe iptables-save to it)..."
	$(DIST_DIR)/$(APP_NAME)

# Clean build artifacts
clean:
	@echo "==> Cleaning up build artifacts..."
	rm -rf $(BUILD_DIR) $(DIST_DIR) __pycache__ dot
	rm -f *.bin *.build *.dist *.onefile-build
	rm -f test-output.*
	@echo "==> Clean complete"

# ============================================================================
# PyPI targets
# ============================================================================

# Build PyPI package
pypi-build:
	@echo "==> Building PyPI package (version $(VERSION))..."
	$(PYTHON) -m build
	@echo "==> Package built in dist/"
	@ls -lh dist/

# Check PyPI package
pypi-check:
	@echo "==> Checking package with twine..."
	@if ls dist/*.whl dist/*.tar.gz 1> /dev/null 2>&1; then \
		twine check dist/*.whl dist/*.tar.gz; \
	else \
		echo "ERROR: No .whl or .tar.gz files found in dist/"; \
		echo "Run 'make pypi-build' first"; \
		exit 1; \
	fi

# Upload to TestPyPI (for testing)
pypi-test-upload: pypi-build pypi-check
	@echo "==> Uploading to TestPyPI (version $(VERSION))..."
	twine upload --repository testpypi dist/*.whl dist/*.tar.gz
	@echo "==> Test upload complete!"
	@echo "==> Install with: pip install -i https://test.pypi.org/simple/ iptables-graph"


# Upload to PyPI (production)
pypi-upload: pypi-build pypi-check
	@echo "==> Uploading to PyPI (version $(VERSION))..."
	@echo "WARNING: This will upload to production PyPI!"
	@read -p "Continue? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		twine upload dist/*.whl dist/*.tar.gz; \
		echo "==> Upload complete!"; \
	else \
		echo "==> Upload cancelled"; \
	fi

# Clean PyPI build artifacts
pypi-clean:
	@echo "==> Cleaning PyPI build artifacts..."
	rm -rf dist/ build/ src/*.egg-info/
	@echo "==> PyPI cleanup complete"

# ============================================================================
# Semantic Release targets (Conventional Commits)
# ============================================================================

# Check what version would be released
version-check:
	@echo "==> Checking next version..."
	semantic-release version --print

# Automatic version bump based on conventional commits
version-bump:
	@echo "==> Bumping version based on conventional commits..."
	semantic-release version --no-push --no-tag --no-changelog
	@echo "==> Version updated in pyproject.toml and __init__.py"

# Generate CHANGELOG
changelog:
	@echo "==> Generating CHANGELOG..."
	semantic-release changelog
	@echo "==> CHANGELOG.md generated"

# Full release: version bump + changelog + tag + push
release:
	@echo "==> Creating new release with semantic-release..."
	@echo "This will:"
	@echo "  1. Analyze commits since last release"
	@echo "  2. Determine next version (major/minor/patch)"
	@echo "  3. Update version in pyproject.toml and __init__.py"
	@echo "  4. Generate/update CHANGELOG.md"
	@echo "  5. Create git commit and tag"
	@echo "  6. Push to GitHub"
	@echo ""
	@read -p "Continue? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		semantic-release version; \
		echo "==> Release complete!"; \
		echo "==> Don't forget to run 'make pypi-upload' if you want to publish to PyPI"; \
	else \
		echo "==> Release cancelled"; \
	fi

# Show help
help:
	@echo "iptables-graph v$(VERSION)"
	@echo ""
	@echo "Local build targets:"
	@echo "  make build         - Build standalone executable with PyInstaller"
	@echo "  make test          - Test script with example file (DOT output)"
	@echo "  make test-svg      - Generate SVG from example file"
	@echo "  make test-png      - Generate PNG from example file"
	@echo "  make run           - Run built executable"
	@echo "  make clean         - Remove all build artifacts"
	@echo ""
	@echo "Docker targets (recommended):"
	@echo "  make docker-build      - Build Docker image"
	@echo "  make docker-test       - Test Docker container with example"
	@echo "  make docker-test-run   - Test all output formats (DOT/SVG/PNG)"
	@echo "  make docker-run        - Run container interactively"
	@echo "  make docker-build-exe  - Extract executable to dist/ directory"
	@echo "  make docker-push       - Push image to registry (set DOCKER_REGISTRY=user/)"
	@echo "  make docker-clean      - Remove Docker images"
	@echo ""
	@echo "PyPI package targets:"
	@echo "  make pypi-build        - Build PyPI package (wheel and sdist)"
	@echo "  make pypi-check        - Check package with twine"
	@echo "  make pypi-test-upload  - Upload to TestPyPI (for testing)"
	@echo "  make pypi-upload       - Upload to production PyPI (requires confirmation)"
	@echo "  make pypi-clean        - Remove PyPI build artifacts"
	@echo ""
	@echo "Semantic Release targets (Conventional Commits):"
	@echo "  make version-check     - Check what version would be released"
	@echo "  make version-bump      - Bump version based on commits (no commit/tag)"
	@echo "  make changelog         - Generate CHANGELOG.md"
	@echo "  make release           - Full release (version + changelog + tag + push)"
	@echo ""
	@echo "Quick start (Docker):"
	@echo "  make docker-build && make docker-test-run"
	@echo "  sudo iptables-save | docker run --rm -i iptables-graph:$(VERSION)"
	@echo ""
	@echo "Conventional Commits Format:"
	@echo "  feat: new feature (minor version bump)"
	@echo "  fix: bug fix (patch version bump)"
	@echo "  BREAKING CHANGE: breaking change (major version bump)"
	@echo ""
	@echo "  make help          - Show this help message"

# ============================================================================
# Docker targets
# ============================================================================

# Build Docker image
docker-build:
	@echo "==> Building Docker image: $(DOCKER_FULL_IMAGE)..."
	docker build -t $(DOCKER_IMAGE):$(DOCKER_TAG) .
	@if [ -n "$(DOCKER_REGISTRY)" ]; then \
		docker tag $(DOCKER_IMAGE):$(DOCKER_TAG) $(DOCKER_FULL_IMAGE); \
	fi
	@echo "==> Docker image built: $(DOCKER_IMAGE):$(DOCKER_TAG)"

# Build executable using Docker (extract to host)
docker-build-exe:
	@echo "==> Building executable using Docker..."
	@mkdir -p $(DIST_DIR)
	docker build --target builder -t $(DOCKER_IMAGE):builder .
	@echo "==> Extracting executable from Docker image..."
	docker create --name tmp-$(APP_NAME) $(DOCKER_IMAGE):builder
	docker cp tmp-$(APP_NAME):/app/dist/$(APP_NAME) $(DIST_DIR)/$(APP_NAME)
	docker rm tmp-$(APP_NAME)
	@echo "==> Executable extracted to $(DIST_DIR)/$(APP_NAME)"
	@ls -lh $(DIST_DIR)/$(APP_NAME)

# Run container interactively (for testing)
docker-run:
	@echo "==> Running Docker container..."
	@echo "==> Pipe iptables-save output or use -i flag"
	docker run --rm -i $(DOCKER_IMAGE):$(DOCKER_TAG)

# Test Docker container with example file (DOT output)
docker-test:
	@echo "==> Testing Docker container with example file (DOT)..."
	cat $(EXAMPLE) | docker run --rm -i $(DOCKER_IMAGE):$(DOCKER_TAG) | head -20

# Test Docker container with various output formats
docker-test-run:
	@echo "==> Testing Docker container with various formats..."
	@echo "--- Test 1: DOT format (default) ---"
	cat $(EXAMPLE) | docker run --rm -i $(DOCKER_IMAGE):$(DOCKER_TAG) | head -10
	@echo ""
	@echo "--- Test 2: SVG format ---"
	cat $(EXAMPLE) | docker run --rm -i $(DOCKER_IMAGE):$(DOCKER_TAG) -f svg | head -5
	@echo ""
	@echo "--- Test 3: PNG format (to file) ---"
	mkdir -p test-docker-output
	docker run --rm -v $(PWD)/test-docker-output:/output -v $(PWD)/$(EXAMPLE):/input.txt \
		$(DOCKER_IMAGE):$(DOCKER_TAG) -i /input.txt -f png -o /output/test.png
	@if [ -f test-docker-output/test.png ]; then \
		echo "✅ PNG created successfully"; \
		ls -lh test-docker-output/test.png; \
	fi
	@rm -rf test-docker-output
	@echo ""
	@echo "==> All Docker tests passed!"

# Push Docker image to registry
docker-push: docker-build
	@if [ -z "$(DOCKER_REGISTRY)" ]; then \
		echo "❌ Error: DOCKER_REGISTRY is not set"; \
		echo "Usage: make docker-push DOCKER_REGISTRY=username/"; \
		exit 1; \
	fi
	@echo "==> Pushing Docker image: $(DOCKER_FULL_IMAGE)..."
	docker push $(DOCKER_FULL_IMAGE)
	@echo "==> Push complete!"
	@echo "==> Users can now run: docker run --rm -i $(DOCKER_FULL_IMAGE)"

# Clean Docker artifacts
docker-clean:
	@echo "==> Removing Docker images..."
	docker rmi $(DOCKER_IMAGE):$(DOCKER_TAG) 2>/dev/null || true
	docker rmi $(DOCKER_IMAGE):builder 2>/dev/null || true
	@if [ -n "$(DOCKER_REGISTRY)" ]; then \
		docker rmi $(DOCKER_FULL_IMAGE) 2>/dev/null || true; \
	fi
	@echo "==> Docker cleanup complete"
