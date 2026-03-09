# cmdlets

[![Build](https://github.com/mtdcy/cmdlets/actions/workflows/build-github.yml/badge.svg)](https://github.com/mtdcy/cmdlets/actions/workflows/build-github.yml)
[![License](https://img.shields.io/badge/license-BSD%202--Clause-blue.svg)](LICENSE)

Prebuilt single-file, static or pseudo-static binaries and libraries for Linux and macOS.

## Features

- 📦 **Single-file binaries** - Easy to deploy, no dependency hell
- 🚀 **Cross-platform** - Linux (x86_64, aarch64) and macOS (Intel, Apple Silicon)
- 🔧 **Build system** - Bash script functions for creating static libraries and binaries
- 📚 **Rich library collection** - Common utilities and development libraries

## Quick Start

### Install cmdlets

```shell
# From GitHub
bash -c "$(curl -fsSL https://raw.githubusercontent.com/mtdcy/cmdlets/main/cmdlets.sh)" install

# From China mirror (faster in CN)
bash -c "$(curl -fsSL http://git.mtdcy.top/mtdcy/cmdlets/raw/branch/main/cmdlets.sh)" install
```

### Setup repository (optional)

```shell
export CMDLETS_MAIN_REPO=https://github.com/mtdcy/cmdlets/releases/download
```

### Install packages

```shell
# Install bash 3.2 as default bash
cmdlets.sh install bash@3.2:bash

# Install other packages
cmdlets.sh install zlib curl wget
```

## Supported Architectures

| Platform | Architecture | Status |
|----------|--------------|--------|
| Linux | x86_64 (amd64) | ✅ |
| Linux | aarch64 (ARM64) | ✅ |
| macOS | x86_64 (Intel) | ✅ |
| macOS | arm64 (Apple Silicon) | ✅ |

## Build

### Build on Host

```shell
# Prepare host environment (run once)
make prepare-host

# Build a library
make zlib
```

### Build with Docker

```shell
# Enable ARM emulation on x86 (optional)
sudo apt install binfmt-support qemu-user-static

# Setup environment
make cmdlets.env
source cmdlets.env

# Or manually configure
export DOCKER_IMAGE=ghcr.io/mtdcy/builder:ubuntu-22.04
export DOCKER_PLATFORM=linux/amd64  # linux/amd64 or linux/arm64

# Build
make zlib
```

### Build on Remote Machine

```shell
export REMOTE_HOST=10.10.10.123
make prepare-remote-homebrew    # run once

make zlib
```

### Build Options

```shell
# Use local package cache mirror
export CMDLET_MIRRORS=http://pub.mtdcy.top

# Logging style: tty, plain, or silent
export CMDLET_LOGGING=tty

# Parallel build jobs
export CMDLET_BUILD_NJOBS=2
```

## Downloads

- 🌐 **GitHub Releases**: https://github.com/mtdcy/cmdlets/releases
- 🇨🇳 **China Mirror**: https://pub.mtdcy.top:8443/cmdlets/latest

## Contributing

Contributions are welcome! Please read our [Commit Convention](.github/COMMIT_CONVENTION.md) before submitting PRs.

## License

- **This project**: BSD 2-Clause License
- **Built libraries**: Respective licenses (LGPL/GPL/BSD/etc. depending on source)

---

Made with 🌹 by [Chen Fang](https://github.com/mtdcy)
