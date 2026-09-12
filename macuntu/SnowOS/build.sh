#!/bin/bash
# SnowOS Build Script
# Builds a custom Ubuntu ISO with SnowOS desktop customization

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
BUILD_DIR="$PROJECT_ROOT/build"
OUTPUT_DIR="$BUILD_DIR/output"
WORK_DIR="$BUILD_DIR/work"
UBUNTU_VERSION="${UBUNTU_VERSION:-24.04}"
UBUNTU_CODENAME="${UBUNTU_CODENAME:-noble}"
ARCH="${ARCH:-amd64}"

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

check_dependencies() {
    log_info "Checking build dependencies..."
    local deps=(xorriso squashfs-tools genisoimage rsync wget curl gpg)
    local missing=()
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing[*]}"
        log_info "Install with: sudo apt update && sudo apt install -y ${missing[*]}"
        exit 1
    fi
    log_ok "All build dependencies satisfied"
}

download_ubuntu_iso() {
    local iso_url="https://releases.ubuntu.com/$UBUNTU_VERSION/ubuntu-$UBUNTU_VERSION-desktop-$ARCH.iso"
    local iso_path="$BUILD_DIR/ubuntu-$UBUNTU_VERSION-desktop-$ARCH.iso"
    
    log_info "Downloading Ubuntu $UBUNTU_VERSION ISO..."
    if [[ -f "$iso_path" ]]; then
        log_ok "ISO already exists: $iso_path"
        return 0
    fi
    
    mkdir -p "$BUILD_DIR"
    if wget -q --show-progress -O "$iso_path" "$iso_url"; then
        log_ok "Downloaded Ubuntu ISO"
    else
        log_error "Failed to download Ubuntu ISO"
        exit 1
    fi
}

extract_iso() {
    log_info "Extracting Ubuntu ISO..."
    rm -rf "$WORK_DIR"
    mkdir -p "$WORK_DIR/iso"
    mkdir -p "$WORK_DIR/squashfs"
    
    # Mount ISO
    sudo mount -o loop "$BUILD_DIR/ubuntu-$UBUNTU_VERSION-desktop-$ARCH.iso" "$WORK_DIR/iso"
    
    # Copy ISO contents
    rsync -a "$WORK_DIR/iso/" "$WORK_DIR/iso-extracted/"
    sudo umount "$WORK_DIR/iso"
    
    # Extract squashfs
    sudo unsquashfs -f -d "$WORK_DIR/squashfs" "$WORK_DIR/iso-extracted/casper/filesystem.squashfs"
    log_ok "ISO extracted"
}

prepare_chroot() {
    log_info "Preparing chroot environment..."
    
    # Copy DNS
    sudo cp /etc/resolv.conf "$WORK_DIR/squashfs/etc/resolv.conf"
    
    # Mount pseudo filesystems
    sudo mount --bind /dev "$WORK_DIR/squashfs/dev"
    sudo mount --bind /proc "$WORK_DIR/squashfs/proc"
    sudo mount --bind /sys "$WORK_DIR/squashfs/sys"
    sudo mount --bind /run "$WORK_DIR/squashfs/run"
    
    log_ok "Chroot environment prepared"
}

run_chroot_script() {
    local script="$1"
    log_info "Running chroot script: $script"
    
    sudo cp "$script" "$WORK_DIR/squashfs/tmp/"
    sudo chroot "$WORK_DIR/squashfs" /bin/bash "/tmp/$(basename "$script")"
    sudo rm "$WORK_DIR/squashfs/tmp/$(basename "$script")"
}

create_customization_script() {
    local script_path="$BUILD_DIR/customize.sh"
    cat > "$script_path" << 'CHROOT_EOF'
#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "[INFO] Updating package lists..."
apt-get update

echo "[INFO] Installing base packages..."
apt-get install -y \
    gnome-tweaks \
    gnome-shell-extension-manager \
    plank \
    git \
    curl \
    wget \
    unzip \
    p7zip-full \
    build-essential \
    python3 \
    python3-pip \
    ffmpeg \
    htop \
    neofetch \
    gparted \
    file-roller \
    vlc \
    gnome-shell-extensions \
    chrome-gnome-shell \
    || true

echo "[INFO] Installing WhiteSur theme..."
cd /tmp
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git --depth=1
cd WhiteSur-gtk-theme
./install.sh -c Dark -c Light -l -N mojave -t all 2>/dev/null || ./install.sh -c Dark -c Light 2>/dev/null || true

echo "[INFO] Installing WhiteSur icons..."
cd /tmp
git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git --depth=1
cd WhiteSur-icon-theme
./install.sh 2>/dev/null || true

echo "[INFO] Installing GNOME extensions..."
EXTENSION_DIR="/usr/share/gnome-shell/extensions"
mkdir -p "$EXTENSION_DIR"

# Dash to Dock (built-in on Ubuntu)
# Blur My Shell
cd /tmp
git clone https://github.com/aunetx/blur-my-shell.git --depth=1
cd blur-my-shell
make install 2>/dev/null || true

# Search Light (if compatible)
GNOME_VERSION=$(gnome-shell --version | awk '{print $3}' | cut -d. -f1,2)
if [[ "$GNOME_VERSION" == "42"* ]] || [[ "$GNOME_VERSION" == "43"* ]] || [[ "$GNOME_VERSION" == "44"* ]] || [[ "$GNOME_VERSION" == "45"* ]] || [[ "$GNOME_VERSION" == "46"* ]]; then
    cd /tmp
    git clone https://github.com/S3r3n1t7/search-light.git --depth=1
    cd search-light
    make install 2>/dev/null || true
fi

echo "[INFO] Configuring default settings..."
# Set default theme
gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur' 2>/dev/null || true
gsettings set org.gnome.desktop.interface font-name 'Inter 11' 2>/dev/null || true
gsettings set org.gnome.desktop.interface document-font-name 'Inter 11' 2>/dev/null || true
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrains Mono 11' 2>/dev/null || true

# Enable extensions
gnome-extensions enable dash-to-dock@micxgx.gmail.com 2>/dev/null || true
gnome-extensions enable blur-my-shell@aunetx 2>/dev/null || true
gnome-extensions enable search-light@s3r3n1t7.github.com 2>/dev/null || true

# Configure Plank
mkdir -p /etc/skel/.config/plank/dock1
cat > /etc/skel/.config/plank/dock1/settings << 'PLANK_EOF'
[PlankDockPreferences]
Theme=Transparent
Position=Bottom
AutoHide=Intelligent
IconSize=48
ZoomEnabled=true
ZoomPercent=150
ShowDockItem=false
PLANK_EOF

# Default dock items
mkdir -p /etc/skel/.config/plank/dock1/launchers
cat > /etc/skel/.config/plank/dock1/launchers/org.gnome.Nautilus.dockitem << 'EOF'
[PlankItemsDockItemPreferences]
Launcher=file:///usr/share/applications/org.gnome.Nautilus.desktop
EOF

cat > /etc/skel/.config/plank/dock1/launchers/org.gnome.Terminal.dockitem << 'EOF'
[PlankItemsDockItemPreferences]
Launcher=file:///usr/share/applications/org.gnome.Terminal.desktop
EOF

cat > /etc/skel/.config/plank/dock1/launchers/org.gnome.Software.dockitem << 'EOF'
[PlankItemsDockItemPreferences]
Launcher=file:///usr/share/applications/org.gnome.Software.desktop
EOF

cat > /etc/skel/skel/.config/plank/dock1/launchers/org.gnome.TextEditor.dockitem << 'EOF'
[PlankItemsDockItemPreferences]
Launcher=file:///usr/share/applications/org.gnome.TextEditor.desktop
EOF

cat > /etc/skel/.config/plank/dock1/launchers/org.gnome.Totem.dockitem << 'EOF'
[PlankItemsDockItemPreferences]
Launcher=file:///usr/share/applications/org.gnome.Totem.desktop
EOF

cat > /etc/skel/.config/plank/dock1/launchers/user-trash.dockitem << 'EOF'
[PlankItemsDockItemPreferences]
Launcher=trash:///
EOF

echo "[INFO] Installing fonts..."
apt-get install -y fonts-inter fonts-noto-core fonts-jetbrains-mono 2>/dev/null || true

echo "[INFO] Setting up wallpapers..."
mkdir -p /usr/share/backgrounds/snowos
# Create simple gradient wallpapers using ImageMagick if available
if command -v convert &> /dev/null; then
    convert -size 3840x2160 gradient:#1a1a2e-#16213e /usr/share/backgrounds/snowos/default-dark.png
    convert -size 3840x2160 gradient:#f5f5f5-#e8e8e8 /usr/share/backgrounds/snowos/default-light.png
fi

echo "[INFO] Configuring GDM..."
mkdir -p /etc/gdm3
cat > /etc/gdm3/custom.conf << 'GDM_EOF'
[daemon]
WaylandEnable=true
DefaultSession=ubuntu-wayland.desktop

[security]
AllowRoot=false

[xdmcp]
Enable=false

[chooser]
Multicast=false

[debug]
Enable=false
GDM_EOF

echo "[INFO] Creating SnowOS branding..."
mkdir -p /usr/share/snowos
cat > /usr/share/snowos/version << 'VER_EOF'
SnowOS 1.0
Based on Ubuntu 24.04 LTS
VER_EOF

cat > /usr/share/applications/snowos-welcome.desktop << 'WELCOME_EOF'
[Desktop Entry]
Type=Application
Name=SnowOS Welcome
Comment=Welcome to SnowOS
Exec=gnome-text-editor /usr/share/snowos/welcome.txt
Icon=applications-other
Terminal=false
Categories=System;
WELCOME_EOF

cat > /usr/share/snowos/welcome.txt << 'WELCOME_TXT'
Welcome to SnowOS!

A macOS-inspired desktop experience built on Ubuntu Linux.

Quick Start:
- Press Super key for application launcher
- Press Super+Space for Spotlight-style search
- Bottom dock (Plank) for favorite apps
- Top bar for system controls

Customization:
- GNOME Tweaks: Themes, fonts, extensions
- Extension Manager: Manage GNOME extensions
- Settings: System configuration

Performance Modes:
- Performance: Minimal effects, maximum speed
- Balanced: Moderate effects (default)
- Visual: Full effects and animations

Enjoy your new desktop!
WELCOME_TXT

echo "[INFO] Cleaning up..."
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*
CHROOT_EOF
    chmod +x "$script_path"
    echo "$script_path"
}

repack_squashfs() {
    log_info "Repacking squashfs filesystem..."
    sudo rm -f "$WORK_DIR/iso-extracted/casper/filesystem.squashfs"
    sudo mksquashfs "$WORK_DIR/squashfs" "$WORK_DIR/iso-extracted/casper/filesystem.squashfs" -comp xz -b 1M
    log_ok "Squashfs repacked"
}

create_iso() {
    local output_iso="$OUTPUT_DIR/SnowOS-$UBUNTU_VERSION-$ARCH.iso"
    log_info "Creating SnowOS ISO: $output_iso"
    
    mkdir -p "$OUTPUT_DIR"
    
    # Update manifest
    sudo chroot "$WORK_DIR/squashfs" dpkg-query -W --showformat='${Package} ${Version}\n' > "$WORK_DIR/iso-extracted/casper/filesystem.manifest"
    sudo cp "$WORK_DIR/iso-extracted/casper/filesystem.manifest" "$WORK_DIR/iso-extracted/casper/filesystem.manifest-desktop"
    
    # Create ISO
    cd "$WORK_DIR/iso-extracted"
    sudo xorriso -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -volid "SnowOS $UBUNTU_VERSION" \
        -output "$output_iso" \
        -eltorito-boot boot/grub/i386-pc/eltorito.img \
        -eltorito-catalog boot/grub/boot.cat \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        -eltorito-alt-boot \
        -e boot/grub/efi.img \
        -no-emul-boot \
        -isohybrid-gpt-basdat \
        -isohybrid-apm-hfsplus \
        .
    
    log_ok "ISO created: $output_iso"
}

cleanup() {
    log_info "Cleaning up build environment..."
    sudo umount -R "$WORK_DIR/squashfs" 2>/dev/null || true
    sudo umount "$WORK_DIR/iso" 2>/dev/null || true
    sudo rm -rf "$WORK_DIR"
    log_ok "Cleanup complete"
}

main() {
    log_info "Starting SnowOS build for Ubuntu $UBUNTU_VERSION ($ARCH)"
    
    check_dependencies
    download_ubuntu_iso
    extract_iso
    prepare_chroot
    
    local customize_script=$(create_customization_script)
    run_chroot_script "$customize_script"
    
    repack_squashfs
    create_iso
    cleanup
    
    log_ok "Build complete! ISO: $OUTPUT_DIR/SnowOS-$UBUNTU_VERSION-$ARCH.iso"
}

# Trap cleanup on exit
trap cleanup EXIT

main "$@"