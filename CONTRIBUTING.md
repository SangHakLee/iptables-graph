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

The project uses **pyproject.toml** with **semantic-release** for automatic version management:

- Version is defined in `pyproject.toml` under `[tool.poetry]`
- Automatically bumped by `semantic-release` based on commit messages
- Uses Conventional Commits format (see Releasing section below)

```bash
# Check current version
grep '^version = ' pyproject.toml

# Version is automatically updated by semantic-release
make release

# Manual update (not recommended)
# Edit pyproject.toml: version = "1.0.2"
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
├── pyproject.toml           # Python package configuration & version management
├── iptables-graph.spec      # PyInstaller spec file
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
- **`pyproject.toml`**: Package configuration and version management (Poetry + semantic-release)
- **`iptables-graph.spec`**: PyInstaller configuration for building standalone executable
- **`Dockerfile`**: Multi-stage build for optimized Docker images

## Releasing

This project uses **Semantic Versioning** with **Conventional Commits** for automatic versioning and changelog generation.

### Conventional Commits Format

Follow the Conventional Commits format for all commits:

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

**Types:**
- `feat`: New feature (minor version bump: 1.0.0 → 1.1.0)
- `fix`: Bug fix (patch version bump: 1.0.0 → 1.0.1)
- `docs`: Documentation only changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `build`: Build system or dependencies
- `ci`: CI configuration
- `chore`: Other changes

**Breaking Changes:**
Add `BREAKING CHANGE:` in the footer for major version bump (1.0.0 → 2.0.0)

```bash
# Examples
git commit -m "feat: add SVG output format"
git commit -m "fix: handle empty iptables input"
git commit -m "feat!: redesign CLI arguments

BREAKING CHANGE: -o flag now requires explicit format type"
```

### Automatic Release Workflow

#### 1. Check Next Version

See what version would be released based on commits:

```bash
make version-check
```

#### 2. Create Release (Recommended)

Automatically bump version, update changelog, and create git tag:

```bash
make release
```

This will:
1. Analyze commits since last release
2. Determine next version (major/minor/patch)
3. Update `pyproject.toml` version
4. Generate/update `CHANGELOG.md`
5. Create git commit and tag
6. Push to GitHub

#### 3. Publish to PyPI

```bash
# Test on TestPyPI first
make pypi-test-upload

# Publish to production PyPI
make pypi-upload
```

#### 4. Publish Docker Image

```bash
make docker-push DOCKER_REGISTRY=yourusername/
```

### Manual Release (Not Recommended)

If you need to manually control the version:

```bash
# 1. Update version in pyproject.toml manually
# 2. Build and test
make test
make docker-build
make docker-test-run

# 3. Build PyPI package
make pypi-build
make pypi-check
make pypi-upload

# 4. Create git tag
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
grep '^version = ' pyproject.toml

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
