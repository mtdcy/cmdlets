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

    # static only
    --disable-shared
    --enable-static
    )

libs_build() {
    configure && make || return $?
 
    # bin/kvazaar also been installed
    pkgfile libkvazaar -- make install SUBDIRS=src &&

    cmdlet src/kvazaar && 
    
    check kvazaar --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
