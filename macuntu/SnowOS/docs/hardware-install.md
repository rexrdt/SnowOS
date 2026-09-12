# Hardware Installation Guide

## Pre-Installation Checklist

### Backup Data
- **Critical:** Backup all important data before installation
- Use external drive, cloud storage, or separate partition
- Verify backups are readable

### System Requirements
- **CPU:** x86_64 (Intel/AMD 64-bit)
- **RAM:** 4 GB minimum, 8 GB+ recommended
- **Storage:** 30 GB minimum, 50 GB+ SSD recommended
- **GPU:** OpenGL 3.3+ support (most GPUs from 2010+)
- **Firmware:** UEFI preferred, Legacy BIOS supported

### Prepare Installation Media
```bash
# Download SnowOS ISO
# Verify checksum
sha256sum SnowOS-24.04-amd64.iso

# Create bootable USB (Linux/macOS)
sudo dd if=SnowOS-24.04-amd64.iso of=/dev/sdX bs=4M status=progress && sync

# Windows: Use Rufus (DD mode) or Ventoy
```

## BIOS/UEFI Configuration

### Enter BIOS/UEFI
- Restart and press: F2, F12, Del, Esc, or F10 (varies by manufacturer)

### Required Settings
| Setting | Value |
|---------|-------|
| Boot Mode | UEFI (preferred) or Legacy |
| Secure Boot | Disabled (or Enrolled with Ubuntu keys) |
| SATA Mode | AHCI |
| Fast Boot | Disabled |
| CSM (Compatibility Support) | Disabled for UEFI |

### NVIDIA Optimus / Hybrid Graphics
- Set to "Discrete Graphics" or "Switchable" in BIOS
- If not available, configure in OS after install

### Disable Windows Features (if dual-booting)
In Windows before installing:
1. Disable Fast Startup: Control Panel → Power Options → Choose what power buttons do
2. Disable BitLocker: Settings → Privacy & Security → BitLocker
3. Run `powercfg /h off` in Admin PowerShell (disables hibernation)

## Installation Process

### Boot from USB
1. Insert USB drive
2. Restart and enter boot menu (F12, F8, etc.)
3. Select USB drive (UEFI: USB Name)

### GRUB Menu
- Select "Install SnowOS" or "Try or Install Ubuntu"
- Press `e` to edit boot parameters if needed:
  - `nomodeset` - for GPU issues
  - `nvme_core.default_ps_max_latency_us=0` - for NVMe power issues

### Language & Keyboard
- Select language
- Choose keyboard layout
- Test special characters

### Network
- Connect to WiFi if needed
- Ethernet works automatically
- "Download updates" and "Install third-party software" → **Enable both**

### Installation Type

#### Option A: Erase Disk (Clean Install)
- Select "Erase disk and install SnowOS"
- **Advanced:** Choose LVM + Encryption for full disk encryption

#### Option B: Manual Partitioning (Advanced)
```
EFI System Partition:    512 MB  fat32  /boot/efi  (boot, esp)
Root Partition:          30+ GB  ext4   /          
Swap Partition:          =RAM    swap   (optional with swapfile)
Home Partition:          Rest    ext4   /home      (optional)
```

#### Option C: Dual Boot with Windows
- Select "Install alongside Windows Boot Manager"
- Allocate space for SnowOS (50 GB minimum)
- **Do not** delete Windows partitions

### User Setup
- Your name
- Computer name (hostname)
- Username (lowercase, no spaces)
- Strong password
- **Require password: Yes**
- **Login automatically: No** (recommended)

### Installation
- Click "Install Now"
- Confirm partition changes
- Wait for installation (5-15 minutes)

### Post-Install
- Remove USB when prompted
- Reboot

## Post-Install Hardware Configuration

### NVIDIA Drivers
```bash
# Check available drivers
ubuntu-drivers devices

# Install recommended
sudo ubuntu-drivers autoinstall

# Or specific version
sudo apt install nvidia-driver-550

# Reboot
sudo reboot
```

### Verify GPU
```bash
# NVIDIA
nvidia-smi

# AMD/Intel
glxinfo | grep "OpenGL renderer"
vulkaninfo | grep "deviceName"
```

### WiFi Issues
```bash
# Check hardware
lspci -nn | grep -i network
rfkill list

# Install firmware if needed
sudo apt install linux-firmware

# Realtek/Broadcom specific
sudo apt install firmware-realtek  # or firmware-b43-installer
```

### Audio Issues
```bash
# Restart PipeWire
systemctl --user restart pipewire pipewire-pulse wireplumber

# Check devices
wpctl status
pavucontrol  # GUI mixer
```

### Touchpad/Trackpad
```bash
# Libinput gestures (for MacBook-like gestures)
sudo apt install libinput-gestures
libinput-gestures-setup autostart
```

### Battery Optimization (Laptops)
```bash
# Install TLP
sudo apt install tlp tlp-rdw
sudo tlp start

# Or auto-cpufreq
git clone https://github.com/AdnanHodzic/auto-cpufreq
cd auto-cpufreq && sudo ./auto-cpufreq-installer
sudo auto-cpufreq --install
```

### Sensor Monitoring
```bash
sudo apt install lm-sensors hddtemp
sudo sensors-detect
sensors
```

## Hardware-Specific Guides

### MacBook (Intel)
- Use `macbook12-spi-driver` for keyboard/trackpad
- Install `mbpfan` for fan control
- Configure `pommed` for keyboard backlight

### MacBook (Apple Silicon)
- **Not supported** - Use Asahi Linux instead

### Surface Devices
- Kernel: `linux-surface` for better support
- `iptsd` for touchscreen
- `libwacom` for pen

### Lenovo ThinkPad
- `thinkfan` for fan control
- `tp-smapi-dkms` for battery thresholds
- `acpi_call-dkms` for battery conservation mode

### Dell XPS
- `dell-smm-hwmon` for fan/temp
- `intel-undervolt` for CPU undervolting

### Framework Laptop
- Works out of the box
- `fwupd` for firmware updates

### AMD Ryzen Laptops
- `ryzenadj` for power limits
- `auto-cpufreq` for governor tuning

## Troubleshooting

### Black Screen After Install
1. Boot with `nomodeset` kernel parameter
2. Install GPU drivers
3. Remove `nomodeset`

### System Won't Boot
- Check boot order in BIOS
- Verify EFI partition exists and is flagged `boot, esp`
- Use Boot-Repair: `sudo add-apt-repository ppa:yannubuntu/boot-repair && sudo apt update && sudo apt install -y boot-repair && boot-repair`

### WiFi Not Working
- Check `rfkill list` - unblock if needed
- Install missing firmware
- Try LTS kernel: `sudo apt install linux-generic-hwe-24.04`

### Audio Not Working
- Run `wpctl status` check PipeWire
- Install `pavucontrol` and check profile
- Try `systemctl --user restart pipewire`

### Touchpad Not Working
- Check `libinput list-devices`
- Install `xserver-xorg-input-libinput`
- Check kernel: `dmesg | grep -i i2c`

### High Temperature/Fan Noise
- Install `tlp` and `thermald`
- Check `sensors` output
- Clean dust from vents
- Consider undervolting (advanced)

## Verification Checklist

After installation, verify:

- [ ] System boots to login screen
- [ ] Login works
- [ ] Desktop loads (GNOME Shell)
- [ ] Network connected (WiFi/Ethernet)
- [ ] Audio works (test speakers/headphones)
- [ ] GPU acceleration working (`glxinfo`)
- [ ] Touchpad/mouse works
- [ ] Keyboard works (all keys)
- [ ] Screen brightness controls
- [ ] Volume/brightness keys work
- [ ] Suspend/resume works
- [ ] Battery reporting (laptop)
- [ ] Webcam works
- [ ] Bluetooth pairs devices
- [ ] USB ports work
- [ ] External monitor works
- [ ] Dock station works (if applicable)

## Support

If hardware doesn't work:
1. Check `dmesg | grep -i error`
2. Check `journalctl -xe`
3. Search Ubuntu forums for your model
4. File bug at Launchpad
5. Check upstream kernel support