# Restoring Original Ubuntu GNOME

## Quick Restore

Run the restore script:
```bash
cd SnowOS
./restore-desktop.sh
```

This will:
1. Find the latest backup
2. Restore GNOME settings
3. Disable SnowOS extensions
4. Remove Plank configuration
5. Optionally remove installed packages

## What Gets Restored

### Automatically Restored
- **dconf settings** (all GNOME settings)
- **~/.config/** (application configs)
- **~/.local/share/gnome-shell/** (extensions)
- **~/.themes/** (custom themes)
- **~/.icons/** (custom icons)

### Reset to Defaults
- GTK theme → Adwaita
- Icon theme → Yaru/Adwaita
- Font → Ubuntu/Cantarell
- Window buttons → Right side (Ubuntu default)
- Animations → Enabled
- Extensions → Ubuntu defaults only

### Removed
- Plank dock & autostart
- SnowOS performance script
- SnowOS welcome screen
- Custom wallpapers (SnowOS folder)
- Custom keybindings (Super+Space search)

## Manual Restore (If Script Fails)

### 1. Disable Extensions
```bash
# Disable SnowOS extensions
gnome-extensions disable blur-my-shell@aunetx
gnome-extensions disable search-light@s3r3n1t7.github.com
gnome-extensions disable magic-lamp@laxatives.github.io
gnome-extensions disable user-theme@gnome-shell-extensions.gcampax.github.com

# Reset Dash to Dock
gsettings reset org.gnome.shell.extensions.dash-to-dock dock-position
gsettings reset org.gnome.shell.extensions.dash-to-dock autohide
gsettings reset org.gnome.shell.extensions.dash-to-dock intellihide
gsettings reset org.gnome.shell.extensions.dash-to-dock extend-height
gsettings reset org.gnome.shell.extensions.dash-to-dock transparency-mode
gsettings reset org.gnome.shell.extensions.dash-to-dock background-opacity
gsettings reset org.gnome.shell.extensions.dash-to-dock show-applications-button
gsettings reset org.gnome.shell.extensions.dash-to-dock show-trash
```

### 2. Reset GNOME Settings
```bash
# Theme & Appearance
gsettings reset org.gnome.desktop.interface gtk-theme
gsettings reset org.gnome.desktop.interface icon-theme
gsettings reset org.gnome.desktop.interface font-name
gsettings reset org.gnome.desktop.interface document-font-name
gsettings reset org.gnome.desktop.interface monospace-font-name
gsettings reset org.gnome.desktop.interface color-scheme

# Window Behavior
gsettings reset org.gnome.desktop.wm.preferences button-layout
gsettings reset org.gnome.desktop.interface enable-animations
gsettings reset org.gnome.desktop.interface enable-hot-corners
gsettings reset org.gnome.desktop.interface clock-show-weekday
gsettings reset org.gnome.desktop.interface clock-format

# Keybindings
gsettings reset org.gnome.mutter overlay-key
gsettings reset org.gnome.settings-daemon.plugins.media-keys terminal
gsettings reset org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/
```

### 3. Remove Plank
```bash
# Kill and remove config
pkill plank
rm -rf ~/.config/plank
rm -f ~/.config/autostart/plank.desktop
```

### 4. Remove SnowOS Files
```bash
rm -f ~/.local/bin/snowos-performance
rm -f ~/.config/autostart/snowos-welcome.desktop
rm -rf ~/Pictures/Wallpapers/SnowOS
```

### 5. Remove Packages (Optional)
```bash
sudo apt remove --purge -y \
    plank \
    gnome-tweaks \
    gnome-shell-extension-manager \
    fonts-inter \
    fonts-jetbrains-mono
sudo apt autoremove -y
```

### 6. Restore from Backup (If Available)
```bash
# Find backup
ls -la ~/.snowos-backup-*/

# Restore dconf
dconf load / < ~/.snowos-backup-YYYYMMDD-HHMMSS/dconf-backup.ini

# Restore configs
rsync -a ~/.snowos-backup-YYYYMMDD-HHMMSS/.config/ ~/.config/
rsync -a ~/.snowos-backup-YYYYMMDD-HHMMSS/.local/share/gnome-shell/ ~/.local/share/gnome-shell/
rsync -a ~/.snowos-backup-YYYYMMDD-HHMMSS/.themes/ ~/.themes/
rsync -a ~/.snowos-backup-YYYYMMDD-HHMMSS/.icons/ ~/.icons/
```

## Nuclear Option: Reset All GNOME Settings

**Warning:** This resets ALL GNOME settings to defaults.

```bash
# Reset everything
gsettings reset-recursively org.gnome

# Or dconf
dconf reset -f /
```

Then reboot.

## Reinstalling Ubuntu Desktop (Clean Slate)

If you want a completely fresh Ubuntu desktop:

```bash
# Reinstall ubuntu-desktop metapackage
sudo apt update
sudo apt install --reinstall -y ubuntu-desktop ubuntu-desktop-minimal

# Reinstall GNOME Shell
sudo apt install --reinstall -y gnome-shell gnome-shell-extension-ubuntu-dock

# Reconfigure
sudo dpkg-reconfigure gdm3
sudo dpkg-reconfigure lightdm  # if installed
```

## Verifying Restore

After restore, verify:
```bash
# Check theme
gsettings get org.gnome.desktop.interface gtk-theme
# Should be: 'Yaru' or 'Adwaita'

# Check icons
gsettings get org.gnome.desktop.interface icon-theme
# Should be: 'Yaru' or 'Adwaita'

# Check extensions
gnome-extensions list --enabled
# Should only show Ubuntu defaults

# Check dock
gsettings get org.gnome.shell.extensions.dash-to-dock dock-position
# Should be: 'BOTTOM' or default

# Check Plank
which plank && plank --version
# Should not be configured for autostart
```

## What NOT to Remove

These are core Ubuntu packages - **do not remove**:
- `ubuntu-desktop`
- `gnome-shell`
- `gdm3`
- `network-manager`
- `pipewire`
- `systemd`
- `linux-generic`
- `grub-efi-amd64`

## After Restore

1. **Log out and back in** (or reboot)
2. **Verify desktop works** normally
3. **Reconfigure preferences** (wallpaper, favorites, etc.)
4. **Reinstall any extensions** you want via Extension Manager

## Troubleshooting Restore

### Settings Not Resetting
```bash
# Force reload
dconf update
# Or restart GNOME Shell
# X11: Alt+F2 → r
# Wayland: Log out/in
```

### Extensions Still Showing
```bash
# Remove extension directories
rm -rf ~/.local/share/gnome-shell/extensions/blur-my-shell@aunetx
rm -rf ~/.local/share/gnome-shell/extensions/search-light@s3r3n1t7.github.com
rm -rf ~/.local/share/gnome-shell/extensions/magic-lamp@laxatives.github.io
```

### Theme Still Applied
```bash
# Remove theme directories
rm -rf ~/.themes/WhiteSur*
rm -rf /usr/share/themes/WhiteSur*  # if installed system-wide
rm -rf ~/.icons/WhiteSur*
rm -rf /usr/share/icons/WhiteSur*
```

### Dock Still Shows Plank
```bash
# Check autostart
ls ~/.config/autostart/ | grep plank
# Remove if found
```

## Backup Location

Backups are stored at:
```
~/.snowos-backup-YYYYMMDD-HHMMSS/
├── .config/
├── .local/share/gnome-shell/
├── .themes/
├── .icons/
└── dconf-backup.ini
```

Keep these backups until you're sure the restore worked correctly.