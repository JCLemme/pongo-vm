#!/usr/bin/env python3
"""
Convert PNG images to Common Lisp data lists using xterm color palette
"""

import json
import sys
from pathlib import Path
from PIL import Image


class XtermPalette:
    """Xterm color palette lookup"""

    def __init__(self, json_path):
        """Load xterm colors from JSON"""
        with open(json_path, 'r') as f:
            colors = json.load(f)

        # Build RGB to color index lookup table
        # Process in ascending order so lower indices take precedence for duplicates
        self.rgb_to_index = {}
        for idx in sorted(colors.keys(), key=int):
            color_data = colors[idx]
            r = color_data['r']
            g = color_data['g']
            b = color_data['b']
            # Only set if not already present (keeps the lowest index)
            rgb_key = (r, g, b)
            if rgb_key not in self.rgb_to_index:
                self.rgb_to_index[rgb_key] = int(idx)

    def get_color_index(self, r, g, b):
        """
        Get xterm color index for RGB values

        Returns:
            Color index (0-255) or None if not found
        """
        return self.rgb_to_index.get((r, g, b))


def convert_png_to_lisp(png_path, output_path, palette):
    """
    Convert PNG to Common Lisp raw-data lists

    Args:
        png_path: Path to input PNG file
        output_path: Path to output .lisp file
        palette: XtermPalette instance
    """
    # Load the image
    img = Image.open(png_path)

    # Convert to RGB if not already (handles RGBA, P, etc.)
    if img.mode != 'RGB':
        img = img.convert('RGB')

    width, height = img.size
    pixels = img.load()

    # Generate symbol-safe name from filename
    basename = Path(png_path).stem
    symbol_name = basename.replace('-', '_').replace('.', '_')

    # Collect pixel data and validate colors
    pixel_data = []
    invalid_colors = set()

    for y in range(height):
        row_data = []
        for x in range(width):
            r, g, b = pixels[x, y]
            color_idx = palette.get_color_index(r, g, b)

            if color_idx is None:
                invalid_colors.add((r, g, b))
                row_data.append(None)
            else:
                row_data.append(color_idx)

        pixel_data.append(row_data)

    # Error out if invalid colors found
    if invalid_colors:
        print(f"ERROR: Found {len(invalid_colors)} color(s) not in xterm palette:", file=sys.stderr)
        for r, g, b in sorted(invalid_colors):
            print(f"  RGB({r}, {g}, {b})", file=sys.stderr)
        sys.exit(1)

    # Write output file
    with open(output_path, 'w') as f:
        f.write(f"; Converted from {Path(png_path).name}\n")
        f.write(f"; Size: {width}x{height}\n")
        f.write("\n")
        f.write(f"(at-label \"IMG_{symbol_name}_w\")\n")
        f.write(f"(raw-data '({width}))\n")
        f.write("\n")
        f.write(f"(at-label \"IMG_{symbol_name}_h\")\n")
        f.write(f"(raw-data '({height}))\n")
        f.write("\n")
        f.write(f"(at-label \"IMG_{symbol_name}_data\")\n")

        for row in pixel_data:
            # Format as hex values with Common Lisp hex notation
            hex_values = [f"#x{val:02X}" for val in row]
            f.write("(raw-data '(" + " ".join(hex_values) + "))\n")

    print(f"Successfully converted {png_path}")
    print(f"  Size: {width}x{height} pixels")
    print(f"  Output: {output_path}")


def main():
    if len(sys.argv) < 2:
        print("Usage: python png_to_lisp.py <input.png> [output.lisp]")
        print("  If output not specified, will use input name with .lisp extension")
        sys.exit(1)

    png_path = sys.argv[1]

    if len(sys.argv) >= 3:
        output_path = sys.argv[2]
    else:
        output_path = Path(png_path).with_suffix('.lisp')

    # Load palette
    palette = XtermPalette('xterm_colors.json')

    # Convert
    convert_png_to_lisp(png_path, output_path, palette)


if __name__ == "__main__":
    main()
