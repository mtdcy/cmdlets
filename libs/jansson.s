# C library for encoding, decoding, and manipulating JSON

# shellcheck disable=SC2034
libs_name=jansson
libs_lic="MIT"
libs_ver=2.15.1
libs_url=https://github.com/akheron/jansson/releases/download/v$libs_ver/jansson-$libs_ver.tar.gz
libs_sha=0c7114dc0b2d22a670724a1f95922029d7077c19dbf79a584cb8084d2f267f2f

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    # static only
    --disable-shared
    --enable-static
)

libs_build() {
    configure

    make

    pkgfile libjansson -- make.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
