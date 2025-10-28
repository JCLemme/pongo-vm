#!/usr/bin/env python3
"""
Convert xterm_colors.json to GIMP palette format (.gpl)
"""

import json

def convert_xterm_to_gpl(json_path, output_path):
    """
    Convert xterm colors JSON to GIMP palette format

    Args:
        json_path: Path to the xterm_colors.json file
        output_path: Path for the output .gpl file
    """
    # Load the JSON file
    with open(json_path, 'r') as f:
        colors = json.load(f)

    # Open output file for writing
    with open(output_path, 'w') as f:
        # Write header
        f.write("GIMP Palette\n")
        f.write("#Palette Name: Xterm Colors\n")
        f.write("#Description: Standard xterm 256 color palette\n")
        f.write(f"#Colors: {len(colors)}\n")

        # Write each color
        # Sort by color index to maintain proper order
        for idx in sorted(colors.keys(), key=int):
            color = colors[idx]
            r = color['r']
            g = color['g']
            b = color['b']
            name = color['name']

            # Write color entry: R G B Name
            f.write(f"{r}\t{g}\t{b}\t{name}\n")

    print(f"Successfully converted {len(colors)} colors to {output_path}")

if __name__ == "__main__":
    convert_xterm_to_gpl("xterm_colors.json", "xterm_colors.gpl")
