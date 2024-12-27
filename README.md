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

## Binaries

- x86_64-linux-gnu      - [bin](https://pub.mtdcy.top:8443/cmdlets/latest/x86_64-linux-gnu/bin/)
- x86_64-linux-musl     - [bin](https://pub.mtdcy.top:8443/cmdlets/latest/x86_64-linux-musl/bin/)
- x86_64-apple-darwin   - [bin](https://pub.mtdcy.top:8443/cmdlets/latest/x86_64-apple-darwin/bin/)

## Libraries

- x86_64-linux-gnu      - [packages.lst](https://pub.mtdcy.top:8443/cmdlets/latest/x86_64-linux-gnu/packages.lst)
- x86_64-linux-musl     - [packages.lst](https://pub.mtdcy.top:8443/cmdlets/latest/x86_64-linux-musl/packages.lst)
- x86_64-apple-darwin   - [packages.lst](https://pub.mtdcy.top:8443/cmdlets/latest/x86_64-apple-darwin/packages.lst)

## Build Libraries & Binaries

### Configure Your Host

- Linux     - see the [Dockerfile](Dockerfile) for details.
- macOS     - see [Makefile](Makefile) `make prepare-remote-homebrew`
- MSYS2     - TODO

### Build on Host

```shell
export UPKG_DLROOT=/path/to/package/cache # [optional]
export UPKG_NJOBS=8 # [optional]
./build.sh zlib
# OR
make zlib
```

### Build with Docker

```shell
export DOCKER_IMAGE=cmdlets
make prepare    # run only once
make zlib
```

### Build with remote machine

prerequisite: clone this project and setup packages dir.

```shell
export REMOTE_HOST=10.10.10.234
make prepare-remote-homebrew    # run only once
make zlib
```

## LICENSES

* This Project is licensed under BSD 2-Clause License.
* The target is either LGPL or GPL or BSD or others depends on the source code's license.
