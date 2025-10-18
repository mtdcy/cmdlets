# Library for reading RAW files from digital photo cameras

# shellcheck disable=SC2034
libs_ver=0.21.4
libs_url=https://github.com/LibRaw/LibRaw/archive/refs/tags/$libs_ver.tar.gz
libs_sha=8baeb5253c746441fadad62e9c5c43ff4e414e41b0c45d6dcabccb542b2dff4b
libs_dep=( zlib libjpeg-turbo lcms2 )

# configure args: RAW <=> JPEG
libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --enable-jpeg
    --enable-zlib
    --enable-lcms       # color management

    # prefer openjpeg
    --disable-jasper    # JPEG-2000

    --disable-examples
    --disable-docs

    --disable-shared
    --enable-static
)

libs_build() {
    slogcmd autoreconf -fiv || return 1

    configure && make || return 2

    pkgfile libraw -- make install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
