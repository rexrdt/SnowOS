#!/bin/bash
# SnowOS Extension Installer
# Installs compatible GNOME Shell extensions

set -euo pipefail

# Detect GNOME version
GNOME_VERSION=$(gnome-shell --version | awk '{print $3}')
GNOME_MAJOR=$(echo "$GNOME_VERSION" | cut -d. -f1)
GNOME_MINOR=$(echo "$GNOME_VERSION" | cut -d. -f2)

echo "Detected GNOME $GNOME_VERSION (major: $GNOME_MAJOR)"

EXT_DIR="$HOME/.local/share/gnome-shell/extensions"
mkdir -p "$EXT_DIR"

install_extension() {
    local name="$1"
    local repo="$2"
    local uuid="$3"
    local min_version="${4:-0}"
    local max_version="${5:-99}"
    
    # Check version compatibility
    if [[ $GNOME_MAJOR -lt $min_version ]] || [[ $GNOME_MAJOR -gt $max_version ]]; then
        echo "[SKIP] $name: Requires GNOME $min_version-$max_version, have $GNOME_MAJOR"
        return 0
    fi
    
    echo "[INSTALL] $name..."
    
    cd /tmp
    rm -rf "$name"
    
    if git clone "https://github.com/$repo.git" --depth=1 2>/dev/null; then
        cd "$name"
        
        # Try make install first
        if [[ -f Makefile ]] && make install 2>/dev/null; then
            echo "[OK] $name installed via make"
        elif [[ -f meson.build ]] && meson setup build && meson install -C build 2>/dev/null; then
            echo "[OK] $name installed via meson"
        else
            # Manual install
            mkdir -p "$EXT_DIR/$uuid"
            if [[ -d src ]]; then
                cp -r src/* "$EXT_DIR/$uuid/"
            elif [[ -d "$uuid" ]]; then
                cp -r "$uuid"/* "$EXT_DIR/$uuid/"
            else
                cp -r * "$EXT_DIR/$uuid/" 2>/dev/null || true
            fi
            echo "[OK] $name installed manually"
        fi
    else
        echo "[WARN] Failed to clone $name"
        return 1
    fi
}

# Extensions to install (name, repo, uuid, min_gnome, max_gnome)
EXTENSIONS=(
    "blur-my-shell|aunetx/blur-my-shell|blur-my-shell@aunetx|42|47"
    "search-light|S3r3n1t7/search-light|search-light@s3r3n1t7.github.com|42|47"
    "magic-lamp|laxatives/gnome-shell-extension-magic-lamp|magic-lamp@laxatives.github.io|42|47"
)

for ext in "${EXTENSIONS[@]}"; do
    IFS='|' read -r name repo uuid min max <<< "$ext"
    install_extension "$name" "$repo" "$uuid" "$min" "$max"
done

# Enable extensions
echo "[ENABLE] Enabling extensions..."
for ext in "${EXTENSIONS[@]}"; do
    IFS='|' read -r name repo uuid min max <<< "$ext"
    gnome-extensions enable "$uuid" 2>/dev/null || true
done

# User Themes (built-in)
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null || true

# Dash to Dock (built-in on Ubuntu)
gnome-extensions enable dash-to-dock@micxgx.gmail.com 2>/dev/null || true

echo "[DONE] Extension installation complete"
echo "Restart GNOME Shell (Alt+F2 → r on X11, or log out/in on Wayland)"