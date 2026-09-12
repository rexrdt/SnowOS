# Icon Customization

## Default Icons: WhiteSur

SnowOS uses **WhiteSur Icon Theme** by vinceliuice, matching the WhiteSur GTK theme.

### Installation
```bash
# Included in setup-desktop.sh, or manual:
git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git
cd WhiteSur-icon-theme
./install.sh

# System-wide
sudo ./install.sh
```

### Variants
- `WhiteSur` - Default (colorful)
- `WhiteSur-mono` - Monochrome
- `WhiteSur-grey` - Grey tone
- `WhiteSur-purple` - Purple accent

```bash
# Install specific variant
./install.sh -c purple  # or mono, grey
```

## Switching Icon Themes

### Via GNOME Tweaks
1. Open **GNOME Tweaks** → **Appearance**
2. **Icons** → Select **WhiteSur** variant

### Via Command Line
```bash
gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur'
gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur-mono'
gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur-grey'
```

## Alternative Icon Packs

### McMojave Circle
```bash
git clone https://github.com/vinceliuice/McMojave-circle-icon-theme.git
cd McMojave-circle-icon-theme
./install.sh
```

### Tela Icons
```bash
git clone https://github.com/vinceliuice/Tela-icon-theme.git
cd Tela-icon-theme
./install.sh -c purple  # or blue, green, red, etc.
```

### Colloid Icons
```bash
git clone https://github.com/vinceliuice/Colloid-icon-theme.git
cd Colloid-icon-theme
./install.sh
```

### Papirus (Popular Alternative)
```bash
sudo add-apt-repository ppa:papirus/papirus
sudo apt update
sudo apt install papirus-icon-theme
```

## Customizing Icons

### Per-Application Icons
1. Find app's `.desktop` file:
   ```bash
   ls /usr/share/applications/ | grep firefox
   ```

2. Copy to local:
   ```bash
   cp /usr/share/applications/firefox.desktop ~/.local/share/applications/
   ```

3. Edit `Icon=` line:
   ```ini
   Icon=/home/user/.local/share/icons/custom/firefox.png
   ```

### Creating Custom Icon Theme
```
MyIcons/
├── index.theme
├── scalable/
│   ├── apps/
│   ├── places/
│   ├── devices/
│   └── ...
├── 48x48/
├── 64x64/
├── 128x128/
└── 256x256/
```

`index.theme` example:
```ini
[Icon Theme]
Name=MyIcons
Comment=Custom icon theme
Inherits=WhiteSur,Adwaita,hicolor
Directories=scalable/apps,scalable/places,48x48/apps
```

### Icon Sizes for Dock
Plank works best with scalable SVG icons. For raster:
- 48x48 (default dock size)
- 64x64 (zoomed)
- 128x128 (high DPI)

## Dock Icon Customization

### Plank Launchers
Icons in `~/.config/plank/dock1/launchers/` reference `.desktop` files:
```ini
[PlankItemsDockItemPreferences]
Launcher=file:///usr/share/applications/org.gnome.Nautilus.desktop
```

The icon comes from the `.desktop` file's `Icon=` field.

### Custom Dock Icons
1. Create custom `.desktop` in `~/.local/share/applications/`
2. Set custom `Icon=` path
3. Add to Plank via drag-and-drop or `.dockitem`

Example custom terminal icon:
```ini
# ~/.local/share/applications/custom-terminal.desktop
[Desktop Entry]
Name=Terminal
Comment=Custom Terminal
Exec=gnome-terminal
Icon=/home/user/.local/share/icons/terminal-custom.svg
Terminal=false
Type=Application
Categories=System;TerminalEmulator;
```

## Icon Theme Compatibility

| Icon Theme | WhiteSur GTK | Orchis GTK | Colloid GTK | Adwaita |
|------------|--------------|------------|-------------|---------|
| WhiteSur | ✓ Perfect | ✓ Good | ✓ Good | ✓ Good |
| McMojave | ✓ Good | ✓ Good | ✓ Good | ✓ Good |
| Tela | ✓ Good | ✓ Perfect | ✓ Good | ✓ Good |
| Colloid | ✓ Good | ✓ Good | ✓ Perfect | ✓ Good |
| Papirus | ✓ Good | ✓ Good | ✓ Good | ✓ Good |

## High DPI / Fractional Scaling

For 4K/high-DPI displays:
```bash
# Enable fractional scaling (experimental)
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"

# Set scaling factor
gsettings set org.gnome.desktop.interface scaling-factor 2
gsettings set org.gnome.desktop.interface text-scaling-factor 1.0
```

Icons should be scalable (SVG) for best results at any scale.

## Troubleshooting Icons

### Icons Not Updating
```bash
# Refresh icon cache
gtk-update-icon-cache -f ~/.icons/WhiteSur
gtk-update-icon-cache -f /usr/share/icons/WhiteSur

# Restart GNOME Shell
# Alt+F2 → r (X11) or logout/login (Wayland)
```

### Missing Icons in Dock
- Ensure `.desktop` file has valid `Icon=` entry
- Icon file exists at specified path
- Icon theme has the icon in scalable/apps/ or appropriate size

### Inconsistent Icons (Some Apps Different)
- App uses hardcoded icon path
- App is Snap/Flatpak with bundled icons
- Fix: Copy icon to theme, or create override `.desktop`

### Flatpak/Snap Icons
```bash
# Flatpak icons location
/var/lib/flatpak/exports/share/icons/hicolor/

# Snap icons location
/var/lib/snapd/desktop/applications/

# Override by copying to ~/.local/share/icons/hicolor/
```

## Icon Theme Structure Reference

```
WhiteSur/
├── index.theme
├── scalable/
│   ├── apps/           # Application icons
│   ├── categories/     # Menu categories
│   ├── devices/        # Hardware icons
│   ├── emblems/        # Overlay icons
│   ├── mimetypes/      # File type icons
│   ├── places/         # Folder/location icons
│   └── status/         # System status icons
├── 16x16/, 24x24/, 32x32/, 48x48/, 64x64/, 128x128/, 256x256/
│   └── (same categories)
└── symbolic/           # Symbolic (monochrome) icons
```

## Performance Notes

- **SVG icons** scale perfectly, minimal size
- **Raster icons** (PNG) needed for some legacy apps
- Large icon themes (10000+ icons) may slow initial load
- WhiteSur is optimized (~5000 icons)

Use `snowos-performance performance` to disable icon animations if needed.