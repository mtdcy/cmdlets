# JPEG image codec that aids compression and decompression
#
# shellcheck disable=SC2034

libs_lic="IJG"
libs_ver=3.0.1
libs_url=https://downloads.sourceforge.net/project/libjpeg-turbo/$libs_ver/libjpeg-turbo-$libs_ver.tar.gz
libs_sha=22429507714ae147b3acacd299e82099fce5d9f456882fc28e252e4579ba2a75
libs_dep=()

libs_args=(
    -DREQUIRE_SIMD=TRUE
    -DWITH_JPEG8=1
    -DENABLE_SHARED=FALSE
    -DENABLE_STATIC=TRUE
)

libs_build() {
    # https://github.com/libjpeg-turbo/libjpeg-turbo/issues/709 <= homebrew
    if is_darwin && is_arm64; then
        libs_args+=(
            -DFLOATTEST8=fp-contract
            -DFLOATTEST12=fp-contract
        )
    fi

    cmake . && make || return 1

    inspect make install &&

    library libjpeg-turbo \
            include     libjpeg-turbo.h jpeglib.h jconfig.h jerror.h jmorecfg.h \
            lib         *.a \
            lib/pkgconfig  pkgscripts/*.pc &&

    cmdlet  cjpeg-static cjpeg &&
    cmdlet  djpeg-static djpeg &&

    check   cjpeg -version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
