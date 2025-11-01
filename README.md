# iptables-graph

Visualize iptables packet flow as [Graphviz](https://graphviz.org) diagrams. Convert [iptables-save](https://man7.org/linux/man-pages/man8/iptables-save.8.html) output to DOT, SVG, or PNG formats.

> Inspired by [AChingYo/iptables-graph](https://github.com/AChingYo/iptables-graph)

[![PyPI](https://img.shields.io/pypi/v/iptables-graph?logo=pypi)](https://pypi.org/project/iptables-graph/)
[![Docker](https://img.shields.io/docker/v/sanghaklee/iptables-graph?logo=docker)](https://hub.docker.com/r/sanghaklee/iptables-graph)

## Features

- 📊 Visualize packet flow through all iptables tables (raw, mangle, nat, filter)
- 🎨 Color-coded tables and chains for easy understanding
- 🔗 Show custom chains and jump targets
- 📤 Multiple output formats: DOT, SVG, PNG
- 🐳 Docker-based (no host dependencies!)
- 📦 PyPI package (pipx install)

## Quick Start

### Option 1: Docker (Recommended)

No installation required! Just pull and run:

```bash
# Pull from Docker Hub
docker pull sanghaklee/iptables-graph

# Use it
sudo iptables-save | docker run --rm -i sanghaklee/iptables-graph

# Generate SVG
sudo iptables-save | docker run --rm -i sanghaklee/iptables-graph -f svg > graph.svg

# Generate PNG
sudo iptables-save | docker run --rm -i sanghaklee/iptables-graph -f png > example.png
```

**Create an alias for convenience:**

```bash
# Add to ~/.bashrc or ~/.zshrc
alias iptables-graph='docker run --rm -i sanghaklee/iptables-graph'

# Now use it like a regular command
sudo iptables-save | iptables-graph
sudo iptables-save | iptables-graph -f svg > graph.svg
```

### Option 2: PyPI Package

Install via pip:

```bash
pipx install iptables-graph
```

Use it:

```bash
# Generate DOT format
sudo iptables-save | iptables-graph > graph.dot

# Generate SVG (requires graphviz installed)
sudo iptables-save | iptables-graph -f svg > graph.svg

# Generate PNG (requires graphviz installed)
sudo iptables-save | iptables-graph -f png > example.png
```

**Note**: For SVG/PNG conversion, you need to install graphviz:
```bash
# Debian/Ubuntu
sudo apt-get install graphviz

# RHEL/CentOS
sudo yum install graphviz

# macOS
brew install graphviz
```

## Usage

### Basic DOT Output

```bash
sudo iptables-save | iptables-graph
```

Output:
```dot
digraph {
    graph [pad="0.5", nodesep="0.5", ranksep="2"];
    node [shape=plain]
    rankdir=LR;
    ...
}
```

### Generate SVG Diagram

```bash
sudo iptables-save | iptables-graph -f svg > graph.svg
```

### Generate PNG Image

```bash
sudo iptables-save | iptables-graph -f png > example.png
```

### Read from File

```bash
# Save iptables rules to file
sudo iptables-save > rules.txt

# Generate diagram
cat rules.txt | iptables-graph -f svg > diagram.svg
```

### Using with Docker Volumes

```bash
# For file input/output with Docker
docker run --rm sanghaklee/iptables-graph \
  -v $(pwd):/data
  -i /data/iptables-save.txt 
  -f svg 
  -o /data/diagram.svg
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
                        Output file (default: stdout)
  -f {dot,svg,png}, --format {dot,svg,png}
                        Output format: dot (default), svg, or png
```

## Example Output

![example.png](https://raw.githubusercontent.com/SangHakLee/iptables-graph/refs/heads/main/examples/example.png)

### Color Scheme

- 🔴 **raw** table: Red (#FA7070)
- 🔵 **mangle** table: Blue (#AEE2FF)
- 🟣 **nat** table: Purple (#E5D1FA)
- 🟢 **filter** table: Green (#BEF0CB)

## How It Works

1. **Parse** `iptables-save` output to extract rules, chains, and policies
2. **Generate** Graphviz DOT format with color-coded tables
3. **Convert** (optional) to SVG or PNG using graphviz

## Requirements

### Docker Method
- Docker only

### PyPI Method
- Python 3.7+
- Graphviz (optional, for SVG/PNG conversion)

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, building, and release process.

## License

[MIT License](LICENSE)

## Links

- PyPI: https://pypi.org/project/iptables-graph/
- Docker Hub: https://hub.docker.com/r/sanghaklee/iptables-graph
- GitHub: https://github.com/SangHakLee/iptables-graph
- Issues: https://github.com/SangHakLee/iptables-graph/issues
