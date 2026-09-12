#!/bin/bash
# SnowOS Restore Script
# Restores original Ubuntu GNOME configuration

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

find_latest_backup() {
    local latest=""
    local latest_time=0
    
    for backup in "$HOME"/.snowos-backup-*; do
        if [[ -d "$backup" ]]; then
            local mtime=$(stat -c %Y "$backup" 2>/dev/null || echo 0)
            if [[ $mtime -gt $latest_time ]]; then
                latest_time=$mtime
                latest="$backup"
            fi
        fi
    done
    
    echo "$latest"
}

restore_configs() {
    local backup_dir="$1"
    
    log_info "Restoring configuration from $backup_dir..."
    
    # Restore dconf settings
    if [[ -f "$backup_dir/dconf-backup.ini" ]]; then
        log_info "Restoring dconf settings..."
        dconf load / < "$backup_dir/dconf-backup.ini" 2>/dev/null || log_warn "Partial dconf restore"
        log_ok "dconf settings restored"
    fi
    
    # Restore .config
    if [[ -d "$backup_dir/.config" ]]; then
        log_info "Restoring .config..."
        rsync -a --delete "$backup_dir/.config/" "$HOME/.config/" 2>/dev/null || true
        log_ok ".config restored"
    fi
    
    # Restore .local/share/gnome-shell
    if [[ -d "$backup_dir/.local/share/gnome-shell" ]]; then
        log_info "Restoring GNOME Shell extensions..."
        rsync -a --delete "$backup_dir/.local/share/gnome-shell/" "$HOME/.local/share/gnome-shell/" 2>/dev/null || true
        log_ok "GNOME Shell extensions restored"
    fi
    
    # Restore .themes
    if [[ -d "$backup_dir/.themes" ]]; then
        log_info "Restoring themes..."
        rsync -a --delete "$backup_dir/.themes/" "$HOME/.themes/" 2>/dev/null || true
        log_ok "Themes restored"
    fi
    
    # Restore .icons
    if [[ -d "$backup_dir/.icons" ]]; then
        log_info "Restoring icons..."
        rsync -a --delete "$backup_dir/.icons/" "$HOME/.icons/" 2>/dev/null || true
        log_ok "Icons restored"
    fi
}

disable_extensions() {
    log_info "Disabling SnowOS extensions..."
    
    local extensions=(
        "blur-my-shell@aunetx"
        "search-light@s3r3n1t7.github.com"
        "magic-lamp@laxatives.github.io"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
    )
    
    for ext in "${extensions[@]}"; do
        gnome-extensions disable "$ext" 2>/dev/null || true
    done
    
    # Reset Dash to Dock to defaults
    gsettings reset org.gnome.shell.extensions.dash-to-dock dock-position 2>/dev/null || true
    gsettings reset org.gnome.shell.extensions.dash-to-dock autohide 2>/dev/null || true
    gsettings reset org.gnome.shell.extensions.dash-to-dock intellihide 2>/dev/null || true
    gsettings reset org.gnome.shell.extensions.dash-to-dock extend-height 2>/dev/null || true
    gsettings reset org.gnome.shell.extensions.dash-to-dock transparency-mode 2>/dev/null || true
    gsettings reset org.gnome.shell.extensions.dash-to-dock background-opacity 2>/dev/null || true
    gsettings reset org.gnome.shell.extensions.dash-to-dock show-applications-button 2>/dev/null || true
    gsettings reset org.gnome.shell.extensions.dash-to-dock show-trash 2>/dev/null || true
    
    log_ok "Extensions disabled"
}

reset_gnome_settings() {
    log_info "Resetting GNOME settings to defaults..."
    
    # Theme
    gsettings reset org.gnome.desktop.interface gtk-theme 2>/dev/null || true
    gsettings reset org.gnome.desktop.interface icon-theme 2>/dev/null || true
    gsettings reset org.gnome.desktop.interface font-name 2>/dev/null || true
    gsettings reset org.gnome.desktop.interface document-font-name 2>/dev/null || true
    gsettings reset org.gnome.desktop.interface monospace-font-name 2>/dev/null || true
    gsettings reset org.gnome.desktop.interface color-scheme 2>/dev/null || true
    
    # Window buttons
    gsettings reset org.gnome.desktop.wm.preferences button-layout 2>/dev/null || true
    
    # Animations
    gsettings reset org.gnome.desktop.interface enable-animations 2>/dev/null || true
    
    # Top bar
    gsettings reset org.gnome.desktop.interface clock-show-weekday 2>/dev/null || true
    gsettings reset org.gnome.desktop.interface clock-format 2>/dev/null || true
    
    # Hot corners
    gsettings reset org.gnome.desktop.interface enable-hot-corners 2>/dev/null || true
    
    # Keybindings
    gsettings reset org.gnome.mutter overlay-key 2>/dev/null || true
    
    log_ok "GNOME settings reset"
}

remove_plank() {
    log_info "Removing Plank configuration..."
    
    # Remove autostart
    rm -f "$HOME/.config/autostart/plank.desktop"
    
    # Remove Plank config
    rm -rf "$HOME/.config/plank"
    
    # Kill Plank if running
    pkill plank 2>/dev/null || true
    
    log_ok "Plank removed"
}

remove_snowos_files() {
    log_info "Removing SnowOS files..."
    
    # Remove performance script
    rm -f "$HOME/.local/bin/snowos-performance"
    
    # Remove welcome autostart
    rm -f "$HOME/.config/autostart/snowos-welcome.desktop"
    
    # Remove wallpapers
    rm -rf "$HOME/Pictures/Wallpapers/SnowOS"
    
    log_ok "SnowOS files removed"
}

remove_packages() {
    log_info "Removing SnowOS packages (optional)..."
    
    read -p "Remove installed packages (plank, gnome-tweaks, etc.)? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo apt-get remove -y \
            plank \
            gnome-tweaks \
            gnome-shell-extension-manager \
            fonts-inter \
            fonts-jetbrains-mono \
            2>/dev/null || true
        sudo apt-get autoremove -y 2>/dev/null || true
        log_ok "Packages removed"
    else
        log_info "Packages kept"
    fi
}

main() {
    log_info "SnowOS Restore Utility"
    
    local backup_dir=$(find_latest_backup)
    
    if [[ -z "$backup_dir" ]]; then
        log_error "No backup found. Cannot restore automatically."
        log_info "Manual restore options:"
        log_info "1. Reset GNOME settings: gsettings reset-recursively org.gnome"
        log_info "2. Disable extensions via Extension Manager"
        log_info "3. Remove Plank config: rm -rf ~/.config/plank"
        exit 1
    fi
    
    log_info "Found backup: $backup_dir"
    echo
    read -p "Restore from this backup? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n $REPLY ]]; then
        log_info "Restore cancelled"
        exit 0
    fi
    
    disable_extensions
    restore_configs "$backup_dir"
    reset_gnome_settings
    remove_plank
    remove_snowos_files
    remove_packages
    
    log_ok "Restore complete!"
    log_info "Please log out and log back in (or reboot) to see changes."
}

main "$@"