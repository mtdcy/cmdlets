# cmdlets

Prebuilt single file, static or pseudo-static binaries and libraries for Linux and macOS

This Project includes:

- [bash script](libs.sh) functions for creating static libraries and binaries.

## Quick Start

```shell
# Github
bash -c "$(curl -fsSL https://raw.githubusercontent.com/mtdcy/cmdlets/main/cmdlets.sh)" install
# CN
bash -c "$(curl -fsSL http://git.mtdcy.top/mtdcy/cmdlets/raw/branch/main/cmdlets.sh)" install

# Setup repo (optional)
export CMDLETS_MAIN_REPO=https://github.com/mtdcy/cmdlets/releases/download

# Install bash 3.2 as default bash
cmdlets.sh install bash@3.2:bash
```

## Supported arch

- x86_64-linux-gnu
- x86_64-apple-darwin
- aarch64-linux-gnu
- arm64-apple-darwin

## Build

### Build on Host

```shell
make prepare-host

make zlib
```

### Build with Docker

```shell
# ARM on x86 (optional)
sudo apt install binfmt-support qemu-user-static

# Setup env
make cmdlets.env
source cmdlets.env
# OR, manually
export DOCKER_IMAGE=ghcr.io/mtdcy/builder:ubuntu-22.04
export DOCKER_PLATFORM=linux/amd64  # supported: linux/amd64,linux/arm64

make zlib
```

### Build with remote machine

```shell
export REMOTE_HOST=10.10.10.123
make prepare-remote-homebrew    # run only once

make zlib
```

### Build options

```shell
# local packages cache
export CMDLET_MIRRORS=http://pub.mtdcy.top

# logging style
export CMDLET_LOGGING=tty # options: tty,plain,silence

# parallels jobs
export CL_NJOBS=2
```

## Artifacts

- [Github](https://github.com/mtdcy/cmdlets/releases)
- [CN](https://pub.mtdcy.top:8443/cmdlets/latest)

## LICENSES

- This Project is licensed under BSD 2-Clause License.
- The target is either LGPL or GPL or BSD or others depends on the source code's license.
