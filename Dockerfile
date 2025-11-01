# Multi-stage Dockerfile for iptables-graph
#
# Usage:
#   # Build the image
#   docker build -t iptables-graph .
#
#   # Run directly (stdin -> stdout)
#   sudo iptables-save | docker run --rm -i iptables-graph
#
#   # Generate SVG
#   sudo iptables-save | docker run --rm -i iptables-graph -f svg > output.svg
#
#   # Generate PNG with file I/O
#   docker run --rm -v $(pwd):/data iptables-graph -i /data/input.txt -f png -o /data/output.png
#
#   # Extract executable to host (for deployment without Docker)
#   docker build --target builder -t iptables-graph:builder .
#   docker create --name tmp iptables-graph:builder
#   docker cp tmp:/app/dist/iptables-graph ./iptables-graph
#   docker rm tmp

# Build stage
FROM python:3.9-slim AS builder

# Install system dependencies
RUN apt-get update && apt-get install -y \
    graphviz \
    binutils \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source files
COPY src/ ./src/
COPY iptables-graph.spec .

# Build the executable
RUN pyinstaller iptables-graph.spec

# Runtime stage (default - lightweight image for running)
FROM python:3.9-slim

# Install only graphviz (needed at runtime for format conversion)
RUN apt-get update && apt-get install -y \
    graphviz \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy built executable from builder
COPY --from=builder /app/dist/iptables-graph /usr/local/bin/iptables-graph

# Make it executable
RUN chmod +x /usr/local/bin/iptables-graph

# Set entrypoint
ENTRYPOINT ["iptables-graph"]
