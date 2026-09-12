#!/bin/bash

# SnowOS Build Script
# Builds a customized Ubuntu 24.04-based SnowOS ISO

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

BUILD_DIR="$PROJECT_ROOT/build"
OUTPUT_DIR="$BUILD_DIR/output"
WORK_DIR="$BUILD_DIR/work"

UBUNTU_VERSION="${UBUNTU_VERSION:-24.04}"
UBUNTU_POINT_RELEASE="${UBUNTU_POINT_RELEASE:-24.04.3}"
ARCH="${ARCH:-amd64}"

ISO_NAME="ubuntu-${UBUNTU_POINT_RELEASE}-desktop-${ARCH}.iso"
ISO_PATH="$BUILD_DIR/$ISO_NAME"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_ok() {
    echo -e "${GREEN}[OK]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

check_dependencies() {
    log_info "Checking build dependencies..."

    local deps=(
        xorriso
        unsquashfs
        mksquashfs
        rsync
        wget
        curl
        gpg
        mount
        chroot
    )

    local missing=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing[*]}"
        exit 1
    fi

    log_ok "All build dependencies are installed"
}

download_ubuntu_iso() {
    log_info "Preparing Ubuntu $UBUNTU_POINT_RELEASE ISO..."

    mkdir -p "$BUILD_DIR"

    local iso_url="https://releases.ubuntu.com/24.04/${ISO_NAME}"

    if [[ -f "$ISO_PATH" ]]; then
        log_ok "Ubuntu ISO already exists:"
        echo "$ISO_PATH"
        return 0
    fi

    log_info "Downloading:"
    echo "$iso_url"

    wget \
        --progress=bar:force \
        -O "$ISO_PATH" \
        "$iso_url"

    if [[ ! -s "$ISO_PATH" ]]; then
        log_error "Downloaded ISO is empty"
        exit 1
    fi

    log_ok "Ubuntu ISO downloaded"
}

extract_iso() {
    log_info "Extracting Ubuntu ISO..."

    sudo rm -rf "$WORK_DIR"

    mkdir -p "$WORK_DIR"
    mkdir -p "$WORK_DIR/iso"
    mkdir -p "$WORK_DIR/iso-extracted"
    mkdir -p "$WORK_DIR/squashfs"

    log_info "Mounting Ubuntu ISO..."

    sudo mount -o loop,ro "$ISO_PATH" "$WORK_DIR/iso"

    log_info "Copying ISO contents..."

    sudo rsync -aH "$WORK_DIR/iso/" "$WORK_DIR/iso-extracted/"

    log_info "Unmounting ISO..."

    sudo umount "$WORK_DIR/iso"

    log_info "Extracting filesystem.squashfs..."

    sudo unsquashfs \
        -f \
        -d "$WORK_DIR/squashfs" \
        "$WORK_DIR/iso-extracted/casper/filesystem.squashfs"

    log_ok "Ubuntu filesystem extracted"
}

prepare_chroot() {
    log_info "Preparing chroot environment..."

    # Make sure required directories exist
    sudo mkdir -p \
        "$WORK_DIR/squashfs/dev" \
        "$WORK_DIR/squashfs/proc" \
        "$WORK_DIR/squashfs/sys" \
        "$WORK_DIR/squashfs/run"

    # DNS
    sudo cp --dereference /etc/resolv.conf \
        "$WORK_DIR/squashfs/etc/resolv.conf"

    log_info "Mounting /dev..."

    sudo mount --bind \
        /dev \
        "$WORK_DIR/squashfs/dev"

    log_info "Mounting /proc..."

    sudo mount -t proc \
        /proc \
        "$WORK_DIR/squashfs/proc"

    log_info "Mounting /sys..."

    sudo mount --bind \
        /sys \
        "$WORK_DIR/squashfs/sys"

    log_info "Mounting /run..."

    sudo mount --bind \
        /run \
        "$WORK_DIR/squashfs/run"

    log_ok "Chroot environment prepared"
}

run_chroot_script() {
    local script="$1"
    local script_name

    script_name="$(basename "$script")"

    log_info "Copying customization script into chroot..."

    sudo cp "$script" \
        "$WORK_DIR/squashfs/tmp/$script_name"

    sudo chmod +x \
        "$WORK_DIR/squashfs/tmp/$script_name"

    log_info "Running customization script..."

    sudo chroot "$WORK_DIR/squashfs" \
        /bin/bash "/tmp/$script_name"

    sudo rm -f \
        "$WORK_DIR/squashfs/tmp/$script_name"

    log_ok "Customization completed"
}

create_customization_script() {
    local script_path="$BUILD_DIR/customize.sh"

    cat > "$script_path" <<'CHROOT_EOF'
#!/bin/bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "[INFO] Updating package lists..."

apt-get update

echo "[INFO] Installing SnowOS packages..."

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
    gparted \
    file-roller \
    vlc \
    gnome-shell-extensions \
    fonts-noto-core \
    fonts-jetbrains-mono \
    imagemagick

echo "[INFO] Installing WhiteSur GTK theme..."

cd /tmp

rm -rf WhiteSur-gtk-theme

git clone \
    --depth=1 \
    https://github.com/vinceliuice/WhiteSur-gtk-theme.git

cd WhiteSur-gtk-theme

chmod +x install.sh

./install.sh \
    -c Dark \
    -c Light \
    -l \
    -N mojave \
    -t all \
    || ./install.sh -c Dark -c Light \
    || true

echo "[INFO] Installing WhiteSur icon theme..."

cd /tmp

rm -rf WhiteSur-icon-theme

git clone \
    --depth=1 \
    https://github.com/vinceliuice/WhiteSur-icon-theme.git

cd WhiteSur-icon-theme

chmod +x install.sh

./install.sh || true

echo "[INFO] Installing Blur My Shell..."

cd /tmp

rm -rf blur-my-shell

git clone \
    --depth=1 \
    https://github.com/aunetx/blur-my-shell.git

cd blur-my-shell

make install || true

echo "[INFO] Configuring GNOME..."

gsettings set \
    org.gnome.desktop.interface \
    gtk-theme \
    'WhiteSur-Dark' \
    2>/dev/null || true

gsettings set \
    org.gnome.desktop.interface \
    icon-theme \
    'WhiteSur' \
    2>/dev/null || true

gsettings set \
    org.gnome.desktop.interface \
    font-name \
    'Inter 11' \
    2>/dev/null || true

gsettings set \
    org.gnome.desktop.interface \
    document-font-name \
    'Inter 11' \
    2>/dev/null || true

gsettings set \
    org.gnome.desktop.interface \
    monospace-font-name \
    'JetBrains Mono 11' \
    2>/dev/null || true

echo "[INFO] Configuring Plank..."

mkdir -p \
    /etc/skel/.config/plank/dock1/launchers

cat > /etc/skel/.config/plank/dock1/settings <<'PLANK_EOF'
[PlankDockPreferences]
Theme=Transparent
Position=Bottom
AutoHide=Intelligent
IconSize=48
ZoomEnabled=true
ZoomPercent=150
ShowDockItem=false
PLANK_EOF

cat > /etc/skel/.config/plank/dock1/launchers/org.gnome.Nautilus.dockitem <<'EOF'
[PlankItemsDockItemPreferences]
Launcher=file:///usr/share/applications/org.gnome.Nautilus.desktop
EOF

cat > /etc/skel/.config/plank/dock1/launchers/org.gnome.Terminal.dockitem <<'EOF'
[PlankItemsDockItemPreferences]
Launcher=file:///usr/share/applications/org.gnome.Terminal.desktop
EOF

cat > /etc/skel/.config/plank/dock1/launchers/org.gnome.Software.dockitem <<'EOF'
[PlankItemsDockItemPreferences]
Launcher=file:///usr/share/applications/org.gnome.Software.desktop
EOF

cat > /etc/skel/.config/plank/dock1/launchers/org.gnome.TextEditor.dockitem <<'EOF'
[PlankItemsDockItemPreferences]
Launcher=file:///usr/share/applications/org.gnome.TextEditor.desktop
EOF

cat > /etc/skel/.config/plank/dock1/launchers/org.gnome.Totem.dockitem <<'EOF'
[PlankItemsDockItemPreferences]
Launcher=file:///usr/share/applications/org.gnome.Totem.desktop
EOF

cat > /etc/skel/.config/plank/dock1/launchers/user-trash.dockitem <<'EOF'
[PlankItemsDockItemPreferences]
Launcher=trash:///
EOF

echo "[INFO] Creating SnowOS directories..."

mkdir -p \
    /usr/share/backgrounds/snowos \
    /usr/share/snowos

echo "[INFO] Creating wallpapers..."

if command -v convert >/dev/null 2>&1; then

    convert \
        -size 3840x2160 \
        gradient:'#1a1a2e-#16213e' \
        /usr/share/backgrounds/snowos/default-dark.png

    convert \
        -size 3840x2160 \
        gradient:'#f5f5f5-#e8e8e8' \
        /usr/share/backgrounds/snowos/default-light.png

fi

echo "[INFO] Configuring GDM..."

mkdir -p /etc/gdm3

cat > /etc/gdm3/custom.conf <<'GDM_EOF'
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

cat > /usr/share/snowos/version <<'VER_EOF'
SnowOS 1.0
Based on Ubuntu 24.04 LTS
VER_EOF

cat > /usr/share/applications/snowos-welcome.desktop <<'WELCOME_EOF'
[Desktop Entry]
Type=Application
Name=SnowOS Welcome
Comment=Welcome to SnowOS
Exec=gnome-text-editor /usr/share/snowos/welcome.txt
Icon=applications-other
Terminal=false
Categories=System;
WELCOME_EOF

cat > /usr/share/snowos/welcome.txt <<'WELCOME_TXT'
Welcome to SnowOS!

A macOS-inspired desktop experience built on Ubuntu Linux.

Quick Start:

- Press Super for the application launcher
- Bottom dock for favorite applications
- Top bar for system controls

Customization:

- GNOME Tweaks
- Extension Manager
- System Settings

Enjoy SnowOS!
WELCOME_TXT

echo "[INFO] Cleaning package cache..."

apt-get clean

rm -rf /var/lib/apt/lists/*

rm -rf /tmp/*

echo "[OK] SnowOS customization finished"

CHROOT_EOF

    chmod +x "$script_path"

    echo "$script_path"
}

repack_squashfs() {
    log_info "Repacking SquashFS..."

    sudo rm -f \
        "$WORK_DIR/iso-extracted/casper/filesystem.squashfs"

    sudo mksquashfs \
        "$WORK_DIR/squashfs" \
        "$WORK_DIR/iso-extracted/casper/filesystem.squashfs" \
        -comp xz \
        -b 1M \
        -noappend

    log_ok "SquashFS repacked"
}

create_iso() {
    local output_iso="$OUTPUT_DIR/SnowOS-$UBUNTU_VERSION-$ARCH.iso"

    log_info "Creating SnowOS ISO..."

    mkdir -p "$OUTPUT_DIR"

    log_info "Updating filesystem manifest..."

    sudo chroot "$WORK_DIR/squashfs" \
        dpkg-query -W \
        --showformat='${Package} ${Version}\n' \
        > "$WORK_DIR/iso-extracted/casper/filesystem.manifest"

    sudo cp \
        "$WORK_DIR/iso-extracted/casper/filesystem.manifest" \
        "$WORK_DIR/iso-extracted/casper/filesystem.manifest-desktop"

    log_info "Running xorriso..."

    cd "$WORK_DIR/iso-extracted"

    sudo xorriso -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -volid "SnowOS $UBUNTU_VERSION" \
        -output "$output_iso" \
        -eltorito-boot boot/grub/i386-pc/eltorito.img \
        -eltorito-catalog boot/grub/boot.cat \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        -eltorito-alt-boot \
        -e boot/grub/efi.img \
        -no-emul-boot \
        -isohybrid-gpt-basdat \
        -isohybrid-apm-hfsplus \
        .

    log_ok "ISO created:"
    echo "$output_iso"
}

cleanup() {
    log_info "Cleaning up..."

    if [[ -d "$WORK_DIR/squashfs" ]]; then
        sudo umount -R \
            "$WORK_DIR/squashfs" \
            2>/dev/null || true
    fi

    if [[ -d "$WORK_DIR/iso" ]]; then
        sudo umount \
            "$WORK_DIR/iso" \
            2>/dev/null || true
    fi

    sudo rm -rf \
        "$WORK_DIR"

    log_ok "Cleanup complete"
}

main() {
    log_info "========================================"
    log_info "          SnowOS ISO Builder"
    log_info "========================================"

    log_info "Ubuntu version: $UBUNTU_VERSION"
    log_info "Ubuntu release: $UBUNTU_POINT_RELEASE"
    log_info "Architecture: $ARCH"

    check_dependencies
    download_ubuntu_iso
    extract_iso
    prepare_chroot

    local customize_script

    customize_script="$(create_customization_script)"

    run_chroot_script "$customize_script"

    repack_squashfs
    create_iso
    cleanup

    log_ok "========================================"
    log_ok "          BUILD COMPLETE"
    log_ok "========================================"

    echo ""
    echo "ISO:"
    echo "$OUTPUT_DIR/SnowOS-$UBUNTU_VERSION-$ARCH.iso"
}

trap cleanup EXIT

main "$@"
