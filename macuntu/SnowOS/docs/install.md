# SnowOS Installation Guide

## Installation Methods

### Method 1: Custom ISO (Recommended for New Installs)

1. **Download SnowOS ISO** from releases or build your own
2. **Create bootable USB**:
   ```bash
   # Linux/macOS
   sudo dd if=SnowOS-24.04-amd64.iso of=/dev/sdX bs=4M status=progress
   sync
   
   # Windows: Use Rufus, BalenaEtcher, or Ventoy
   ```
3. **Boot from USB** and follow Ubuntu installer
4. **Select "SnowOS" desktop** when prompted (if multiple options)
5. **Complete installation** and reboot

### Method 2: Transform Existing Ubuntu (Recommended for Current Users)

Run the setup script on your existing Ubuntu installation:

```bash
# Clone or download SnowOS
git clone https://github.com/yourusername/SnowOS.git
cd SnowOS

# Run setup (requires sudo for package installation)
./setup-desktop.sh
```

**Requirements:**
- Ubuntu 22.04 LTS or 24.04 LTS
- GNOME desktop (default Ubuntu flavor)
- Internet connection
- sudo privileges

**What it does:**
- Installs required packages
- Downloads and applies WhiteSur theme & icons
- Installs GNOME extensions (Blur My Shell, Search Light, Magic Lamp)
- Configures Plank dock
- Sets up keybindings (Super for launcher, Super+Space for search)
- Creates performance mode switcher
- Applies wallpapers
- Creates welcome screen

**After running:** Log out and back in (or reboot)

## Post-Installation

### First Boot

On first login, you'll see the **SnowOS Welcome** screen with:
- Quick start guide
- Keyboard shortcuts
- Performance mode instructions
- Links to settings

### Initial Configuration

1. **Open Settings** (from dock or Super key → "Settings")
2. **Appearance** → Choose Light/Dark/Auto theme
3. **Extensions** → Open Extension Manager to tweak extensions
4. **Tweaks** → Open GNOME Tweaks for advanced options

### Dock Customization

Right-click Plank dock → Preferences:
- Position: Bottom/Left/Right
- Hide mode: Intelligent/Auto/Window Dodge
- Icon size & zoom
- Theme: Transparent/Matte

### Adding Dock Items

Drag applications from app launcher to dock, or:
Right-click running app in dock → "Keep in Dock"

## Dual Boot with Windows

1. **Install Windows first** (if not already installed)
2. **Resize Windows partition** from Windows Disk Management
3. **Boot SnowOS USB** and install alongside Windows
4. **GRUB** will detect Windows automatically

**Important:** Disable Windows Fast Startup and BitLocker before installing.

## Virtual Machine Installation

### VirtualBox
1. Create new VM → Linux → Ubuntu (64-bit)
2. Allocate 4GB+ RAM, 2+ CPU cores
3. Enable 3D Acceleration (Display settings)
4. Increase Video Memory to 128MB
5. Attach SnowOS ISO
6. Install normally

### VMware
Similar to VirtualBox, ensure 3D acceleration enabled.

### QEMU/KVM (Linux Host)
```bash
virt-install \
  --name snowos \
  --memory 4096 \
  --vcpus 2 \
  --cdrom SnowOS-24.04-amd64.iso \
  --disk size=30 \
  --os-variant ubuntu24.04 \
  --graphics spice \
  --video virtio
```

## Hardware Requirements

### Minimum
- 2 GB RAM
- 2 CPU cores
- 25 GB storage
- GPU with OpenGL 3.3+ support

### Recommended
- 8 GB RAM
- 4+ CPU cores
- 50 GB SSD
- Dedicated GPU or modern integrated graphics

## NVIDIA GPU Setup

If you have NVIDIA graphics:

1. During Ubuntu installer: Check "Install third-party software"
2. Or after install:
   ```bash
   sudo ubuntu-drivers autoinstall
   sudo reboot
   ```

3. For Wayland + NVIDIA (Ubuntu 24.04+):
   ```bash
   sudo nvidia-settings --assign CurrentMetaMode="nvidia-auto-select +0+0 {ForceFullCompositionPipeline=On}"
   ```

## Troubleshooting Installation

### "Unable to locate package" errors
```bash
sudo apt update
sudo apt install -f
```

### Theme not applying
- Log out and back in
- Check Extensions app → User Themes is enabled
- Run: `gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark'`

### Extensions not working
- Check GNOME version compatibility
- Disable/enable in Extension Manager
- Check for updates: `gnome-extensions list --enabled`

### Plank not starting
```bash
plank --preferences  # Check if it runs
# Add to startup applications if needed
```

### Black screen on boot
- Try nomodeset kernel parameter
- Check GPU drivers
- Try X11 session instead of Wayland (gear icon at login)

## Uninstalling SnowOS

To restore original Ubuntu GNOME:

```bash
cd SnowOS
./restore-desktop.sh
```

This will:
- Restore backed-up configurations
- Disable SnowOS extensions
- Reset GNOME settings to defaults
- Remove Plank configuration
- Optionally remove installed packages