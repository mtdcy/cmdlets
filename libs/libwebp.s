# Image format providing lossless and lossy compression for web images
#
# shellcheck disable=SC2034

libs_lic="BSD-3-Clause"
libs_ver=1.6.0
libs_url=https://github.com/webmproject/libwebp/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=93a852c2b3efafee3723efd4636de855b46f9fe1efddd607e1f42f60fc8f2136
libs_dep=(libpng giflib libtiff libjpeg-turbo)

libs_args=(
    -DWEBP_BUILD_CWEBP=ON
    -DWEBP_BUILD_DWEBP=ON

    -DBUILD_SHARED_LIBS=OFF
)

libs_build() {
    cmake.setup

    cmake.build

    cmdlet.pkgfile libwebp -- cmake.install

    cmdlet.install ./build/cwebp
    cmdlet.install ./build/dwebp
    cmdlet.install ./build/img2webp
    cmdlet.install ./build/webpinfo
    cmdlet.install ./build/webpmux
    cmdlet.install ./build/webp_quality

    cmdlet.check img2webp -version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
