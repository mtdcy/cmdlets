# Ultravideo HEVC encoder
#
# shellcheck disable=SC2034

upkg_lic="BSD-3-Clause"
upkg_ver=2.3.2
upkg_url=https://github.com/ultravideo/kvazaar/releases/download/v$upkg_ver/kvazaar-$upkg_ver.tar.gz
upkg_sha=b95d2e20f2b0d8d7ed320055740be2e7a730abe28b153b5a788cfca371cc38b2

upkg_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking
    --disable-shared
    --enable-static
    )

upkg_static() {
    configure && make &&

    # fix kvazaar.pc
    sed -e "s@^prefix=.*@prefix=$PREFIX@" \
        -e "s@^Version:.*@Version: $upkg_ver@" \
        -i src/kvazaar.pc &&
    
    library kvazaar \
        include src/kvazaar.h \
        lib src/.libs/*.a \
        lib/pkgconfig src/kvazaar.pc &&

    cmdlet src/kvazaar
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
