#!/bin/bash
# SnowOS Wallpaper Generator
# Creates default wallpapers using ImageMagick

set -euo pipefail

OUTPUT_DIR="${1:-$HOME/Pictures/Wallpapers/SnowOS}"
mkdir -p "$OUTPUT_DIR"

# Check for ImageMagick
if ! command -v convert &> /dev/null; then
    echo "ImageMagick not found. Install with: sudo apt install imagemagick"
    exit 1
fi

WIDTH=3840
HEIGHT=2160

echo "Generating wallpapers in $OUTPUT_DIR..."

# Dark default - deep blue gradient
convert -size "${WIDTH}x${HEIGHT}" \
    gradient:'#1a1a2e-#16213e' \
    "$OUTPUT_DIR/default-dark.png"

# Light default - soft gray gradient
convert -size "${WIDTH}x${HEIGHT}" \
    gradient:'#f5f5f5-#e8e8e8' \
    "$OUTPUT_DIR/default-light.png"

# Abstract 1 - radial gradient
convert -size "${WIDTH}x${HEIGHT}" \
    radial-gradient:ellipse at center '#2c3e50','#1a1a2e' \
    "$OUTPUT_DIR/abstract-1.png"

# Abstract 2 - diagonal gradient
convert -size "${WIDTH}x${HEIGHT}" \
    gradient:'#0f0f23-#1a1a2e-#0d1b2a' \
    -rotate 45 \
    "$OUTPUT_DIR/abstract-2.png"

# Nature 1 - forest tones
convert -size "${WIDTH}x${HEIGHT}" \
    gradient:'#1b4332-#2d6a4f-#40916c' \
    "$OUTPUT_DIR/nature-1.png"

# Nature 2 - ocean tones
convert -size "${WIDTH}x${HEIGHT}" \
    gradient:'#001219-#005f73-#0a9396' \
    "$OUTPUT_DIR/nature-2.png"

# Nature 3 - sunset tones
convert -size "${WIDTH}x${HEIGHT}" \
    gradient:'#2b2d42-#8d99ae-#edf2f4' \
    "$OUTPUT_DIR/nature-3.png"

# Minimal 1 - solid dark
convert -size "${WIDTH}x${HEIGHT}" \
    xc:'#16213e' \
    "$OUTPUT_DIR/minimal-dark.png"

# Minimal 2 - solid light
convert -size "${WIDTH}x${HEIGHT}" \
    xc:'#f0f0f0' \
    "$OUTPUT_DIR/minimal-light.png"

# Minimal 3 - subtle pattern
convert -size "${WIDTH}x${HEIGHT}" \
    xc:'#1a1a2e' \
    -fill '#1e1e3e' -draw 'circle 0,0 100,100' \
    -fill '#22224e' -draw 'circle 1920,1080 200,200' \
    "$OUTPUT_DIR/minimal-pattern.png"

# SnowOS branded
convert -size "${WIDTH}x${HEIGHT}" \
    gradient:'#1a1a2e-#16213e' \
    -font DejaVu-Sans-Bold -pointsize 120 -fill white -gravity center \
    -annotate +0+0 "SnowOS" \
    -font DejaVu-Sans -pointsize 40 -fill '#8888aa' \
    -annotate +0+150 "macOS-inspired • Ubuntu-based" \
    "$OUTPUT_DIR/snowos-branded.png"

echo "Wallpapers generated:"
ls -la "$OUTPUT_DIR"/*.png

# Set default if requested
if [[ "${2:-}" == "--set-default" ]]; then
    gsettings set org.gnome.desktop.background picture-uri "file://$OUTPUT_DIR/default-dark.png"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$OUTPUT_DIR/default-dark.png"
    gsettings set org.gnome.desktop.background picture-options 'zoom'
    echo "Default wallpaper set"
fi