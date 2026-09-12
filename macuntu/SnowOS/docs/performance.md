# Disabling Effects for Performance

SnowOS provides three performance modes to balance visual quality and system resources.

## Performance Modes

### Quick Switch
```bash
# Maximum performance (minimal effects)
snowos-performance performance

# Balanced (default)
snowos-performance balanced

# Maximum visual effects
snowos-performance visual
```

### What Each Mode Changes

| Feature | Performance | Balanced | Visual |
|---------|-------------|----------|--------|
| Animations | Disabled | Enabled | Enhanced |
| Panel Blur | Off | On | On |
| Overview Blur | Off | On | On |
| App Folder Blur | Off | On | On |
| Dialog Blur | Off | On | On |
| Hot Corners | Off | On | On |
| Dock Zoom | Off | On | Enhanced (200%) |
| Window Shadows | Minimal | Normal | Enhanced |

## Manual Configuration

### Disable All Animations
```bash
gsettings set org.gnome.desktop.interface enable-animations false
```

### Disable Blur My Shell Effects
```bash
gsettings set org.gnome.shell.extensions.blur-my-shell panel-blur false
gsettings set org.gnome.shell.extensions.blur-my-shell overview-blur false
gsettings set org.gnome.shell.extensions.blur-my-shell appfolder-blur false
gsettings set org.gnome.shell.extensions.blur-my-shell dialog-blur false
```

### Disable Dock Magnification
```bash
gsettings set org.gnome.shell.extensions.dash-to-dock zoom-enabled false
# Or for Plank (edit settings file)
sed -i 's/ZoomEnabled=true/ZoomEnabled=false/' ~/.config/plank/dock1/settings
```

### Disable Hot Corners
```bash
gsettings set org.gnome.desktop.interface enable-hot-corners false
```

### Reduce Transparency
```bash
# Panel opacity (0-255, 255=opaque)
gsettings set org.gnome.shell.extensions.blur-my-shell panel-opacity 255
gsettings set org.gnome.shell.extensions.blur-my-shell overview-opacity 255
```

### Disable Magic Lamp Animation
```bash
gnome-extensions disable magic-lamp@laxatives.github.io
# Or
gsettings set org.gnome.shell.extensions.magic-lamp animation-duration 0
```

### Disable Search Light
```bash
gnome-extensions disable search-light@s3r3n1t7.github.com
```

## Low-End Hardware Optimizations

### Startup Applications
Disable unnecessary autostart apps:
```bash
# List autostart apps
ls /etc/xdg/autostart/
ls ~/.config/autostart/

# Disable specific (create override)
mkdir -p ~/.config/autostart
cp /etc/xdg/autostart/some-app.desktop ~/.config/autostart/
echo "Hidden=true" >> ~/.config/autostart/some-app.desktop
```

### Systemd Services
```bash
# Disable unused services
sudo systemctl disable bluetooth.service  # If no Bluetooth
sudo systemctl disable cups.service       # If no printer
sudo systemctl disable avahi-daemon.service  # If no local network discovery
```

### Swap Configuration
```bash
# Check current swap
swapon --show

# Adjust swappiness (lower = less swap usage)
echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-swappiness.conf
sudo sysctl --system
```

### CPU Governor
```bash
# Install cpufrequtils
sudo apt install cpufrequtils

# Set to powersave
echo 'GOVERNOR="powersave"' | sudo tee /etc/default/cpufrequtils
sudo systemctl restart cpufrequtils
```

### Reduce Journal Size
```bash
sudo mkdir -p /etc/systemd/journald.conf.d
echo -e '[Journal]\nSystemMaxUse=100M' | sudo tee /etc/systemd/journald.conf.d/00-size.conf
sudo systemctl restart systemd-journald
```

## Per-Application Performance

### Web Browser (Firefox/Chrome)
- Disable hardware acceleration if GPU issues
- Reduce content process limit
- Use uBlock Origin to block heavy scripts

### Terminal
```bash
# Disable transparency for better performance
# In GNOME Terminal preferences → Profile → Colors → uncheck "Use transparency"
```

### VS Code / Electron Apps
```bash
# Disable GPU acceleration
code --disable-gpu
# Or add to .desktop: Exec=code --disable-gpu %F
```

## Monitoring Performance

### System Monitor
```bash
# Install
sudo apt install gnome-system-monitor

# Or terminal
htop
btop
```

### GPU Usage
```bash
# Intel/AMD
intel_gpu_top
radeontop

# NVIDIA
nvidia-smi -l 1
```

### Frame Rate
```bash
# Show FPS overlay (GNOME)
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer', 'show-fps']"

# Or use gamescope/vkcube for Vulkan
```

## Creating Custom Performance Profiles

### Profile Script Template
```bash
#!/bin/bash
# ~/.local/bin/my-performance-profile

MODE="$1"

apply_settings() {
    gsettings set org.gnome.desktop.interface enable-animations "$ANIMATIONS"
    gsettings set org.gnome.shell.extensions.blur-my-shell panel-blur "$BLUR"
    gsettings set org.gnome.shell.extensions.blur-my-shell overview-blur "$BLUR"
    gsettings set org.gnome.shell.extensions.dash-to-dock zoom-enabled "$ZOOM"
    gsettings set org.gnome.desktop.interface enable-hot-corners "$HOT_CORNERS"
}

case "$MODE" in
    battery)
        ANIMATIONS=false; BLUR=false; ZOOM=false; HOT_CORNERS=false
        # Additional: reduce refresh rate, dim screen
        ;;
    performance)
        ANIMATIONS=false; BLUR=false; ZOOM=false; HOT_CORNERS=false
        ;;
    balanced)
        ANIMATIONS=true; BLUR=true; ZOOM=true; HOT_CORNERS=true
        ;;
    presentation)
        ANIMATIONS=true; BLUR=true; ZOOM=true; HOT_CORNERS=false
        # Disable notifications
        gsettings set org.gnome.desktop.notifications show-banners false
        ;;
esac

apply_settings
notify-send "Performance Mode" "Switched to $MODE"
```

## Benchmarking

### Before/After Comparison
```bash
# Test animation smoothness
# 1. Open multiple windows
# 2. Switch workspaces rapidly
# 3. Open/close overview (Super key)
# 4. Minimize/maximize windows

# Measure
echo "Testing animation frame times..."
# Use gnome-shell's built-in profiler:
# Alt+F2 → lg → Performance tab
```

### Automated Test
```bash
#!/bin/bash
# benchmark-effects.sh

for mode in performance balanced visual; do
    snowos-performance "$mode"
    sleep 2
    
    # Time overview animation
    start=$(date +%s%N)
    gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval 'Main.overview.show();' >/dev/null
    sleep 1
    end=$(date +%s%N)
    
    echo "$mode: $(( (end-start)/1000000 ))ms"
done
```

## Troubleshooting Performance

### High CPU Usage
```bash
# Check top processes
top -bn1 | head -20

# Common culprits:
# - gnome-shell (extensions)
# - tracker-miner (file indexing)
# - packagekitd (updates)
```

### High Memory Usage
```bash
# Check memory
free -h

# Clear caches
sync && echo 3 | sudo tee /proc/sys/vm/drop_caches
```

### High GPU Usage
```bash
# Check what's using GPU
sudo intel_gpu_top  # Intel
sudo radeontop      # AMD
nvidia-smi          # NVIDIA
```

### Laggy Animations
1. Disable blur: `snowos-performance performance`
2. Check refresh rate: `xrandr` or Settings → Displays
3. Update GPU drivers
4. Check for swap thrashing: `iotop`

## Recommended Settings by Hardware

### Very Old Hardware (< 4GB RAM, No GPU)
```bash
snowos-performance performance
# Plus:
gsettings set org.gnome.desktop.interface enable-animations false
gsettings set org.gnome.shell.extensions.dash-to-dock zoom-enabled false
# Disable tracker
gsettings set org.freedesktop.Tracker.Miner.Files crawling-interval -2
gsettings set org.freedesktop.Tracker.Miner.Files enable-monitors false
```

### Older Hardware (4-8GB RAM, Integrated GPU)
```bash
snowos-performance balanced
# Reduce blur intensity
gsettings set org.gnome.shell.extensions.blur-my-shell panel-opacity 200
```

### Modern Hardware (8GB+ RAM, Dedicated GPU)
```bash
snowos-performance visual
# All effects enabled
```

### Laptop on Battery
```bash
# Auto-switch on battery
# Create udev rule or systemd service to run:
# snowos-performance battery
```