# zlib replacement with optimizations for "next generation" systems.

# shellcheck disable=SC2034
libs_lic="Zlib"
libs_ver=2.3.3
libs_url=https://github.com/zlib-ng/zlib-ng/archive/refs/tags/2.3.3.tar.gz
libs_sha=f9c65aa9c852eb8255b636fd9f07ce1c406f061ec19a2e7d508b318ca0c907d1

libs_deps=()

# configure args
libs_args=(
    -DZLIB_COMPAT=ON
    -DWITH_GTEST=ON

    -DBUILD_SHARED_LIBS=OFF
)

# resources: "url;sha"
libs_resources=

# patches
libs_patches=()

libs_build() {
    # disclaim old zlib versions
    cmdlet.disclaim 1.3.1

    cmake.setup

    cmake.build

    cmdlet.pkgfile libz -- cmake.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
