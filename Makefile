# Makefile for iptables-graph project

APP_NAME = iptables-graph
SCRIPT = $(APP_NAME).py
DIST_DIR = dist
BUILD_DIR = build
EXAMPLE = examples/example.iptables

# Docker configuration
DOCKER_IMAGE = $(APP_NAME)
DOCKER_TAG ?= latest
DOCKER_REGISTRY ?= # Set your registry (e.g., username/ or ghcr.io/username/)
DOCKER_FULL_IMAGE = $(DOCKER_REGISTRY)$(DOCKER_IMAGE):$(DOCKER_TAG)

.PHONY: all build test test-svg test-png clean help
.PHONY: docker-build docker-build-exe docker-run docker-test docker-test-run docker-push docker-clean

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

# Show help
help:
	@echo "iptables-graph Makefile"
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
	@echo "Quick start (Docker):"
	@echo "  make docker-build && make docker-test-run"
	@echo "  sudo iptables-save | docker run --rm -i iptables-graph:latest"
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
