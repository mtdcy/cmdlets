# A Portable Foreign Function Interface Library

# shellcheck disable=SC2034
libs_lic='MIT'
libs_ver=3.7.0
libs_url=https://github.com/libffi/libffi/releases/download/v$libs_ver/libffi-$libs_ver.tar.gz
libs_sha=2255c5a638dfb51bf67c20a12a7bb70d17feb1e9eababac05f5573146f586436
libs_dep=()

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --enable-pic
    --enable-portable-binary

    --disable-debug
    --disable-docs
    --disable-man

    # static
    --disable-shared
    --enable-static
)

is_mingw && libs_args+=( --disable-symvers )

libs_build() {

    configure

    make

    pkgfile libffi -- make.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
