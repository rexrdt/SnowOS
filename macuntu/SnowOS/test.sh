#!/bin/bash
# SnowOS Test Script
# Validates the SnowOS installation and configuration

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TOTAL=0
PASSED=0
FAILED=0
WARNINGS=0

log_info() { echo -e "${BLUE}[TEST]${NC} $*"; }
log_pass() { echo -e "${GREEN}[PASS]${NC} $*"; ((PASSED++)); }
log_fail() { echo -e "${RED}[FAIL]${NC} $*"; ((FAILED++)); }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; ((WARNINGS++)); }

run_test() {
    local name="$1"
    local cmd="$2"
    ((TOTAL++))
    log_info "Testing: $name"
    if eval "$cmd" &>/dev/null; then
        log_pass "$name"
        return 0
    else
        log_fail "$name"
        return 1
    fi
}

run_test_warn() {
    local name="$1"
    local cmd="$2"
    ((TOTAL++))
    log_info "Testing: $name"
    if eval "$cmd" &>/dev/null; then
        log_pass "$name"
        return 0
    else
        log_warn "$name (optional)"
        return 1
    fi
}

test_ubuntu_base() {
    log_info "=== Ubuntu Base System ==="
    run_test "Ubuntu OS" "grep -q 'Ubuntu' /etc/os-release"
    run_test "Systemd" "systemctl --version >/dev/null 2>&1"
    run_test "APT" "command -v apt >/dev/null"
    run_test "NetworkManager" "systemctl is-active --quiet NetworkManager"
    run_test "UFW" "command -v ufw >/dev/null"
}

test_gnome() {
    log_info "=== GNOME Desktop ==="
    run_test "GNOME Shell" "command -v gnome-shell >/dev/null"
    run_test "GNOME Version" "gnome-shell --version >/dev/null 2>&1"
    run_test "GNOME Settings" "command -v gnome-control-center >/dev/null"
    run_test "GNOME Tweaks" "command -v gnome-tweaks >/dev/null"
    run_test "Extension Manager" "command -v gnome-shell-extension-manager >/dev/null"
}

test_packages() {
    log_info "=== Required Packages ==="
    local packages=(
        "plank"
        "git"
        "curl"
        "wget"
        "unzip"
        "p7zip-full"
        "build-essential"
        "python3"
        "python3-pip"
        "ffmpeg"
        "htop"
        "neofetch"
        "gparted"
        "file-roller"
        "vlc"
    )
    
    for pkg in "${packages[@]}"; do
        run_test_warn "Package: $pkg" "dpkg -l | grep -q \"^ii  $pkg \""
    done
}

test_theme() {
    log_info "=== Theme & Icons ==="
    run_test_warn "WhiteSur GTK Theme" "test -d \"$HOME/.themes/WhiteSur\" || test -d \"/usr/share/themes/WhiteSur\""
    run_test_warn "WhiteSur Dark Variant" "test -d \"$HOME/.themes/WhiteSur-Dark\" || test -d \"/usr/share/themes/WhiteSur-Dark\""
    run_test_warn "WhiteSur Icons" "test -d \"$HOME/.icons/WhiteSur\" || test -d \"/usr/share/icons/WhiteSur\""
    run_test_warn "GTK Theme Set" "gsettings get org.gnome.desktop.interface gtk-theme | grep -q WhiteSur"
    run_test_warn "Icon Theme Set" "gsettings get org.gnome.desktop.interface icon-theme | grep -q WhiteSur"
    run_test_warn "Font Set" "gsettings get org.gnome.desktop.interface font-name | grep -q -i inter"
}

test_plank() {
    log_info "=== Plank Dock ==="
    run_test "Plank Installed" "command -v plank >/dev/null"
    run_test "Plank Config" "test -f \"$HOME/.config/plank/dock1/settings\""
    run_test "Plank Launchers" "test -d \"$HOME/.config/plank/dock1/launchers\""
    run_test "Plank Autostart" "test -f \"$HOME/.config/autostart/plank.desktop\""
}

test_extensions() {
    log_info "=== GNOME Extensions ==="
    local ext_dir="$HOME/.local/share/gnome-shell/extensions"
    
    run_test_warn "Dash to Dock" "gnome-extensions list --enabled | grep -q dash-to-dock || gsettings get org.gnome.shell enabled-extensions | grep -q dash-to-dock"
    run_test_warn "Blur My Shell" "test -d \"$ext_dir/blur-my-shell@aunetx\" || test -d \"/usr/share/gnome-shell/extensions/blur-my-shell@aunetx\""
    run_test_warn "Search Light" "test -d \"$ext_dir/search-light@s3r3n1t7.github.com\" || test -d \"/usr/share/gnome-shell/extensions/search-light@s3r3n1t7.github.com\""
    run_test_warn "Magic Lamp" "test -d \"$ext_dir/magic-lamp@laxatives.github.io\" || test -d \"/usr/share/gnome-shell/extensions/magic-lamp@laxatives.github.io\""
    run_test_warn "User Themes" "gnome-extensions list --enabled | grep -q user-theme || gsettings get org.gnome.shell enabled-extensions | grep -q user-theme"
}

test_keybindings() {
    log_info "=== Keybindings ==="
    run_test_warn "Super Key (Overlay)" "gsettings get org.gnome.mutter overlay-key | grep -q Super"
    run_test_warn "Super+Space (Search)" "gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding | grep -q '<Super>space'"
}

test_performance_modes() {
    log_info "=== Performance Modes ==="
    run_test "Performance Script" "test -f \"$HOME/.local/bin/snowos-performance\""
    run_test "Script Executable" "test -x \"$HOME/.local/bin/snowos-performance\""
}

test_wallpapers() {
    log_info "=== Wallpapers ==="
    run_test_warn "Wallpaper Directory" "test -d \"$HOME/Pictures/Wallpapers/SnowOS\""
    run_test_warn "Dark Wallpaper" "test -f \"$HOME/Pictures/Wallpapers/SnowOS/default-dark.png\""
    run_test_warn "Light Wallpaper" "test -f \"$HOME/Pictures/Wallpapers/SnowOS/default-light.png\""
    run_test_warn "Wallpaper Set" "gsettings get org.gnome.desktop.background picture-uri | grep -q SnowOS"
}

test_fonts() {
    log_info "=== Fonts ==="
    run_test_warn "Inter Font" "fc-list | grep -q -i inter"
    run_test_warn "Noto Fonts" "fc-list | grep -q -i noto"
    run_test_warn "JetBrains Mono" "fc-list | grep -q -i jetbrains"
}

test_scripts() {
    log_info "=== SnowOS Scripts ==="
    run_test "setup-desktop.sh" "test -f \"$HOME/SnowOS/setup-desktop.sh\" || test -f \"/opt/snowos/setup-desktop.sh\""
    run_test "restore-desktop.sh" "test -f \"$HOME/SnowOS/restore-desktop.sh\" || test -f \"/opt/snowos/restore-desktop.sh\""
    run_test "snowos-performance" "test -f \"$HOME/.local/bin/snowos-performance\""
}

test_hardware_compat() {
    log_info "=== Hardware Compatibility ==="
    run_test "CPU Info" "lscpu >/dev/null 2>&1"
    run_test "GPU Detection" "lspci | grep -i vga >/dev/null 2>&1"
    run_test "Storage" "lsblk >/dev/null 2>&1"
    run_test "USB" "lsusb >/dev/null 2>&1"
    run_test "Network" "ip link show >/dev/null 2>&1"
}

test_low_end_optimization() {
    log_info "=== Low-End Optimization ==="
    run_test_warn "No Excessive Services" "! systemctl list-units --type=service --state=running | grep -q -E '(heavy|bloat)'"
    run_test_warn "Animations Configurable" "gsettings get org.gnome.desktop.interface enable-animations >/dev/null 2>&1"
    run_test_warn "Blur Configurable" "gsettings list-schemas | grep -q blur-my-shell"
}

print_summary() {
    echo
    echo "========================================"
    echo "Test Summary"
    echo "========================================"
    echo "Total tests:  $TOTAL"
    echo "Passed:       $PASSED"
    echo "Failed:       $FAILED"
    echo "Warnings:     $WARNINGS"
    echo "========================================"
    
    if [[ $FAILED -eq 0 ]]; then
        log_pass "All critical tests passed!"
        return 0
    else
        log_fail "Some critical tests failed"
        return 1
    fi
}

main() {
    log_info "Starting SnowOS validation tests..."
    echo
    
    test_ubuntu_base
    test_gnome
    test_packages
    test_theme
    test_plank
    test_extensions
    test_keybindings
    test_performance_modes
    test_wallpapers
    test_fonts
    test_scripts
    test_hardware_compat
    test_low_end_optimization
    
    print_summary
}

main "$@"