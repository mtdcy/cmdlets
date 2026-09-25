# Image format providing lossless and lossy compression for web images
#
# shellcheck disable=SC2034

libs_lic="BSD-3-Clause"
libs_ver=1.6.0
libs_url=https://github.com/webmproject/libwebp/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=93a852c2b3efafee3723efd4636de855b46f9fe1efddd607e1f42f60fc8f2136
libs_dep=(libpng giflib libtiff libjpeg-turbo)

libs_args=(
    -DBUILD_SHARED_LIBS=OFF
)

# cygwin-gcc failed to build these utils
is_cygwin && libs_args+=(
    -DWEBP_BUILD_ANIM_UTILS=OFF
    -DWEBP_BUILD_CWEBP=OFF
    -DWEBP_BUILD_DWEBP=OFF
    -DWEBP_BUILD_GIF2WEBP=OFF
    -DWEBP_BUILD_IMG2WEBP=OFF
    -DWEBP_BUILD_VWEBP=OFF
    -DWEBP_BUILD_WEBPINFO=OFF
    -DWEBP_BUILD_WEBPMUX=OFF
    -DWEBP_BUILD_EXTRAS=OFF
)

libs_build() {
    cmake.setup

    cmake.build

    # cmake.install will always install utils
    cmake.install
    sed install_manifest.txt \
        -e "\#$PREFIX/bin#d" \
        -e "\#$PREFIX/share/man#d" > libwebp.txt

    cmdlet.pkgfile libwebp < libwebp.txt

    if ! is_cygwin; then
        local utils=(
            webpinfo
            cwebp dwebp webpmux
            img2webp gif2webp
        )
        for x in "${utils[@]}"; do
            cmdlet.install "$x"
        done

        cmdlet.verify -- webpinfo -version
    fi
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
