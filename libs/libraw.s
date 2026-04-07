# Library for reading RAW files from digital photo cameras

# shellcheck disable=SC2034
libs_ver=0.22.1
libs_url=https://github.com/LibRaw/LibRaw/archive/refs/tags/$libs_ver.tar.gz
libs_sha=e676248284075605aa2697a66eeed7dc258820bd1d4988c724d29edffd726726
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

    --disable-shared
    --enable-static
)

libs_build() {
    bootstrap

    configure

    make

    # no docs
    pkgfile libraw -- make.install doc_DATA=
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
