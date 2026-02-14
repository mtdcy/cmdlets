# shellcheck disable=SC2034
libs_desc="New zlib (gzip, deflate) compatible compressor"
libs_lic='Apache-2.0'
libs_ver=1.0.3
libs_url=(
    https://github.com/google/zopfli/archive/refs/tags/zopfli-$libs_ver.tar.gz
)
libs_sha=e955a7739f71af37ef3349c4fa141c648e8775bceb2195be07e86f8e638814bd
libs_dep=( )

libs_patches=(
    https://github.com/google/zopfli/commit/8ef44ffde0fd2bb2a658f75887e65b31c9e44985.patch?full_index=1
)

libs_args=(

    # static only
    -DBUILD_SHARED_LIBS=OFF
)

libs_build() {
    cmake.setup

    cmake.build

    pkgfile libzopfli -- cmake.install

    cmdlet.install zopfli

    cmdlet.install zopflipng

    cmdlet.check zopfli
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
