# Ultravideo HEVC encoder
#
# shellcheck disable=SC2034

libs_lic="BSD-3-Clause"
libs_ver=2.3.2
libs_url=https://github.com/ultravideo/kvazaar/releases/download/v$libs_ver/kvazaar-$libs_ver.tar.gz
libs_sha=b95d2e20f2b0d8d7ed320055740be2e7a730abe28b153b5a788cfca371cc38b2

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking
    --disable-shared
    --enable-static
    )

libs_build() {
    configure && make &&

    # fix kvazaar.pc
    sed -e "s@^prefix=.*@prefix=$PREFIX@" \
        -e "s@^Version:.*@Version: $libs_ver@" \
        -i src/kvazaar.pc &&
    
    library kvazaar \
        include src/kvazaar.h \
        lib src/.libs/*.a \
        lib/pkgconfig src/kvazaar.pc &&

    cmdlet src/kvazaar
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
