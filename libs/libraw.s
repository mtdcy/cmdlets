# Library for reading RAW files from digital photo cameras

# shellcheck disable=SC2034
libs_ver=0.21.5
libs_url=https://github.com/LibRaw/LibRaw/archive/refs/tags/$libs_ver.tar.gz
libs_sha=4b7f183a68f6e46e579e80ba32ab121687e75bd30a2e5566f34c36a6bcba1679
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
