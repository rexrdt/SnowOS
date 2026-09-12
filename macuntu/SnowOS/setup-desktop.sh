#!/bin/bash
# SnowOS Desktop Setup Script
# Configures an existing Ubuntu installation with SnowOS desktop

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
BACKUP_DIR="$HOME/.snowos-backup-$(date +%Y%m%d-%H%M%S)"

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

check_ubuntu_version() {
    log_info "Detecting Ubuntu version..."
    if [[ ! -f /etc/os-release ]]; then
        log_error "Not an Ubuntu system"
        exit 1
    fi
    source /etc/os-release
    UBUNTU_VERSION="$VERSION_ID"
    UBUNTU_CODENAME="$VERSION_CODENAME"
    log_ok "Ubuntu $UBUNTU_VERSION ($UBUNTU_CODENAME) detected"
}

check_gnome_version() {
    log_info "Detecting GNOME version..."
    if command -v gnome-shell &> /dev/null; then
        GNOME_VERSION=$(gnome-shell --version | awk '{print $3}')
        GNOME_MAJOR=$(echo "$GNOME_VERSION" | cut -d. -f1)
        GNOME_MINOR=$(echo "$GNOME_VERSION" | cut -d. -f2)
        log_ok "GNOME $GNOME_VERSION detected"
    else
        log_error "GNOME Shell not found"
        exit 1
    fi
}

check_display_server() {
    log_info "Detecting display server..."
    if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
        DISPLAY_SERVER="wayland"
        log_ok "Wayland session detected"
    elif [[ "$XDG_SESSION_TYPE" == "x11" ]]; then
        DISPLAY_SERVER="x11"
        log_warn "X11 session detected (Wayland recommended)"
    else
        DISPLAY_SERVER="unknown"
        log_warn "Unknown display server: $XDG_SESSION_TYPE"
    fi
}

backup_configs() {
    log_info "Backing up current configuration to $BACKUP_DIR..."
    mkdir -p "$BACKUP_DIR"
    
    # Backup GNOME settings
    if [[ -d "$HOME/.config" ]]; then
        cp -r "$HOME/.config" "$BACKUP_DIR/" 2>/dev/null || true
    fi
    
    # Backup GNOME Shell extensions
    if [[ -d "$HOME/.local/share/gnome-shell" ]]; then
        cp -r "$HOME/.local/share/gnome-shell" "$BACKUP_DIR/" 2>/dev/null || true
    fi
    
    # Backup themes
    if [[ -d "$HOME/.themes" ]]; then
        cp -r "$HOME/.themes" "$BACKUP_DIR/" 2>/dev/null || true
    fi
    
    # Backup icons
    if [[ -d "$HOME/.icons" ]]; then
        cp -r "$HOME/.icons" "$BACKUP_DIR/" 2>/dev/null || true
    fi
    
    # Backup dconf
    dconf dump / > "$BACKUP_DIR/dconf-backup.ini" 2>/dev/null || true
    
    log_ok "Backup created at $BACKUP_DIR"
}

install_packages() {
    log_info "Installing required packages..."
    
    local packages=(
        gnome-tweaks
        gnome-shell-extension-manager
        plank
        git
        curl
        wget
        unzip
        p7zip-full
        build-essential
        python3
        python3-pip
        ffmpeg
        htop
        neofetch
        gparted
        file-roller
        vlc
        gnome-shell-extensions
        chrome-gnome-shell
        fonts-inter
        fonts-noto-core
        fonts-jetbrains-mono
    )
    
    # Update package list
    sudo apt-get update -qq
    
    # Install packages with error tolerance
    for pkg in "${packages[@]}"; do
        if apt-cache show "$pkg" &>/dev/null; then
            log_info "Installing $pkg..."
            sudo apt-get install -y "$pkg" 2>/dev/null || log_warn "Failed to install $pkg (continuing)"
        else
            log_warn "Package $pkg not available in repositories (skipping)"
        fi
    done
    
    log_ok "Package installation complete"
}

install_whitesur_theme() {
    log_info "Installing WhiteSur GTK theme..."
    
    cd /tmp
    if [[ -d WhiteSur-gtk-theme ]]; then
        rm -rf WhiteSur-gtk-theme
    fi
    
    if git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git --depth=1 2>/dev/null; then
        cd WhiteSur-gtk-theme
        # Try different install options based on GNOME version
        if [[ $GNOME_MAJOR -ge 46 ]]; then
            ./install.sh -c Dark -c Light -l -N mojave -t all 2>/dev/null || \
            ./install.sh -c Dark -c Light 2>/dev/null || true
        else
            ./install.sh -c Dark -c Light 2>/dev/null || true
        fi
        log_ok "WhiteSur GTK theme installed"
    else
        log_warn "Failed to download WhiteSur GTK theme"
    fi
}

install_whitesur_icons() {
    log_info "Installing WhiteSur icon theme..."
    
    cd /tmp
    if [[ -d WhiteSur-icon-theme ]]; then
        rm -rf WhiteSur-icon-theme
    fi
    
    if git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git --depth=1 2>/dev/null; then
        cd WhiteSur-icon-theme
        ./install.sh 2>/dev/null || true
        log_ok "WhiteSur icon theme installed"
    else
        log_warn "Failed to download WhiteSur icon theme"
    fi
}

install_extensions() {
    log_info "Installing GNOME Shell extensions..."
    
    local EXT_DIR="$HOME/.local/share/gnome-shell/extensions"
    mkdir -p "$EXT_DIR"
    
    # Blur My Shell
    log_info "Installing Blur My Shell..."
    cd /tmp
    if [[ -d blur-my-shell ]]; then
        rm -rf blur-my-shell
    fi
    if git clone https://github.com/aunetx/blur-my-shell.git --depth=1 2>/dev/null; then
        cd blur-my-shell
        make install 2>/dev/null || {
            # Manual install fallback
            local uuid="blur-my-shell@aunetx"
            mkdir -p "$EXT_DIR/$uuid"
            cp -r src/* "$EXT_DIR/$uuid/" 2>/dev/null || true
            log_info "Blur My Shell installed manually"
        }
        log_ok "Blur My Shell installed"
    else
        log_warn "Failed to download Blur My Shell"
    fi
    
    # Search Light (check compatibility)
    log_info "Checking Search Light compatibility..."
    if [[ $GNOME_MAJOR -ge 42 && $GNOME_MAJOR -le 47 ]]; then
        cd /tmp
        if [[ -d search-light ]]; then
            rm -rf search-light
        fi
        if git clone https://github.com/S3r3n1t7/search-light.git --depth=1 2>/dev/null; then
            cd search-light
            make install 2>/dev/null || {
                local uuid="search-light@s3r3n1t7.github.com"
                mkdir -p "$EXT_DIR/$uuid"
                cp -r src/* "$EXT_DIR/$uuid/" 2>/dev/null || true
                log_info "Search Light installed manually"
            }
            log_ok "Search Light installed"
        else
            log_warn "Failed to download Search Light"
        fi
    else
        log_warn "Search Light may not be compatible with GNOME $GNOME_VERSION (skipping)"
    fi
    
    # Magic Lamp / Genie effect (check compatibility)
    log_info "Checking Magic Lamp compatibility..."
    if [[ $GNOME_MAJOR -ge 42 && $GNOME_MAJOR -le 47 ]]; then
        cd /tmp
        if [[ -d gnome-shell-extension-magic-lamp ]]; then
            rm -rf gnome-shell-extension-magic-lamp
        fi
        if git clone https://github.com/laxatives/gnome-shell-extension-magic-lamp.git --depth=1 2>/dev/null; then
            cd gnome-shell-extension-magic-lamp
            make install 2>/dev/null || {
                local uuid="magic-lamp@laxatives.github.io"
                mkdir -p "$EXT_DIR/$uuid"
                cp -r src/* "$EXT_DIR/$uuid/" 2>/dev/null || true
                log_info "Magic Lamp installed manually"
            }
            log_ok "Magic Lamp installed"
        else
            log_warn "Failed to download Magic Lamp"
        fi
    else
        log_warn "Magic Lamp may not be compatible with GNOME $GNOME_VERSION (skipping)"
    fi
}

configure_gnome() {
    log_info "Configuring GNOME desktop..."
    
    # Theme settings
    gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark' 2>/dev/null || log_warn "Could not set GTK theme"
    gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur' 2>/dev/null || log_warn "Could not set icon theme"
    gsettings set org.gnome.desktop.interface font-name 'Inter 11' 2>/dev/null || log_warn "Could not set font"
    gsettings set org.gnome.desktop.interface document-font-name 'Inter 11' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrains Mono 11' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    
    # Window behavior
    gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:' 2>/dev/null || true
    gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']" 2>/dev/null || true
    
    # Enable animations
    gsettings set org.gnome.desktop.interface enable-animations true 2>/dev/null || true
    
    # Top bar
    gsettings set org.gnome.desktop.interface clock-show-weekday true 2>/dev/null || true
    gsettings set org.gnome.desktop.interface clock-format '24h' 2>/dev/null || true
    
    # Workspaces
    gsettings set org.gnome.mutter dynamic-workspaces true 2>/dev/null || true
    gsettings set org.gnome.desktop.wm.preferences workspace-names "['Desktop 1', 'Desktop 2', 'Desktop 3', 'Desktop 4']" 2>/dev/null || true
    
    # Hot corners
    gsettings set org.gnome.desktop.interface enable-hot-corners true 2>/dev/null || true
    
    log_ok "GNOME configured"
}

configure_plank() {
    log_info "Configuring Plank dock..."
    
    local PLANK_DIR="$HOME/.config/plank/dock1"
    mkdir -p "$PLANK_DIR"
    
    # Main settings
    cat > "$PLANK_DIR/settings" << 'PLANK_EOF'
[PlankDockPreferences]
Theme=Transparent
Position=Bottom
AutoHide=Intelligent
IconSize=48
ZoomEnabled=true
ZoomPercent=150
ShowDockItem=false
PressureReveal=false
TimeFadeIn=200
TimeFadeOut=300
PLANK_EOF
    
    # Launchers
    mkdir -p "$PLANK_DIR/launchers"
    
    local launchers=(
        "org.gnome.Nautilus.desktop:Files"
        "firefox.desktop:Web Browser"
        "org.gnome.Terminal.desktop:Terminal"
        "org.gnome.Software.desktop:Software Center"
        "org.gnome.ControlCenter.desktop:Settings"
        "org.gnome.TextEditor.desktop:Text Editor"
        "org.gnome.Totem.desktop:Media Player"
    )
    
    for launcher in "${launchers[@]}"; do
        IFS=':' read -r desktop_file name <<< "$launcher"
        local dock_file="$PLANK_DIR/launchers/$(basename "$desktop_file" .desktop).dockitem"
        if [[ -f "/usr/share/applications/$desktop_file" ]] || [[ -f "/var/lib/snapd/desktop/applications/$desktop_file" ]]; then
            cat > "$dock_file" << DOCK_EOF
[PlankItemsDockItemPreferences]
Launcher=file:///usr/share/applications/$desktop_file
DOCK_EOF
        fi
    done
    
    # Trash
    cat > "$PLANK_DIR/launchers/user-trash.dockitem" << 'EOF'
[PlankItemsDockItemPreferences]
Launcher=trash:///
EOF
    
    # Autostart
    mkdir -p "$HOME/.config/autostart"
    cat > "$HOME/.config/autostart/plank.desktop" << 'AUTOSTART_EOF'
[Desktop Entry]
Type=Application
Name=Plank
Comment=Elegant, simple, clean dock
Exec=plank
Terminal=false
X-GNOME-Autostart-enabled=true
AUTOSTART_EOF
    
    log_ok "Plank configured"
}

enable_extensions() {
    log_info "Enabling GNOME extensions..."
    
    # Use gnome-extensions CLI if available
    if command -v gnome-extensions &> /dev/null; then
        gnome-extensions enable dash-to-dock@micxgx.gmail.com 2>/dev/null || true
        gnome-extensions enable blur-my-shell@aunetx 2>/dev/null || true
        gnome-extensions enable search-light@s3r3n1t7.github.com 2>/dev/null || true
        gnome-extensions enable magic-lamp@laxatives.github.io 2>/dev/null || true
        gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null || true
    else
        # Manual enable via dconf
        local enabled=$(gsettings get org.gnome.shell enabled-extensions 2>/dev/null | tr -d "[]'" | tr ',' '\n' | sed 's/^ *//g' | grep -v '^$')
        local extensions=(
            "dash-to-dock@micxgx.gmail.com"
            "blur-my-shell@aunetx"
            "search-light@s3r3n1t7.github.com"
            "magic-lamp@laxatives.github.io"
            "user-theme@gnome-shell-extensions.gcampax.github.com"
        )
        for ext in "${extensions[@]}"; do
            if ! echo "$enabled" | grep -q "$ext"; then
                enabled="$enabled '$ext'"
            fi
        done
        gsettings set org.gnome.shell enabled-extensions "[$(echo "$enabled" | tr '\n' ',' | sed 's/,$//')]" 2>/dev/null || true
    fi
    
    # Configure Dash to Dock to not conflict with Plank
    gsettings set org.gnome.shell.extensions.dash-to-dock dock-position BOTTOM 2>/dev/null || true
    gsettings set org.gnome.shell.extensions.dash-to-dock autohide true 2>/dev/null || true
    gsettings set org.gnome.shell.extensions.dash-to-dock intellihide true 2>/dev/null || true
    gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false 2>/dev/null || true
    gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode FIXED 2>/dev/null || true
    gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.0 2>/dev/null || true
    gsettings set org.gnome.shell.extensions.dash-to-dock show-applications-button false 2>/dev/null || true
    gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false 2>/dev/null || true
    
    # Configure Blur My Shell
    gsettings set org.gnome.shell.extensions.blur-my-shell panel-blur true 2>/dev/null || true
    gsettings set org.gnome.shell.extensions.blur-my-shell overview-blur true 2>/dev/null || true
    gsettings set org.gnome.shell.extensions.blur-my-shell appfolder-blur true 2>/dev/null || true
    gsettings set org.gnome.shell.extensions.blur-my-shell dialog-blur true 2>/dev/null || true
    
    log_ok "Extensions enabled and configured"
}

configure_keybindings() {
    log_info "Configuring keybindings..."
    
    # Super key for app launcher (overview)
    gsettings set org.gnome.mutter overlay-key 'Super_L' 2>/dev/null || true
    
    # Super+Space for search light (if available)
    gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "['<Super>Return']" 2>/dev/null || true
    
    # Custom shortcut for search-light
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']" 2>/dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Search Light' 2>/dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'dbus-send --session --type=method_call --dest=org.gnome.Shell /org/gnome/Shell org.gnome.Shell.Eval string:"Main.overview.show();"' 2>/dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Super>space' 2>/dev/null || true
    
    log_ok "Keybindings configured"
}

configure_performance_mode() {
    log_info "Setting up performance modes..."
    
    # Create performance mode script
    cat > "$HOME/.local/bin/snowos-performance" << 'PERF_EOF'
#!/bin/bash
# SnowOS Performance Mode Switcher

MODE="${1:-balanced}"

case "$MODE" in
    performance)
        gsettings set org.gnome.desktop.interface enable-animations false
        gsettings set org.gnome.shell.extensions.blur-my-shell panel-blur false
        gsettings set org.gnome.shell.extensions.blur-my-shell overview-blur false
        gsettings set org.gnome.shell.extensions.blur-my-shell appfolder-blur false
        gsettings set org.gnome.shell.extensions.blur-my-shell dialog-blur false
        gsettings set org.gnome.desktop.interface enable-hot-corners false
        gsettings set org.gnome.shell.extensions.dash-to-dock zoom-enabled false
        echo "Performance mode enabled"
        ;;
    balanced)
        gsettings set org.gnome.desktop.interface enable-animations true
        gsettings set org.gnome.shell.extensions.blur-my-shell panel-blur true
        gsettings set org.gnome.shell.extensions.blur-my-shell overview-blur true
        gsettings set org.gnome.shell.extensions.blur-my-shell appfolder-blur true
        gsettings set org.gnome.shell.extensions.blur-my-shell dialog-blur true
        gsettings set org.gnome.desktop.interface enable-hot-corners true
        gsettings set org.gnome.shell.extensions.dash-to-dock zoom-enabled true
        echo "Balanced mode enabled"
        ;;
    visual)
        gsettings set org.gnome.desktop.interface enable-animations true
        gsettings set org.gnome.shell.extensions.blur-my-shell panel-blur true
        gsettings set org.gnome.shell.extensions.blur-my-shell overview-blur true
        gsettings set org.gnome.shell.extensions.blur-my-shell appfolder-blur true
        gsettings set org.gnome.shell.extensions.blur-my-shell dialog-blur true
        gsettings set org.gnome.desktop.interface enable-hot-corners true
        gsettings set org.gnome.shell.extensions.dash-to-dock zoom-enabled true
        gsettings set org.gnome.shell.extensions.dash-to-dock zoom-percent 200
        echo "Visual mode enabled"
        ;;
    *)
        echo "Usage: snowos-performance [performance|balanced|visual]"
        exit 1
        ;;
esac
PERF_EOF
    chmod +x "$HOME/.local/bin/snowos-performance"
    
    # Add to PATH if not already
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    fi
    
    # Default to balanced
    "$HOME/.local/bin/snowos-performance" balanced
    
    log_ok "Performance modes configured"
}

apply_wallpaper() {
    log_info "Setting up wallpapers..."
    
    mkdir -p "$HOME/Pictures/Wallpapers/SnowOS"
    
    # Create simple wallpapers using ImageMagick if available
    if command -v convert &> /dev/null; then
        convert -size 3840x2160 gradient:#1a1a2e-#16213e "$HOME/Pictures/Wallpapers/SnowOS/default-dark.png" 2>/dev/null || true
        convert -size 3840x2160 gradient:#f5f5f5-#e8e8e8 "$HOME/Pictures/Wallpapers/SnowOS/default-light.png" 2>/dev/null || true
        convert -size 3840x2160 "radial-gradient:ellipse at center #2c3e50,#1a1a2e" "$HOME/Pictures/Wallpapers/SnowOS/abstract-1.png" 2>/dev/null || true
    fi
    
    # Set default wallpaper
    if [[ -f "$HOME/Pictures/Wallpapers/SnowOS/default-dark.png" ]]; then
        gsettings set org.gnome.desktop.background picture-uri "file://$HOME/Pictures/Wallpapers/SnowOS/default-dark.png" 2>/dev/null || true
        gsettings set org.gnome.desktop.background picture-uri-dark "file://$HOME/Pictures/Wallpapers/SnowOS/default-dark.png" 2>/dev/null || true
    fi
    
    log_ok "Wallpapers configured"
}

create_welcome() {
    log_info "Creating first-boot welcome..."
    
    mkdir -p "$HOME/.config/autostart"
    cat > "$HOME/.config/autostart/snowos-welcome.desktop" << 'WELCOME_EOF'
[Desktop Entry]
Type=Application
Name=SnowOS Welcome
Comment=Welcome to SnowOS
Exec=gnome-text-editor /usr/share/snowos/welcome.txt
Icon=applications-other
Terminal=false
X-GNOME-Autostart-enabled=true
WELCOME_EOF
    
    # Create welcome content
    sudo mkdir -p /usr/share/snowos
    sudo tee /usr/share/snowos/welcome.txt > /dev/null << 'WELCOME_TXT'
Welcome to SnowOS!

A macOS-inspired desktop experience built on Ubuntu Linux.

Quick Start:
- Press Super key for application launcher (Overview)
- Press Super+Space for Spotlight-style search
- Bottom dock (Plank) for favorite apps
- Top bar for system controls

Customization:
- GNOME Tweaks: Themes, fonts, extensions
- Extension Manager: Manage GNOME extensions
- Settings: System configuration

Performance Modes (run in terminal):
- snowos-performance performance  - Minimal effects, maximum speed
- snowos-performance balanced     - Moderate effects (default)
- snowos-performance visual       - Full effects and animations

Dark/Light Mode:
- Settings > Appearance > Style
- Or run: gsettings set org.gnome.desktop.interface color-scheme prefer-dark

Enjoy your new desktop!
WELCOME_TXT
    
    log_ok "Welcome screen configured"
}

verify_installation() {
    log_info "Verifying installation..."
    
    local checks=(
        "command -v plank"
        "command -v gnome-tweaks"
        "command -v gnome-shell-extension-manager"
        "gsettings get org.gnome.desktop.interface gtk-theme"
        "gsettings get org.gnome.desktop.interface icon-theme"
        "test -d $HOME/.local/share/gnome-shell/extensions/blur-my-shell@aunetx"
        "test -d $HOME/.config/plank/dock1"
    )
    
    local passed=0
    local failed=0
    
    for check in "${checks[@]}"; do
        if eval "$check" &>/dev/null; then
            log_ok "Check passed: $check"
            ((passed++))
        else
            log_warn "Check failed: $check"
            ((failed++))
        fi
    done
    
    log_info "Verification: $passed passed, $failed failed"
}

main() {
    log_info "Starting SnowOS desktop setup..."
    
    check_ubuntu_version
    check_gnome_version
    check_display_server
    backup_configs
    install_packages
    install_whitesur_theme
    install_whitesur_icons
    install_extensions
    configure_gnome
    configure_plank
    enable_extensions
    configure_keybindings
    configure_performance_mode
    apply_wallpaper
    create_welcome
    verify_installation
    
    log_ok "SnowOS desktop setup complete!"
    log_info "Please log out and log back in (or reboot) to see all changes."
    log_info "Backup saved at: $BACKUP_DIR"
}

main "$@"