# Theme Customization

## Default Theme: WhiteSur

SnowOS uses the **WhiteSur GTK Theme** by vinceliuice, an open-source macOS-inspired theme.

### Theme Variants
- `WhiteSur` - Light theme
- `WhiteSur-Dark` - Dark theme (default)
- `WhiteSur-Light` - Light variant
- `WhiteSur-auto` - Follows system preference

### Accent Colors
```bash
# Available accents (installed by setup script)
cd /tmp/WhiteSur-gtk-theme
./install.sh -c Dark -c Light -l -N mojave -t all
```
Accents: `mojave`, `catalina`, `bigsur`, `monterey`, `ventura`, `sonoma`

### Manual Theme Installation
```bash
# Download
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git
cd WhiteSur-gtk-theme

# Install for user
./install.sh -c Dark -c Light

# Install system-wide (requires sudo)
sudo ./install.sh -c Dark -c Light

# Uninstall
./install.sh -r
```

## Switching Themes

### Via GNOME Tweaks (GUI)
1. Open **GNOME Tweaks** (from dock or Super → "Tweaks")
2. **Appearance** → **Themes**
3. **Applications** → Select WhiteSur variant
4. **Shell** → Select WhiteSur variant (requires User Themes extension)

### Via Command Line
```bash
# GTK Theme
gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark'

# Shell Theme (requires User Themes extension)
gsettings set org.gnome.shell.extensions.user-theme name 'WhiteSur-Dark'

# Icon Theme
gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur'

# Font
gsettings set org.gnome.desktop.interface font-name 'Inter 11'
```

### Dark/Light Mode Toggle
```bash
# Dark mode
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Light mode
gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'

# Auto (follows system time)
gsettings set org.gnome.desktop.interface color-scheme 'default'
```

### Quick Toggle Script
```bash
# Save as ~/.local/bin/toggle-theme
#!/bin/bash
CURRENT=$(gsettings get org.gnome.desktop.interface color-scheme)
if [[ "$CURRENT" == *"dark"* ]]; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
    gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Light'
else
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark'
fi
```

## Customizing WhiteSur

### Theme Options
The WhiteSur installer supports many options:

```bash
./install.sh --help
```

Key options:
- `-c, --color VARIANT` - Dark/Light
- `-l, --libadwaita` - Theme libadwaita apps
- `-N, --normal` - Normal window buttons (vs macOS style)
- `-M, --monterey` - Monterey style
- `-t, --theme ALL` - Theme all components
- `--tweaks` - Additional tweaks (darker, rim, etc.)

### Custom Colors
Create `~/.config/gtk-4.0/gtk.css`:
```css
@define-color accent_bg_color #7aa2f7;
@define-color accent_fg_color #1a1a2e;
@define-color success_color #98d080;
@define-color warning_color #ffd700;
@define-color error_color #ff6b6b;
```

### Window Button Styles
```bash
# macOS style (left side)
gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'

# Windows style (right side)
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'

# Minimal (close only)
gsettings set org.gnome.desktop.wm.preferences button-layout 'close:'
```

## Alternative Themes

### Other macOS-Inspired Themes
```bash
# Orchis (Material Design, macOS-like)
git clone https://github.com/vinceliuice/Orchis-theme.git
cd Orchis-theme && ./install.sh

# Colloid (Round, modern)
git clone https://github.com/vinceliuice/Colloid-gtk-theme.git
cd Colloid-gtk-theme && ./install.sh

# Nordic (Nord color palette)
git clone https://github.com/EliverLara/Nordic.git
cd Nordic && ./install.sh
```

### Theme Compatibility
| Theme | GTK3 | GTK4 | Libadwaita | Shell | Status |
|-------|------|------|------------|-------|--------|
| WhiteSur | ✓ | ✓ | ✓ | ✓ | Recommended |
| Orchis | ✓ | ✓ | ✓ | ✓ | Good alternative |
| Colloid | ✓ | ✓ | ✓ | ✓ | Good alternative |
| Nordic | ✓ | ✓ | Partial | ✓ | Limited libadwaita |

## Creating Custom Themes

### From Scratch
1. Copy existing theme:
   ```bash
   cp -r /usr/share/themes/WhiteSur-Dark ~/.themes/MyTheme
   ```

2. Edit colors in `gtk.css`:
   ```css
   /* ~/.themes/MyTheme/gtk-3.0/gtk.css */
   @define-color bg_color #1e1e2e;
   @define-color fg_color #cdd6f4;
   @define-color base_color #181825;
   ```

3. Edit shell theme:
   ```bash
   # ~/.themes/MyTheme/gnome-shell/gnome-shell.css
   #panel { background-color: rgba(26, 26, 46, 0.8); }
   ```

4. Select in Tweaks

### Theme Structure
```
MyTheme/
├── gtk-3.0/
│   ├── gtk.css
│   ├── gtk-dark.css
│   └── assets/
├── gtk-4.0/
│   ├── gtk.css
│   └── assets/
├── gnome-shell/
│   ├── gnome-shell.css
│   └── assets/
├── metacity-1/
│   └── metacity-theme-3.xml
├── index.theme
└── README.md
```

## Troubleshooting Themes

### Theme Not Appearing
```bash
# Refresh theme cache
gtk-update-icon-cache -f ~/.themes/MyTheme
gtk-update-icon-cache -f ~/.icons/MyIcons

# Restart GNOME Shell
# X11: Alt+F2 → r → Enter
# Wayland: Log out/in
```

### Libadwaita Apps Not Themed
```bash
# Ensure libadwaita theming is installed
./install.sh -l

# Or manually
mkdir -p ~/.config/gtk-4.0
ln -sf ~/.themes/WhiteSur-Dark/gtk-4.0/gtk.css ~/.config/gtk-4.0/gtk.css
```

### Shell Theme Not Applying
- Enable **User Themes** extension
- Check: `gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com`

### Dark/Light Mismatch
```bash
# Force specific theme regardless of system preference
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark'
```

## Performance Impact

Themes generally have minimal performance impact. However:
- **Transparency/blur** → GPU usage (handled by Blur My Shell extension)
- **Complex animations** → CPU/GPU (controlled by performance modes)
- **High-res assets** → VRAM usage

Use **Performance Mode** if theme effects cause lag:
```bash
snowos-performance performance
```