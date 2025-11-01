"""
iptables-graph: Visualize iptables packet flow as Graphviz diagrams.

This package converts iptables-save output to DOT, SVG, or PNG formats
with color-coded tables and chains for easy understanding.
"""

from pathlib import Path

# Read version from installed package metadata (for pip installed package)
# or from pyproject.toml (for development)
try:
    from importlib.metadata import version
    __version__ = version("iptables-graph")
except Exception:
    # Fallback to pyproject.toml for development
    import re
    _pyproject_file = Path(__file__).parent.parent.parent / "pyproject.toml"
    _content = _pyproject_file.read_text()
    _match = re.search(r'^version\s*=\s*"([^"]+)"', _content, re.MULTILINE)
    __version__ = _match.group(1) if _match else "unknown"

__author__ = "sanghaklee"
__email__ = "code.ryan.lee@gmail.com"
__license__ = "MIT"

# Import main function for convenience
from .__main__ import main

__all__ = ["main", "__version__"]
