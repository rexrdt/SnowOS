# VM Testing Guide

## Quick Test with QEMU (Linux)

```bash
# Install QEMU
sudo apt install qemu-system-x86 qemu-utils

# Create test disk
qemu-img create -f qcow2 snowos-test.qcow2 30G

# Boot ISO
qemu-system-x86_64 \
  -enable-kvm \
  -m 4G \
  -smp 2 \
  -cdrom build/output/SnowOS-24.04-amd64.iso \
  -drive file=snowos-test.qcow2,format=qcow2 \
  -display gtk,gl=on \
  -device virtio-vga-gl
```

## VirtualBox Testing

### Setup
1. Install VirtualBox and Extension Pack
2. Create VM:
   - Type: Linux, Version: Ubuntu (64-bit)
   - Memory: 4096 MB
   - CPU: 2 cores
   - Enable PAE/NX, Nested VT-x/AMD-V

### Display Settings
- Video Memory: 128 MB
- Graphics Controller: VMSVGA
- Enable 3D Acceleration: ✓

### Network
- Adapter 1: NAT (for internet)
- Adapter 2: Host-only (for SSH access)

### Installation
1. Attach SnowOS ISO to optical drive
2. Start VM and install
3. After install, eject ISO and reboot

### Guest Additions
```bash
# In VM terminal
sudo apt update
sudo apt install -y build-essential dkms linux-headers-$(uname -r)
# Devices → Insert Guest Additions CD Image
sudo ./VBoxLinuxAdditions.run
sudo reboot
```

## VMware Workstation/Player

### VM Settings
- Compatibility: Workstation 17.x
- Guest OS: Linux → Ubuntu 64-bit
- Memory: 4 GB
- Processors: 2
- Network: NAT
- Display: 3D Acceleration ON, 2 GB VRAM

### VMware Tools
```bash
# In VM
sudo apt update
sudo apt install -y open-vm-tools open-vm-tools-desktop
sudo reboot
```

## GNOME Boxes (Simple)

```bash
sudo apt install gnome-boxes
# Open Boxes → New → Select SnowOS ISO
```

## Automated Testing Script

Create `test-vm.sh`:

```bash
#!/bin/bash
# Automated VM test for SnowOS

ISO="$1"
if [[ -z "$ISO" ]]; then
    echo "Usage: $0 <path-to-iso>"
    exit 1
fi

DISK="snowos-autotest.qcow2"
qemu-img create -f qcow2 "$DISK" 20G

# Boot and run basic tests
qemu-system-x86_64 \
  -enable-kvm \
  -m 3G \
  -smp 2 \
  -cdrom "$ISO" \
  -drive file="$DISK",format=qcow2 \
  -display none \
  -serial stdio \
  -device virtio-net-pci,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -boot d \
  -no-reboot &

QEMU_PID=$!

# Wait for SSH
for i in {1..120}; do
    if ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -p 2222 user@localhost "echo ready" 2>/dev/null; then
        break
    fi
    sleep 5
done

# Run tests via SSH
ssh -p 2222 user@localhost << 'EOF'
# Test basic functionality
gnome-shell --version
plank --version
gsettings get org.gnome.desktop.interface gtk-theme
gsettings get org.gnome.desktop.interface icon-theme
ls ~/.config/plank/dock1/launchers/
systemctl --user is-active plank
EOF

# Cleanup
kill $QEMU_PID
rm "$DISK"
```

## CI/CD Testing (GitHub Actions)

```yaml
# .github/workflows/test.yml
name: Test SnowOS ISO

on:
  push:
    tags: ['v*']

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build ISO
        run: |
          sudo apt update
          sudo apt install -y xorriso squashfs-tools genisoimage rsync
          ./build.sh
      
      - name: Test in VM
        run: |
          # Quick smoke test
          qemu-system-x86_64 \
            -enable-kvm \
            -m 2G \
            -smp 1 \
            -cdrom build/output/SnowOS-*.iso \
            -display none \
            -serial stdio \
            -boot d \
            -snapshot \
            -monitor none \
            -no-reboot &
          
          sleep 60
          kill %1
```

## Test Checklist

### Boot & Install
- [ ] ISO boots to GRUB menu
- [ ] Live desktop loads (Wayland)
- [ ] Installer launches
- [ ] Installation completes without errors
- [ ] System boots after install

### Desktop Environment
- [ ] GNOME Shell loads
- [ ] Top panel visible with correct elements
- [ ] Plank dock appears at bottom
- [ ] Wallpaper applied
- [ ] Theme applied (WhiteSur-Dark)
- [ ] Icons applied (WhiteSur)

### Extensions
- [ ] Blur My Shell: Panel blurred
- [ ] Blur My Shell: Overview blurred
- [ ] Search Light: Super+Space opens search
- [ ] Magic Lamp: Window minimize animation
- [ ] Dash to Dock: Hidden (Plank primary)

### Functionality
- [ ] Super key opens app overview
- [ ] Super+Return opens terminal
- [ ] Dock launches applications
- [ ] Right-click dock → Preferences works
- [ ] Settings app opens
- [ ] File manager opens
- [ ] Terminal opens with correct theme

### Performance Modes
- [ ] `snowos-performance performance` disables effects
- [ ] `snowos-performance balanced` restores defaults
- [ ] `snowos-performance visual` enhances effects

### Hardware
- [ ] Network works (WiFi/Ethernet)
- [ ] Audio works
- [ ] GPU acceleration (glxinfo | grep OpenGL)
- [ ] USB devices detected
- [ ] Bluetooth works (if hardware present)

### Persistence
- [ ] Settings persist after reboot
- [ ] Extensions stay enabled
- [ ] Dock items persist
- [ ] Theme persists

## Performance Benchmarks

Run in VM to verify performance:

```bash
# GPU benchmark
glmark2 --run-forever=false

# CPU benchmark
sysbench cpu --cpu-max-prime=20000 run

# Memory benchmark
sysbench memory --memory-block-size=1M --memory-total-size=10G run

# Disk benchmark
fio --name=randread --ioengine=libaio --iodepth=16 --rw=randread --bs=4k --direct=1 --size=512M --numjobs=4 --runtime=30 --group_reporting
```

## Debugging VM Issues

### No Display
- Check 3D acceleration enabled
- Try `-display gtk` instead of `-display none`
- Verify `virtio-vga-gl` device

### Slow Performance
- Enable KVM: `-enable-kvm`
- Use virtio drivers for disk/network
- Allocate more RAM/CPU

### Network Not Working
- Check virtio-net-pci device
- Verify user-mode networking: `-netdev user,id=net0`
- For port forwarding: `hostfwd=tcp::2222-:22`

### Installation Hangs
- Increase VM memory to 4GB+
- Use `-snapshot` for safe testing
- Check console output with `-serial stdio`