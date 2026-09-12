#!/bin/bash
# SnowOS Welcome Screen - First Boot Setup Wizard

set -euo pipefail

# This runs on first boot via autostart
# Creates a guided setup experience

ZENITY=$(command -v zenity || command -v yad || echo "")

if [[ -z "$ZENITY" ]]; then
    # Fallback: just show text file
    gnome-text-editor /usr/share/snowos/welcome.txt 2>/dev/null || cat /usr/share/snowos/welcome.txt
    exit 0
fi

# Check if already configured
CONFIG_FILE="$HOME/.config/snowos/welcome-done"
if [[ -f "$CONFIG_FILE" ]]; then
    exit 0
fi

mkdir -p "$HOME/.config/snowos"

# Welcome
$ZENITY --info \
    --title="Welcome to SnowOS" \
    --text="Welcome to SnowOS!\n\nA macOS-inspired desktop experience built on Ubuntu Linux.\n\nLet's configure your desktop." \
    --width=400 \
    --height=200 \
    --ok-label="Continue" || exit 1

# Theme selection
THEME=$($ZENITY --list \
    --title="Desktop Appearance" \
    --text="Choose your default theme:" \
    --radiolist \
    --column="Select" --column="Theme" \
    TRUE "Dark (Default)" \
    FALSE "Light" \
    FALSE "Auto (Follow System)" \
    --width=400 --height=300) || exit 1

case "$THEME" in
    "Dark (Default)")
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
        gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark'
        ;;
    "Light")
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
        gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Light'
        ;;
    "Auto (Follow System)")
        gsettings set org.gnome.desktop.interface color-scheme 'default'
        ;;
esac

# Performance mode
PERF=$($ZENITY --list \
    --title="Performance Mode" \
    --text="Choose performance profile for your hardware:" \
    --radiolist \
    --column="Select" --column="Mode" --column="Description" \
    FALSE "Performance" "Minimal effects, maximum speed (older hardware)" \
    TRUE "Balanced" "Moderate effects, good balance (recommended)" \
    FALSE "Visual" "Full effects and animations (modern hardware)" \
    --width=500 --height=300) || exit 1

case "$PERF" in
    "Performance")
        "$HOME/.local/bin/snowos-performance" performance 2>/dev/null || true
        ;;
    "Balanced")
        "$HOME/.local/bin/snowos-performance" balanced 2>/dev/null || true
        ;;
    "Visual")
        "$HOME/.local/bin/snowos-performance" visual 2>/dev/null || true
        ;;
esac

# Dock position
DOCK_POS=$($ZENITY --list \
    --title="Dock Position" \
    --text="Where would you like the dock?" \
    --radiolist \
    --column="Select" --column="Position" \
    TRUE "Bottom" \
    FALSE "Left" \
    FALSE "Right" \
    --width=400 --height=250) || exit 1

case "$DOCK_POS" in
    "Bottom")
        sed -i 's/Position=.*/Position=Bottom/' "$HOME/.config/plank/dock1/settings" 2>/dev/null || true
        ;;
    "Left")
        sed -i 's/Position=.*/Position=Left/' "$HOME/.config/plank/dock1/settings" 2>/dev/null || true
        ;;
    "Right")
        sed -i 's/Position=.*/Position=Right/' "$HOME/.config/plank/dock1/settings" 2>/dev/null || true
        ;;
esac

# Restart Plank to apply position
pkill plank 2>/dev/null || true
sleep 1
plank &

# Final screen
$ZENITY --info \
    --title="Setup Complete" \
    --text="SnowOS is ready!\n\nQuick reference:\n• Super key → Application launcher\n• Super+Space → Spotlight search\n• Bottom dock → Favorite apps\n• Right-click dock → Preferences\n\nEnjoy your new desktop!" \
    --width=400 --height=300

# Mark as done
touch "$CONFIG_FILE"