# Troubleshooting Guide

## Common Issues

### Theme Not Applying

**Symptoms:** WhiteSur theme not showing, still using Yaru/Adwaita

**Solutions:**
```bash
# 1. Ensure User Themes extension is enabled
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com

# 2. Set theme via command line
gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark'
gsettings set org.gnome.shell.extensions.user-theme name 'WhiteSur-Dark'

# 3. Restart GNOME Shell
# X11: Alt+F2 → r → Enter
# Wayland: Log out and back in

# 4. Check theme exists
ls ~/.themes/WhiteSur-Dark/  # or /usr/share/themes/WhiteSur-Dark/

# 5. Reinstall theme
cd /tmp && git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git
cd WhiteSur-gtk-theme && ./install.sh -c Dark -c Light
```

### Icons Not Changing

**Symptoms:** Icons still show Yaru/Adwaita

**Solutions:**
```bash
# 1. Set icon theme
gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur'

# 2. Refresh icon cache
gtk-update-icon-cache -f ~/.icons/WhiteSur
gtk-update-icon-cache -f /usr/share/icons/WhiteSur

# 3. Reinstall icons
cd /tmp && git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git
cd WhiteSur-icon-theme && ./install.sh
```

### Extensions Not Working

**Symptoms:** Extensions don't load, show error, or don't appear in Extension Manager

**Solutions:**
```bash
# 1. Check GNOME version compatibility
gnome-shell --version
# Extensions must match GNOME major version

# 2. Check extension errors
gnome-extensions list --enabled
gnome-extensions info <extension-uuid>

# 3. Check logs
journalctl -f -u gnome-shell  # or /var/log/syslog
# Look for: "Extension <uuid> had error:"

# 4. Reinstall extension
rm -rf ~/.local/share/gnome-shell/extensions/<uuid>
# Re-run setup-desktop.sh or install manually

# 5. Disable conflicting extensions
gnome-extensions disable <other-extension>

# 6. Reset extension settings
gsettings reset-recursively org.gnome.shell.extensions.<extension-name>
```

### Plank Dock Issues

**Plank not starting:**
```bash
# Check if installed
which plank

# Try running manually
plank

# Check autostart
cat ~/.config/autostart/plank.desktop

# Add to startup applications manually
gnome-session-properties  # Add: plank
```

**Plank not showing / invisible:**
```bash
# Check theme
cat ~/.config/plank/dock1/settings
# Ensure: Theme=Transparent (or Matte)

# Check position
# Right-click dock → Preferences → Position

# Restart Plank
pkill plank && plank &
```

**Plank icons missing:**
```bash
# Check launchers exist
ls ~/.config/plank/dock1/launchers/

# Verify .desktop files exist
ls /usr/share/applications/org.gnome.Nautilus.desktop

# Re-create launcher
# Drag app from overview to dock, or create .dockitem manually
```

### Search Light (Super+Space) Not Working

```bash
# 1. Check extension enabled
gnome-extensions enable search-light@s3r3n1t7.github.com

# 2. Check keybinding
gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding
# Should be: '<Super>space'

# 3. Check for conflicts
gsettings list-recursively org.gnome.desktop.wm.keybindings | grep space
gsettings list-recursively org.gnome.settings-daemon.plugins.media-keys | grep space

# 4. Reset and reconfigure
gsettings reset org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/
# Re-run setup-desktop.sh
```

### Magic Lamp Animation Not Working

```bash
# 1. Check compatibility (GNOME 42-47)
gnome-shell --version

# 2. Enable extension
gnome-extensions enable magic-lamp@laxatives.github.io

# 3. Check settings
gsettings get org.gnome.shell.extensions.magic-lamp animation-duration
# Should be > 0

# 4. Alternative: Use built-in animations
gsettings set org.gnome.desktop.interface enable-animations true
```

### Blur My Shell Not Working

```bash
# 1. Enable extension
gnome-extensions enable blur-my-shell@aunetx

# 2. Check settings
gsettings get org.gnome.shell.extensions.blur-my-shell panel-blur
gsettings get org.gnome.shell.extensions.blur-my-shell overview-blur

# 3. Adjust opacity (0-255)
gsettings set org.gnome.shell.extensions.blur-my-shell panel-opacity 180

# 4. Check GPU/driver support
glxinfo | grep "OpenGL renderer"
# Requires compositing (Wayland or X11 with compositor)
```

### Performance Issues / Lag

```bash
# 1. Switch to performance mode
snowos-performance performance

# 2. Disable blur
gsettings set org.gnome.shell.extensions.blur-my-shell panel-blur false
gsettings set org.gnome.shell.extensions.blur-my-shell overview-blur false

# 3. Disable animations
gsettings set org.gnome.desktop.interface enable-animations false

# 4. Check resource usage
htop
# Look for: gnome-shell, Xorg, gsd-*, tracker-miner

# 5. Disable tracker (file indexing)
gsettings set org.freedesktop.Tracker.Miner.Files crawling-interval -2
gsettings set org.freedesktop.Tracker.Miner.Files enable-monitors false

# 6. Check GPU drivers
glxinfo | grep -i "OpenGL renderer"
# Should show your GPU, not "llvmpipe" (software rendering)
```

### Wayland vs X11 Issues

**Force X11 session:**
1. Log out
2. Click gear icon → "Ubuntu on Xorg" or "GNOME on Xorg"
3. Log in

**Check current session:**
```bash
echo $XDG_SESSION_TYPE
# wayland or x11
```

**Wayland-specific fixes:**
```bash
# NVIDIA + Wayland (Ubuntu 24.04+)
# Ensure nvidia-driver-550+ installed
# Add to /etc/default/grub:
# GRUB_CMDLINE_LINUX_DEFAULT="nvidia-drm.modeset=1"
sudo update-grub
```

### High CPU/Memory Usage

```bash
# Identify culprit
top -bn1 | head -20

# Common issues:
# gnome-shell: Too many extensions, memory leak
# tracker-miner-fs-3: File indexing
# gsd-*: GNOME Settings Daemon plugins
# packagekitd: Background updates

# Fixes:
# - Reduce extensions
# - Disable tracker (see Performance section)
# - Restart GNOME Shell (X11: Alt+F2 → r)
# - Reboot
```

### Display/Scaling Issues

**Fractional scaling not working:**
```bash
# Enable experimental fractional scaling
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"

# Set scale manually
gsettings set org.gnome.desktop.interface scaling-factor 2
gsettings set org.gnome.desktop.interface text-scaling-factor 1.0
```

**External monitor not detected:**
```bash
# Check connection
xrandr  # X11
wlr-randr  # Wayland

# Restart display manager
sudo systemctl restart gdm3

# Check cable/port
# Try different port/cable
```

### Audio Issues

```bash
# Restart PipeWire
systemctl --user restart pipewire pipewire-pulse wireplumber

# Check devices
wpctl status
pavucontrol  # GUI

# Check kernel module
dmesg | grep -i audio
lsmod | grep snd
```

### Network Issues

```bash
# Restart NetworkManager
sudo systemctl restart NetworkManager

# Check status
nmcli device status
nmcli connection show

# WiFi specific
rfkill list
sudo rfkill unblock wifi
```

### Boot Issues

**Black screen on boot:**
1. Edit GRUB: press `e` at GRUB menu
2. Add `nomodeset` to linux line
3. Press `F10` to boot
4. Install GPU drivers
5. Remove `nomodeset`

**Emergency mode:**
```bash
# Check disk space
df -h

# Check fstab
cat /etc/fstab

# Fix filesystem
sudo fsck /dev/sdXn

# Check journal
journalctl -xb
```

## Debugging Commands

### GNOME Shell Logs
```bash
# Wayland
journalctl -f -u gnome-shell

# X11
cat ~/.local/share/xorg/Xorg.0.log
```

### Extension Debugging
```bash
# Enable debug logging
export GNOME_SHELL_EXTENSION_DEBUG=1
gnome-shell --replace &

# Or use Looking Glass
# Alt+F2 → lg → Extensions tab
```

### DConf/Debugging Settings
```bash
# Watch settings changes
dconf watch /

# Dump all settings
dconf dump / > all-settings.ini

# Compare
diff <(dconf dump /org/gnome/) backup-settings.ini
```

### Package Verification
```bash
# Verify installed packages
dpkg -l | grep -E '(plank|gnome-tweaks|white|gnome-shell-ext)'

# Check for broken packages
sudo apt --fix-broken install
sudo dpkg --configure -a
```

## Getting Help

### Information to Include
When reporting issues, include:
```bash
# System info
lsb_release -a
gnome-shell --version
uname -r
echo $XDG_SESSION_TYPE
lspci -nn | grep -i vga

# Extension status
gnome-extensions list --enabled

# Theme settings
gsettings get org.gnome.desktop.interface gtk-theme
gsettings get org.gnome.desktop.interface icon-theme
```

### Resources
- **GitHub Issues:** Report bugs at SnowOS repository
- **Ubuntu Forums:** ubuntuforums.org
- **Ask Ubuntu:** askubuntu.com
- **GNOME Extensions:** extensions.gnome.org
- **WhiteSur Theme:** github.com/vinceliuice/WhiteSur-gtk-theme/issues

## Recovery Commands

### If Desktop Won't Load
```bash
# From TTY (Ctrl+Alt+F3)
# Login, then:

# Reset GNOME
dconf reset -f /org/gnome/

# Or reinstall desktop
sudo apt install --reinstall ubuntu-desktop

# Reconfigure display manager
sudo dpkg-reconfigure gdm3
```

### If Input Not Working
```bash
# From TTY
sudo apt install --reinstall xserver-xorg-input-all
sudo apt install --reinstall libinput10
```

### If Network Broken After Changes
```bash
# Reset NetworkManager
sudo rm /etc/NetworkManager/system-connections/*
sudo systemctl restart NetworkManager
```

## Prevention

### Before Major Changes
```bash
# Create backup
./restore-desktop.sh  # Creates backup before changes

# Or manual
cp -r ~/.config ~/.config.backup-$(date +%Y%m%d)
dconf dump / > ~/dconf-backup-$(date +%Y%m%d).ini
```

### Test in VM First
```bash
# Always test major changes in VM before real hardware
qemu-system-x86_64 -enable-kvm -m 4G -cdrom SnowOS.iso
```

### Keep System Updated
```bash
sudo apt update && sudo apt upgrade -y
# But hold GNOME version if extensions break:
sudo apt-mark hold gnome-shell
```