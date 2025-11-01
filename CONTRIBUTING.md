# Contributing to iptables-graph

Thank you for your interest in contributing to iptables-graph!

## Development Setup

### Prerequisites

- Python 3.7+
- Docker (for Docker builds)
- Graphviz (for local development)

### Clone the Repository

```bash
git clone https://github.com/SangHakLee/iptables-graph.git
cd iptables-graph
```

### Local Development

#### Install Dependencies

```bash
# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install development dependencies
pip install -r requirements.txt
```

#### Run Tests

```bash
# Test with example file
make test

# Test all formats
make test-svg
make test-png

# Or run directly
cat examples/example.iptables | ./iptables_graph.py
cat examples/example.iptables | ./iptables_graph.py -f svg > test.svg
```

## Building

### Build with PyInstaller (Standalone Executable)

```bash
# Build executable
make build

# Test the executable
cat examples/example.iptables | ./dist/iptables-graph
```

The executable will be created in `dist/iptables-graph`.

### Build Docker Image

```bash
# Build Docker image
make docker-build

# Test Docker image
make docker-test
make docker-test-run

# Run interactively
cat examples/example.iptables | docker run --rm -i iptables-graph:1.0.0
```

### Extract Executable from Docker

```bash
# Build and extract executable to dist/
make docker-build-exe

# The executable is now in dist/iptables-graph
./dist/iptables-graph --help
```

## Version Management

The project uses a single `VERSION` file for all version management:

```bash
# Update version
echo "1.0.1" > VERSION

# Build with new version
make docker-build
# This creates: iptables-graph:1.0.1

# For PyPI
python -m build
# Version is read from VERSION file
```

## Code Structure

This project follows the standard Python src-layout:

```
iptables-graph/
├── src/
│   └── iptables_graph/      # Python package (underscore)
│       ├── __init__.py      # Package initialization & version
│       └── __main__.py      # Main CLI implementation
├── tests/                    # Test files (pytest)
├── examples/                 # Example iptables files
│   ├── example.iptables
│   └── gcloud.iptables
├── pyproject.toml           # Python package configuration
├── iptables-graph.spec      # PyInstaller spec file
├── VERSION                  # Version file (single source of truth)
├── Dockerfile               # Docker build configuration
├── Makefile                 # Build automation
├── requirements.txt         # Build/dev dependencies
├── README.md                # User guide
└── CONTRIBUTING.md          # Developer guide
```

### Key Files

- **`src/iptables_graph/`**: Main Python package (underscore for Python module naming)
  - `__init__.py`: Package initialization, version management
  - `__main__.py`: CLI entry point and main logic
- **`VERSION`**: Single source of truth for version numbers
- **`pyproject.toml`**: Defines PyPI package named `iptables-graph` (dash allowed in PyPI)
- **`iptables-graph.spec`**: PyInstaller configuration for building standalone executable
- **`Dockerfile`**: Multi-stage build for optimized Docker images

## Releasing

### 1. Update Version

```bash
echo "1.1.0" > VERSION
```

### 2. Build and Test

```bash
# Test locally
make test

# Build and test Docker
make docker-build
make docker-test-run
```

### 3. Build PyPI Package

```bash
# Build package
make pypi-build

# Check package
make pypi-check

# Upload to TestPyPI (for testing)
make pypi-test-upload

# Upload to production PyPI (requires credentials)
make pypi-upload
```

### 4. Push Docker Image

```bash
# Tag and push to Docker Hub
make docker-push DOCKER_REGISTRY=yourusername/

# Or manually
docker tag iptables-graph:1.1.0 yourusername/iptables-graph:1.1.0
docker tag iptables-graph:1.1.0 yourusername/iptables-graph:latest
docker push yourusername/iptables-graph:1.1.0
docker push yourusername/iptables-graph:latest
```

### 5. Create Git Release

```bash
git add VERSION
git commit -m "chore: bump version to 1.1.0"
git tag v1.1.0
git push origin main --tags
```

## Testing

### Run All Tests

```bash
# Local Python script
make test
make test-svg
make test-png

# Docker container
make docker-test
make docker-test-run
```

### Manual Testing

```bash
# Test DOT output (using Python module)
python -m iptables_graph < examples/example.iptables

# Test SVG generation
python -m iptables_graph -f svg < examples/example.iptables > output.svg

# Test PNG generation
python -m iptables_graph -f png < examples/example.iptables > output.png

# Or run directly
cat examples/example.iptables | python src/iptables_graph/__main__.py

# Test with Docker
cat examples/example.iptables | docker run --rm -i iptables-graph:1.0.0 -f svg > output.svg
```

## Code Quality

### Python Code Style

- Follow PEP 8 guidelines
- Use meaningful variable names
- Add docstrings to all functions
- Keep functions focused and small

### Naming Conventions

- **Python package**: `src/iptables_graph/` (underscore - Python requirement)
- **PyPI package**: `iptables-graph` (dash - allowed in PyPI)
- **Docker image**: `iptables-graph:version` (dash - common in Docker)
- **Executable**: `iptables-graph` (dash - user-friendly CLI)
- **Module import**: `import iptables_graph` or `python -m iptables_graph`

## Common Issues

### Import Error

If you see `ModuleNotFoundError`:
```bash
# Install in development mode
pip install -e .

# Or run directly
python -m iptables_graph

# Or use full path
python src/iptables_graph/__main__.py

# For PyInstaller builds
pyinstaller iptables-graph.spec
```

### Docker Build Fails

```bash
# Clean Docker cache
make docker-clean

# Rebuild from scratch
docker build --no-cache -t iptables-graph .
```

### Version Mismatch

```bash
# Check current version
cat VERSION

# Verify Docker image tag
docker images | grep iptables-graph

# Rebuild with correct version
make docker-build
```

## Need Help?

- Open an issue on GitHub: https://github.com/SangHakLee/iptables-graph/issues
- Check existing issues and discussions

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
