# Image format providing lossless and lossy compression for web images
#
# shellcheck disable=SC2034

libs_lic="BSD-3-Clause"
libs_ver=1.5.0
libs_url=https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-$libs_ver.tar.gz
libs_sha=7d6fab70cf844bf6769077bd5d7a74893f8ffd4dfb42861745750c63c2a5c92c
libs_dep=(png giflib tiff libjpeg-turbo)

libs_args=(
    -DBUILD_SHARED_LIBS=OFF
)

libs_build() {
    cmake -S . -B build &&

    make -C build &&

    library webp \
            include/webp            src/webp/*.h build/src/webp/*.h \
            include/webp/sharpyuv   sharpyuv/*.h \
            lib                     build/*.a \
            lib/pkgconfig           $(find build -name "*.pc") &&

    cmdlet ./build/cwebp &&
    cmdlet ./build/dwebp &&
    cmdlet ./build/img2webp &&
    cmdlet ./build/webpinfo &&
    cmdlet ./build/webpmux &&
    cmdlet ./build/webp_quality &&

    check img2webp -version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
