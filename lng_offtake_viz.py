#!/usr/bin/env python3
"""
LNG Offtake Visualization Wrapper

This is a compatibility wrapper that calls the visualization module.
"""

import sys
from pathlib import Path
from visualization import generate_all_visualizations

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python lng_offtake_viz.py <output_dir>")
        sys.exit(1)
    
    output_dir = Path(sys.argv[1])
    generate_all_visualizations(output_dir)

