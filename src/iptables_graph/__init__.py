"""
iptables-graph: Visualize iptables packet flow as Graphviz diagrams.

This package converts iptables-save output to DOT, SVG, or PNG formats
with color-coded tables and chains for easy understanding.
"""

import os
from pathlib import Path

# Read version from VERSION file
_version_file = Path(__file__).parent.parent.parent / "VERSION"
__version__ = _version_file.read_text().strip()

__author__ = "sanghaklee"
__email__ = "code.ryan.lee@gmail.com"
__license__ = "MIT"

# Import main function for convenience
from .__main__ import main

__all__ = ["main", "__version__"]
