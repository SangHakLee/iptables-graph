Iptables-graph
======================

Visualize iptables packet flow as Graphviz diagrams. Convert `iptables-save` output to DOT, SVG, or PNG formats.

## Features

- 📊 Visualize packet flow through all iptables tables (raw, mangle, nat, filter)
- 🎨 Color-coded tables and chains for easy understanding
- 🔗 Show custom chains and jump targets
- 📤 Multiple output formats: DOT, SVG, PNG
- 🐳 Docker-based workflow (no host dependencies!)
- 📦 Optional: Install as Python package (DOT output only)

## Quick Start (Docker - Recommended)

### 1. Build the Docker image

```bash
# Clone the repository
git clone https://github.com/AChingYo/iptables-graph.git
cd iptables-graph

# Build Docker image
docker build -t iptables-graph .

# Or use make
make docker-build
```

### 2. Use it!

```bash
# Basic usage: DOT format to stdout
sudo iptables-save | docker run --rm -i iptables-graph

# Generate SVG
sudo iptables-save | docker run --rm -i iptables-graph -f svg > graph.svg

# Generate PNG
sudo iptables-save | docker run --rm -i iptables-graph -f png > graph.png

# Using a file as input
docker run --rm -v $(pwd):/data iptables-graph \
  -i /data/examples/example.iptables -f svg -o /data/output.svg
```

### 3. Create an alias for convenience

```bash
# Add to your ~/.bashrc or ~/.zshrc
alias iptables-graph='docker run --rm -i iptables-graph'

# Now you can use it like a regular command
sudo iptables-save | iptables-graph
sudo iptables-save | iptables-graph -f svg > graph.svg
```

## Installation Options

### Option 1: Docker (Recommended)

✅ **Advantages:**
- No host dependencies required
- All features work (DOT/SVG/PNG)
- Consistent environment
- Easy to distribute

```bash
docker build -t iptables-graph .
sudo iptables-save | docker run --rm -i iptables-graph
```

### Option 2: Python Package (pip)

⚠️ **Limitations:**
- DOT format output only
- Requires manual installation of graphviz for SVG/PNG conversion
- Lighter weight

```bash
pip install iptables-graph

# Use it
sudo iptables-save | iptables-graph > graph.dot

# Convert to SVG manually (requires graphviz)
dot -Tsvg graph.dot -o graph.svg
```

### Option 3: Standalone Executable

Extract executable from Docker (no Docker runtime needed after build):

```bash
make docker-build-exe
# Executable is now in dist/iptables-graph

sudo iptables-save | ./dist/iptables-graph
```

## Usage Examples

### Basic DOT output

```bash
sudo iptables-save | docker run --rm -i iptables-graph
```

### Generate SVG diagram

```bash
sudo iptables-save | docker run --rm -i iptables-graph -f svg > graph.svg
```

### Generate PNG image

```bash
sudo iptables-save | docker run --rm -i iptables-graph -f png > graph.png
```

### Read from file, write to file

```bash
docker run --rm -v $(pwd):/data iptables-graph \
  -i /data/input.txt -f svg -o /data/output.svg
```

### Test with included examples

```bash
# Using Docker
cat examples/example.iptables | docker run --rm -i iptables-graph

# Using make
make docker-test
make docker-test-run  # Tests all formats (DOT/SVG/PNG)
```

## Command Line Options

```
usage: iptables-graph [-h] [-i INPUT] [-o OUTPUT] [-f {dot,svg,png}]

iptables-save output → Graphviz converter (dot/svg/png)

optional arguments:
  -h, --help            show this help message and exit
  -i INPUT, --input INPUT
                        Input file (default: stdin)
  -o OUTPUT, --output OUTPUT
                        Output file (default: stdout for dot/svg, auto-named for png)
  -f {dot,svg,png}, --format {dot,svg,png}
                        Output format: dot (default), svg, or png
```

## Docker Hub (Optional)

You can push your built image to Docker Hub for easy distribution:

```bash
# Build and push
make docker-push DOCKER_REGISTRY=yourusername/

# Others can then use:
docker pull yourusername/iptables-graph:latest
sudo iptables-save | docker run --rm -i yourusername/iptables-graph
```

## Development

### Build locally with PyInstaller

```bash
# Install dependencies
pip install -r requirements.txt

# Build executable
make build

# Test
make test
make test-svg
make test-png
```

### Run tests

```bash
# Test Python script
make test

# Test Docker container
make docker-test
make docker-test-run
```

### Clean up

```bash
# Clean local build artifacts
make clean

# Clean Docker images
make docker-clean
```

## Example Graph

![example.svg](https://raw.githubusercontent.com/AChingYo/iptables-graph/main/example.svg)

## How It Works

1. **Parse** `iptables-save` output to extract rules, chains, and policies
2. **Generate** Graphviz DOT format with color-coded tables
3. **Convert** (optional) to SVG or PNG using graphviz

### Color Scheme

- 🔴 **raw** table: Red (#FA7070)
- 🔵 **mangle** table: Blue (#AEE2FF)
- 🟣 **nat** table: Purple (#E5D1FA)
- 🟢 **filter** table: Green (#BEF0CB)

## Requirements

### Docker Method
- Docker

### Local Build Method
- Python 3.9+
- PyInstaller (for building executable)
- Graphviz (for SVG/PNG conversion)

### Python Package Method
- Python 3.9+
- Graphviz (optional, for SVG/PNG conversion)

## License

[MIT License](LICENSE)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
