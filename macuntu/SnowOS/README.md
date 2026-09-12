# SnowOS

A custom Ubuntu-based Linux distribution with a macOS-inspired desktop experience.

## Overview

SnowOS is a polished desktop operating system built on Ubuntu Linux, featuring a modern macOS-inspired look and feel using open-source software, themes, and extensions.

## Features

- **Base**: Ubuntu Linux (kernel, package management, drivers, networking)
- **Desktop**: GNOME Shell with extensive customization
- **Dock**: Plank with macOS-style behavior
- **Theme**: WhiteSur GTK theme (open-source macOS-inspired)
- **Icons**: WhiteSur icon theme
- **Extensions**: Blur My Shell, Dash to Dock, User Themes, Search Light
- **Animations**: Magic Lamp-style minimize effect
- **Search**: Spotlight-inspired global search (Super+Space)
- **Launcher**: Application grid launcher (Super key)
- **Modes**: Performance / Balanced / Visual modes
- **Dark/Light**: Full theme switching support

## Quick Start

### Building the ISO

```bash
cd SnowOS
./build.sh
```

### Installing on Existing Ubuntu

```bash
cd SnowOS
./setup-desktop.sh
```

### Restoring Original Ubuntu GNOME

```bash
cd SnowOS
./restore-desktop.sh
```

## Requirements

- Ubuntu 22.04 LTS or 24.04 LTS
- GNOME 42+ (Ubuntu 22.04) or GNOME 46+ (Ubuntu 24.04)
- Internet connection for package downloads
- sudo privileges

## Directory Structure

```
SnowOS/
├── build/              # Build scripts and ISO generation
├── config/             # Configuration files
├── themes/             # GTK and Shell themes
├── icons/              # Icon themes
├── extensions/         # GNOME Shell extensions
├── scripts/            # Utility scripts
├── packages/           # Package lists and management
├── installer/          # Custom installer components
├── branding/           # SnowOS branding assets
├── wallpapers/         # Default wallpapers
├── docs/               # Documentation
├── build.sh            # Main build script
├── test.sh             # Test/validation script
├── setup-desktop.sh    # Desktop configuration script
├── restore-desktop.sh  # Restore original Ubuntu GNOME
└── README.md
```

## Documentation

- [Building the ISO](docs/build.md)
- [Installation Guide](docs/install.md)
- [VM Testing](docs/vm-testing.md)
- [Hardware Installation](docs/hardware-install.md)
- [Theme Customization](docs/themes.md)
- [Icon Customization](docs/icons.md)
- [Disabling Effects](docs/performance.md)
- [Restoring Ubuntu](docs/restore.md)
- [Troubleshooting](docs/troubleshooting.md)

## License

This project uses open-source components. See individual component licenses.
SnowOS branding and scripts: MIT License