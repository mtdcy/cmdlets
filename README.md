# cmdlets

Prebuilt single file, pseudo-static binaries and libraries for Linux | macOS | Windows.

This Project includes:

- [bash script](ulib.sh) functions for creating static libraries and binaries.

## Quick Start

```shell
# Github
bash -c "$(curl -fsSL https://raw.githubusercontent.com/mtdcy/cmdlets/main/cmdlets.sh)" install
# CN
bash -c "$(curl -fsSL http://git.mtdcy.top/mtdcy/cmdlets/raw/branch/main/cmdlets.sh)" install

# Install cmdlet
cmdlets.sh install nvim
# OR
ln -svf cmdlets.sh nvim
```

## Supported arch

- x86_64-linux-gnu
- x86_64-linux-musl
- x86_64-apple-darwin

- aarch64-linux-gnu
- aarch64-linux-musl

### ARM on x86

```shell
sudo apt install binfmt-support qemu-user-static
```

## Artifacts

[CN](https://pub.mtdcy.top/cmdlets/latest)

## Build Libraries & Binaries

### Build on Host

```shell
make prepare-host

make zlib
```

### Build with Docker

```shell
export DOCKER_IMAGE=cmdlets
export DOCKER_PLATFORM=linux/amd64  # supported: linux/amd64,linux/arm64

make zlib
```

### Build with remote machine

```shell
export REMOTE_HOST=10.10.10.234
make prepare-remote-homebrew    # run only once

make zlib
```

### Build options

```shell
export UPKG_MIRROR=http://pub.mtdcy.top

export CL_LOGGING=tty # options: tty,plain,silence

export NJOBS=2   #
```

## LICENSES

* This Project is licensed under BSD 2-Clause License.
* The target is either LGPL or GPL or BSD or others depends on the source code's license.
