# Building SnowOS ISO

## Prerequisites

- Ubuntu 22.04 or 24.04 (host system for building)
- Root/sudo access
- At least 20 GB free disk space
- Internet connection

## Install Build Dependencies

```bash
sudo apt update
sudo apt install -y xorriso squashfs-tools genisoimage rsync wget curl gpg
```

## Build Process

### 1. Clone/Navigate to SnowOS

```bash
cd SnowOS
```

### 2. Configure Build (Optional)

```bash
# Set Ubuntu version (default: 24.04)
export UBUNTU_VERSION=24.04

# Set architecture (default: amd64)
export ARCH=amd64
```

### 3. Run Build Script

```bash
./build.sh
```

The script will:
1. Download Ubuntu desktop ISO
2. Extract the ISO and squashfs filesystem
3. Enter chroot and install SnowOS packages/themes/extensions
4. Configure default settings
5. Repack squashfs
6. Generate bootable ISO

### 4. Output

The resulting ISO will be at:
```
build/output/SnowOS-24.04-amd64.iso
```

## Build Time

Typical build time: 15-30 minutes depending on hardware and internet speed.

## Customization

To customize the build, edit:
- `scripts/customize-chroot.sh` - Chroot customization script
- `packages/packages-ubuntu-XX.XX.list` - Package lists
- `config/gnome-settings.ini` - GNOME settings
- `themes/` - Custom themes
- `wallpapers/` - Custom wallpapers

## Verification

Test the ISO in a VM before deploying:

```bash
# Using QEMU
qemu-system-x86_64 -cdrom build/output/SnowOS-24.04-amd64.iso -m 4G -enable-kvm

# Using VirtualBox
# Create new VM -> Use ISO as optical drive
```

## Troubleshooting

### Build Fails at Package Install
- Check internet connectivity
- Verify package names for your Ubuntu version
- Check `packages/packages-ubuntu-XX.XX.list`

### Chroot Errors
- Ensure host system has required dependencies
- Check disk space: `df -h`
- Run with `sudo` if permission errors

### ISO Won't Boot
- Verify ISO integrity: `sha256sum build/output/SnowOS-*.iso`
- Check UEFI/BIOS settings in VM
- Try different virtualization software

## Advanced: Offline Build

For air-gapped environments:

1. Download all packages on connected machine:
   ```bash
   apt download $(cat packages/packages-ubuntu-24.04.list)
   ```

2. Create local repository and serve via HTTP

3. Modify `build.sh` to use local repository

## Signing ISO (Optional)

```bash
# Generate GPG key
gpg --gen-key

# Sign ISO
gpg --detach-sign --armor build/output/SnowOS-24.04-amd64.iso

# Verify
gpg --verify build/output/SnowOS-24.04-amd64.iso.asc
```